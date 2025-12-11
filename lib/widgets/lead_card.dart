import 'package:flutter/material.dart';
import '../models/lead.dart';
import '../utils/constants.dart';

class LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;

  const LeadCard({
    super.key,
    required this.lead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: lead.status.color.withOpacity(0.2),
              child: Text(
                lead.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: lead.status.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Lead Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lead.phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  if (lead.preferredLocation != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            lead.preferredLocation!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: lead.status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: lead.status.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                lead.status.displayName,
                style: TextStyle(
                  fontSize: 11,
                  color: lead.status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
