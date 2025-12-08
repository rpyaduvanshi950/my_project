const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const MAX_PEOPLE_LIMIT = 150;

/**
 * Cloud Function to enforce 150-person limit server-side
 * Triggered when a new person document is created in users/{uid}/people/{personId}
 */
exports.enforcePeopleLimit = functions.firestore
  .document('users/{userId}/people/{personId}')
  .onCreate(async (snap, context) => {
    const userId = context.params.userId;
    const personId = context.params.personId;

    try {
      // Get the user document
      const userRef = admin.firestore().collection('users').doc(userId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        console.error(`User document ${userId} does not exist`);
        // Delete the person document as user doesn't exist
        await snap.ref.delete();
        return null;
      }

      const userData = userDoc.data();
      const currentCount = userData.peopleCount || 0;

      // Check if limit is exceeded
      if (currentCount >= MAX_PEOPLE_LIMIT) {
        console.warn(
          `User ${userId} attempted to exceed limit. Current count: ${currentCount}, Limit: ${MAX_PEOPLE_LIMIT}`
        );
        
        // Delete the person document that was just created
        await snap.ref.delete();
        
        // Ensure peopleCount doesn't exceed limit (in case of race condition)
        await userRef.update({
          peopleCount: Math.min(currentCount, MAX_PEOPLE_LIMIT),
        });

        throw new functions.https.HttpsError(
          'resource-exhausted',
          `Maximum limit of ${MAX_PEOPLE_LIMIT} people reached`
        );
      }

      // Verify the count matches (additional safety check)
      if (currentCount > MAX_PEOPLE_LIMIT) {
        console.error(
          `User ${userId} has count ${currentCount} exceeding limit ${MAX_PEOPLE_LIMIT}`
        );
        
        // Delete the person document
        await snap.ref.delete();
        
        // Reset count to limit
        await userRef.update({
          peopleCount: MAX_PEOPLE_LIMIT,
        });

        throw new functions.https.HttpsError(
          'resource-exhausted',
          `Maximum limit of ${MAX_PEOPLE_LIMIT} people reached`
        );
      }

      console.log(
        `Person ${personId} created successfully for user ${userId}. Count: ${currentCount}/${MAX_PEOPLE_LIMIT}`
      );

      return null;
    } catch (error) {
      console.error(`Error enforcing people limit for user ${userId}:`, error);
      
      // Try to clean up the person document if it still exists
      try {
        await snap.ref.delete();
      } catch (deleteError) {
        console.error(`Failed to delete person document ${personId}:`, deleteError);
      }

      // Re-throw if it's an HttpsError, otherwise wrap it
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      throw new functions.https.HttpsError(
        'internal',
        `Failed to enforce people limit: ${error.message}`
      );
    }
  });

