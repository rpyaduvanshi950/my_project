import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadProgressWidget extends StatelessWidget {
  final UploadTask task;
  final String label;

  const UploadProgressWidget({
    super.key,
    required this.task,
    this.label = 'Uploading...',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TaskSnapshot>(
      stream: task.snapshotEvents,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final snap = snapshot.data!;
          final progress = snap.bytesTransferred / snap.totalBytes;
          final percentage = (progress * 100).toStringAsFixed(0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$label $percentage%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
