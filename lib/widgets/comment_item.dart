import 'package:flutter/material.dart';
import '../../models/comment.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class CommentItem extends StatelessWidget {
  final LeadComment comment;
  final bool isLast;

  const CommentItem({
    super.key,
    required this.comment,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 16),

        // Comment content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User name and time
              Row(
                children: [
                  Text(
                    comment.userName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatRelativeTime(comment.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Comment text
              Text(
                comment.comment,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
