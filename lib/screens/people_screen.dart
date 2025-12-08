import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/person_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class PeopleScreen extends StatefulWidget {
  final UserModel user;

  const PeopleScreen({
    super.key,
    required this.user,
  });

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final remainingSlots = 150 - widget.user.peopleCount;
    final canAddMore = remainingSlots > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('People'),
        actions: [
          if (canAddMore)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/person-form',
                  arguments: {'user': widget.user, 'person': null},
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              tooltip: 'Add Person',
            ),
        ],
      ),
      body: Column(
        children: [
          // Remaining slots indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: canAddMore ? Colors.blue[50] : Colors.orange[50],
            child: Row(
              children: [
                Icon(
                  canAddMore ? Icons.info_outline : Icons.warning_amber_rounded,
                  color: canAddMore ? Colors.blue : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    canAddMore
                        ? '$remainingSlots slots remaining (${widget.user.peopleCount}/150)'
                        : 'Maximum limit reached (150/150)',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: canAddMore ? Colors.blue[900] : Colors.orange[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // People list
          Expanded(
            child: StreamBuilder<List<PersonModel>>(
              stream: _firestoreService.getPeople(_auth.currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final people = snapshot.data ?? [];

                if (people.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No people added yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        if (canAddMore)
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/person-form',
                                arguments: {'user': widget.user, 'person': null},
                              );
                              if (result == true && mounted) {
                                setState(() {});
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Person'),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: person.photoUrl != null
                              ? NetworkImage(person.photoUrl!)
                              : null,
                          child: person.photoUrl == null
                              ? Text(
                                  person.name.isNotEmpty
                                      ? person.name[0].toUpperCase()
                                      : '?',
                                )
                              : null,
                        ),
                        title: Text(person.name),
                        subtitle: Text(person.email),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final result = await Navigator.pushNamed(
                                context,
                                '/person-form',
                                arguments: {'user': widget.user, 'person': person},
                              );
                              if (result == true && mounted) {
                                setState(() {});
                              }
                            } else if (value == 'delete') {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Person'),
                                  content: Text(
                                    'Are you sure you want to delete ${person.name}?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                try {
                                  await _firestoreService.deletePerson(
                                    _auth.currentUser!.uid,
                                    person.id!,
                                  );
                                  // Delete photo if exists
                                  if (person.photoUrl != null) {
                                    await _storageService.deletePersonPhoto(person.id!);
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Person deleted successfully'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to delete: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            }
                          },
                        ),
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/person-form',
                            arguments: {'user': widget.user, 'person': person},
                          );
                          if (result == true && mounted) {
                            setState(() {});
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

