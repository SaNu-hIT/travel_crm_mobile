import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/lead_provider.dart';
import '../../utils/constants.dart';

class AllStatusScreen extends StatelessWidget {
  const AllStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leadProvider = Provider.of<LeadProvider>(context);
    final statusCounts = _getStatusCounts(leadProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Lead Status',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: LeadStatus.values.map((status) {
          final count = statusCounts[status] ?? 0;
          return _buildStatusCard(context, status, count, leadProvider);
        }).toList(),
      ),
    );
  }

  Map<LeadStatus, int> _getStatusCounts(LeadProvider leadProvider) {
    final counts = <LeadStatus, int>{};
    for (var status in LeadStatus.values) {
      counts[status] = leadProvider.leads
          .where((lead) => lead.status == status)
          .length;
    }
    return counts;
  }

  Widget _buildStatusCard(
    BuildContext context,
    LeadStatus status,
    int count,
    LeadProvider leadProvider,
  ) {
    return GestureDetector(
      onTap: () {
        leadProvider.setStatusFilter(status);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: status.color.withOpacity(0.2),
            width: 2,
          ),
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
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getStatusIcon(status),
                color: status.color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            // Status Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count ${count == 1 ? 'lead' : 'leads'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            
            // Count Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: status.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: status.color,
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(LeadStatus status) {
    switch (status) {
      case LeadStatus.NEW:
        return Icons.fiber_new;
      case LeadStatus.FOLLOWUP:
        return Icons.schedule;
      case LeadStatus.INTERESTED:
        return Icons.thumb_up;
      case LeadStatus.PROPOSAL_SENT:
        return Icons.send;
      case LeadStatus.NOT_INTERESTED:
        return Icons.thumb_down;
      case LeadStatus.BOOKED:
        return Icons.check_circle;
      case LeadStatus.PENDING:
        return Icons.pending;
      case LeadStatus.CANCELLED:
        return Icons.cancel;
      case LeadStatus.CLOSED_WON:
        return Icons.emoji_events;
      case LeadStatus.CLOSED_LOST:
        return Icons.close;
    }
  }
}
