import 'package:flutter/material.dart';

class AddCommentDialog extends StatefulWidget {
  const AddCommentDialog({super.key});

  @override
  State<AddCommentDialog> createState() => _AddCommentDialogState();
}

class _AddCommentDialogState extends State<AddCommentDialog> {
  final _commentController = TextEditingController();
  final _maxLength = 1000;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Sharp edges
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add Call Log',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: _maxLength,
              decoration: const InputDecoration(
                hintText: 'Enter call notes or comments...',
                counterText: '',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              '${_commentController.text.length}/$_maxLength characters',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final comment = _commentController.text.trim();
                    if (comment.isNotEmpty) {
                      Navigator.of(context).pop(comment);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
