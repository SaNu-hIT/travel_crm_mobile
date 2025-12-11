import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/lead.dart';
import '../../providers/lead_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/comment_item.dart';
import '../../widgets/add_comment_dialog.dart';

class LeadDetailScreen extends StatefulWidget {
  final String leadId;

  const LeadDetailScreen({super.key, required this.leadId});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeadProvider>(context, listen: false)
          .fetchLeadById(widget.leadId);
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _showAddCommentDialog() async {
    final comment = await showDialog<String>(
      context: context,
      builder: (context) => const AddCommentDialog(),
    );

    if (comment != null && mounted) {
      final leadProvider = Provider.of<LeadProvider>(context, listen: false);
      final success = await leadProvider.addComment(widget.leadId, comment);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? SuccessMessages.commentAdded
                  : leadProvider.error ?? 'Failed to add comment',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(LeadStatus newStatus) async {
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);
    final success = await leadProvider.updateLead(
      widget.leadId,
      {'status': newStatus.value},
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? SuccessMessages.leadUpdated
                : leadProvider.error ?? 'Failed to update status',
          ),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<LeadProvider>(
        builder: (context, leadProvider, child) {
          if (leadProvider.loadingState == LeadLoadingState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (leadProvider.currentLead == null) {
            return const Center(child: Text('Lead not found'));
          }

          final lead = leadProvider.currentLead!;

          return CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.background,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          lead.status.color.withOpacity(0.2),
                          lead.status.color.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Lead Name
                            Text(
                              lead.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: lead.status.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: lead.status.color.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                lead.status.displayName,
                                style: TextStyle(
                                  color: lead.status.color,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Quick Actions
                    _buildQuickActions(lead),
                    const SizedBox(height: 16),

                    // Contact Information
                    _buildContactInfo(lead),
                    const SizedBox(height: 16),

                    // Travel Details
                    if (lead.preferredLocation != null ||
                        lead.checkInDate != null ||
                        lead.numberOfDays != null)
                      _buildTravelDetails(lead),
                    
                    if (lead.preferredLocation != null ||
                        lead.checkInDate != null ||
                        lead.numberOfDays != null)
                      const SizedBox(height: 16),

                    // Call History
                    _buildCallHistory(lead),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCommentDialog,
        icon: const Icon(Icons.add_comment),
        label: const Text('Add Note'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildQuickActions(Lead lead) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.phone,
            label: 'Call',
            color: AppColors.success,
            onTap: () => _makePhoneCall(lead.phone),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.edit,
            label: 'Update Status',
            color: AppColors.primary,
            onTap: () => _showStatusDialog(lead),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(Lead lead) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: lead.phone,
            iconColor: AppColors.success,
          ),
          if (lead.email != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: lead.email!,
              iconColor: AppColors.primary,
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.source_rounded,
            label: 'Source',
            value: lead.source,
            iconColor: Colors.orange,
          ),
          if (lead.category != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.category_rounded,
              label: 'Category',
              value: lead.category!,
              iconColor: Colors.purple,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTravelDetails(Lead lead) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Travel Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (lead.preferredLocation != null)
            _buildInfoRow(
              icon: Icons.location_on_rounded,
              label: 'Destination',
              value: lead.preferredLocation!,
              iconColor: Colors.red,
            ),
          if (lead.checkInDate != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.calendar_today_rounded,
              label: 'Check-in',
              value: formatDate(lead.checkInDate!),
              iconColor: Colors.blue,
            ),
          ],
          if (lead.checkOutDate != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.calendar_month_rounded,
              label: 'Check-out',
              value: formatDate(lead.checkOutDate!),
              iconColor: Colors.blue,
            ),
          ],
          if (lead.numberOfDays != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.event_rounded,
              label: 'Duration',
              value: '${lead.numberOfDays} days',
              iconColor: Colors.green,
            ),
          ],
          if (lead.numberOfRooms != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.hotel_rounded,
              label: 'Rooms',
              value: lead.numberOfRooms.toString(),
              iconColor: Colors.purple,
            ),
          ],
          if (lead.quotedPackageCost != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.attach_money_rounded,
              label: 'Quoted Cost',
              value: '₹${lead.quotedPackageCost!.toStringAsFixed(2)}',
              iconColor: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCallHistory(Lead lead) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Activity & Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${lead.comments.length}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (lead.comments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 48,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No notes yet',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...lead.comments.asMap().entries.map((entry) {
              final index = entry.key;
              final comment = entry.value;
              return CommentItem(
                comment: comment,
                isLast: index == lead.comments.length - 1,
              );
            }),
        ],
      ),
    );
  }

  void _showStatusDialog(Lead lead) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: LeadStatus.values.map((status) {
                    final isSelected = status == lead.status;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        if (status != lead.status) {
                          _updateStatus(status);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? status.color.withOpacity(0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? status.color
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: status.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getStatusIcon(status),
                                color: status.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? status.color
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: status.color,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
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
