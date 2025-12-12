import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/lead.dart';
import '../../models/custom_field.dart';
import '../../models/quotation.dart';
import '../../providers/lead_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/comment_item.dart';
import '../../widgets/add_comment_dialog.dart';
import '../../widgets/lead_conversion_dialog.dart';

class LeadDetailScreen extends StatefulWidget {
  final String leadId;

  const LeadDetailScreen({super.key, required this.leadId});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // Use a map to store editable data.
  // For complex objects, we might need a more robust approach, but for this form simple map works.
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = Provider.of<LeadProvider>(context, listen: false);
    provider.fetchLeadById(widget.leadId).then((_) {
      // Initialize form data when lead is loaded
      if (provider.currentLead != null) {
        _initializeFormData(provider.currentLead!);
      }
    });
    provider.fetchCustomFields();
    provider.fetchFieldGroups();
  }

  void _initializeFormData(Lead lead) {
    setState(() {
      _formData['name'] = lead.name;
      _formData['phone'] = lead.phone;
      _formData['email'] = lead.email ?? '';
      _formData['source'] = lead.source;
      _formData['category'] = lead.category ?? '';
      _formData['customData'] = Map<String, dynamic>.from(lead.customData);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        _showSnackBar(
          success,
          success
              ? SuccessMessages.commentAdded
              : leadProvider.error ?? 'Failed to add comment',
        );
      }
    }
  }

  Future<void> _updateStatus(LeadStatus newStatus) async {
    final leadProvider = Provider.of<LeadProvider>(context, listen: false);
    final success = await leadProvider.updateLead(widget.leadId, {
      'status': newStatus.value,
    });
    if (mounted) {
      _showSnackBar(
        success,
        success
            ? SuccessMessages.leadUpdated
            : leadProvider.error ?? 'Failed to update status',
      );
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final leadProvider = Provider.of<LeadProvider>(context, listen: false);

      final success = await leadProvider.updateLead(widget.leadId, _formData);

      if (mounted) {
        _showSnackBar(
          success,
          success ? 'Lead updated successfully' : 'Failed to update lead',
        );
        if (success) {
          setState(() => _isEditing = false);
        }
      }
    }
  }

  void _convertToCustomer() {
    final lead = Provider.of<LeadProvider>(context, listen: false).currentLead;
    if (lead == null) return;

    showDialog(
      context: context,
      builder: (context) => LeadConversionDialog(
        lead: lead,
        onConvert: (data) async {
          final leadProvider = Provider.of<LeadProvider>(
            context,
            listen: false,
          );
          final success = await leadProvider.updateLead(widget.leadId, data);
          if (mounted) {
            _showSnackBar(
              success,
              success ? 'Lead converted to customer' : 'Failed to convert lead',
            );
          }
        },
      ),
    );
  }

  void _showSnackBar(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

          // Re-init form data if it's empty (e.g. initial load) or if we cancelled edit and want to reset
          if (!_isEditing && _formData.isEmpty) {
            // This acts as a secondary check, ideally relying on initState is better but this handles provider updates
            // We need to be careful not to overwrite user input during edit, hence checking !_isEditing
            // But actually better to just initialize once or when not editing.
            // Let's rely on manual reset when cancelling.
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: AppColors.textPrimary),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    if (!lead.isCustomer && !_isEditing)
                      IconButton(
                        icon: const Icon(
                          Icons.person_add_alt_1,
                          color: AppColors.primary,
                        ),
                        tooltip: 'Convert to Customer',
                        onPressed: _convertToCustomer,
                      ),
                    if (_isEditing)
                      IconButton(
                        icon: const Icon(Icons.check, color: AppColors.success),
                        onPressed: _saveChanges,
                      )
                    else
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _initializeFormData(
                            lead,
                          ); // Reset form data to current lead
                          setState(() => _isEditing = true);
                        },
                      ),
                  ],
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
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppColors.primary
                                        .withOpacity(0.1),
                                    child: Text(
                                      lead.name.isNotEmpty
                                          ? lead.name
                                                .substring(0, 1)
                                                .toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lead.name,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: lead.status.color
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: lead.status.color
                                                  .withOpacity(0.5),
                                            ),
                                          ),
                                          child: Text(
                                            lead.status.displayName,
                                            style: TextStyle(
                                              color: lead.status.color,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottom: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Activity'),
                      Tab(text: 'Quotation'),
                    ],
                  ),
                ),
              ];
            },
            body: Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(lead, leadProvider),
                  _buildActivityTab(lead),
                  _buildQuotationTab(lead),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCommentDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildOverviewTab(Lead lead, LeadProvider leadProvider) {
    print('=== OVERVIEW TAB DEBUG ===');
    print('Custom fields count: ${leadProvider.customFields.length}');
    print('Field groups count: ${leadProvider.fieldGroups.length}');
    print('Custom fields isEmpty: ${leadProvider.customFields.isEmpty}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildQuickActions(lead),
          const SizedBox(height: 20),
          _buildContactInfo(lead),
          const SizedBox(height: 20),
          if (leadProvider.customFields.isNotEmpty)
            _buildCustomFields(
              lead,
              leadProvider.customFields,
              leadProvider.fieldGroups,
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange),
              ),
              child: const Text(
                'DEBUG: Custom fields are empty',
                style: TextStyle(color: Colors.orange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityTab(Lead lead) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Call Logs
          const Text(
            'Call History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (lead.callLogs.isEmpty)
            _buildEmptyState('No calls logged yet', Icons.phone_missed)
          else
            ...lead.callLogs.map(
              (log) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: log.callType == 'MISSED'
                        ? Colors.red.withOpacity(0.1)
                        : log.callType == 'INCOMING'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    child: Icon(
                      log.callType == 'MISSED'
                          ? Icons.call_missed
                          : log.callType == 'INCOMING'
                          ? Icons.call_received
                          : Icons.call_made,
                      color: log.callType == 'MISSED'
                          ? Colors.red
                          : log.callType == 'INCOMING'
                          ? Colors.green
                          : Colors.blue,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    log.callType == 'MISSED'
                        ? 'Missed Call'
                        : log.callType == 'INCOMING'
                        ? 'Incoming Call'
                        : 'Outgoing Call',
                  ),
                  subtitle: Text(
                    DateFormat('MMM d, h:mm a').format(log.createdAt.toLocal()),
                  ),
                  trailing: Text(
                    '${log.duration ~/ 60}m ${log.duration % 60}s',
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Comments
          const Text(
            'Notes & Comments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (lead.comments.isEmpty)
            _buildEmptyState('No notes yet', Icons.note)
          else
            ...lead.comments.asMap().entries.map((entry) {
              return CommentItem(
                comment: entry.value,
                isLast: entry.key == lead.comments.length - 1,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildQuotationTab(Lead lead) {
    if (lead.quotation == null) {
      return Center(
        child: _buildEmptyState('No quotation generated', Icons.receipt_long),
      );
    }

    final quote = lead.quotation!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: quote.status == 'DRAFT'
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: quote.status == 'DRAFT'
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        child: Text(
                          quote.status,
                          style: TextStyle(
                            color: quote.status == 'DRAFT'
                                ? Colors.orange
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${quote.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quote.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = quote.items[index];
                return ListTile(
                  title: Text(item.description),
                  trailing: Text(
                    '₹${(item.amount * item.quantity).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${item.quantity} x ₹${item.amount}'),
                );
              },
            ),
          ),
          if (quote.notes != null && quote.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(quote.notes!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: Colors.grey.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(color: Colors.grey.withOpacity(0.8))),
      ],
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
            icon: Icons.edit_note,
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
          border: Border.all(color: color.withOpacity(0.3), width: 1),
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
          _buildEditableInfoRow(
            fieldKey: 'name',
            label: 'Name',
            value: lead.name,
            icon: Icons.person,
            iconColor: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildEditableInfoRow(
            fieldKey: 'phone',
            label: 'Phone',
            value: lead.phone,
            icon: Icons.phone_rounded,
            iconColor: AppColors.success,
            inputType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _buildEditableInfoRow(
            fieldKey: 'email',
            label: 'Email',
            value: lead.email ?? '',
            icon: Icons.email_rounded,
            iconColor: AppColors.primary,
            placeholder: 'No email',
            inputType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _buildEditableInfoRow(
            fieldKey: 'source',
            label: 'Source',
            value: lead.source,
            icon: Icons.source_rounded,
            iconColor: Colors.orange,
            isDropdown: true,
            dropdownOptions: [
              'WEBSITE',
              'REFERRAL',
              'COLD_CALL',
              'EMAIL_CAMPAIGN',
              'SOCIAL_MEDIA',
              'OTHER',
            ], // Ideally fetch from API
          ),
          const SizedBox(height: 12),
          _buildEditableInfoRow(
            fieldKey: 'category',
            label: 'Category',
            value: lead.category ?? '',
            icon: Icons.category_rounded,
            iconColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFields(
    Lead lead,
    List<CustomField> customFields,
    List<dynamic> fieldGroups,
  ) {
    print('=== CUSTOM FIELDS DEBUG ===');
    print('Total custom fields: ${customFields.length}');
    print('Field groups: ${fieldGroups.length}');
    print('Lead customData: ${lead.customData}');

    if (customFields.isEmpty) {
      print('No custom fields available');
      return const SizedBox.shrink();
    }

    // Group fields
    final groupedFields = <String, List<CustomField>>{};

    for (var field in customFields) {
      print('Field: ${field.label}, Group: ${field.group}, Key: ${field.key}');
      if (field.group.isEmpty) {
        groupedFields.putIfAbsent('General Info', () => []).add(field);
      } else {
        groupedFields.putIfAbsent(field.group, () => []).add(field);
      }
    }

    print('Grouped fields: ${groupedFields.keys.toList()}');

    // Sort groups
    final sortedGroupNames = groupedFields.keys.toList()
      ..sort((a, b) {
        final indexA = fieldGroups.indexWhere((fg) => fg.name == a);
        final indexB = fieldGroups.indexWhere((fg) => fg.name == b);

        if (indexA != -1 && indexB != -1) {
          return fieldGroups[indexA].order.compareTo(fieldGroups[indexB].order);
        }
        if (indexA != -1) return -1;
        if (indexB != -1) return 1;
        return a.compareTo(b);
      });

    return Column(
      children: sortedGroupNames.map((groupName) {
        final fields = groupedFields[groupName]!
          ..sort((a, b) => a.order.compareTo(b.order));

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
              Text(
                groupName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEditableCustomField(field, lead),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEditableInfoRow({
    required String fieldKey,
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    String? placeholder,
    TextInputType inputType = TextInputType.text,
    bool isDropdown = false,
    List<String>? dropdownOptions,
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
          child: _isEditing
              ? isDropdown
                    ? DropdownButtonFormField<String>(
                        initialValue: dropdownOptions!.contains(value)
                            ? value
                            : null,
                        decoration: InputDecoration(
                          labelText: label,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 8,
                          ),
                        ),
                        items: dropdownOptions
                            .map(
                              (opt) => DropdownMenuItem(
                                value: opt,
                                child: Text(opt),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _formData[fieldKey] = val),
                        onSaved: (val) => _formData[fieldKey] = val,
                      )
                    : TextFormField(
                        initialValue: value,
                        keyboardType: inputType,
                        decoration: InputDecoration(
                          labelText: label,
                          hintText: placeholder,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 8,
                          ),
                        ),
                        onSaved: (val) => _formData[fieldKey] = val,
                      )
              : Column(
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
                      value.isEmpty && placeholder != null
                          ? placeholder
                          : value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: value.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEditableCustomField(CustomField field, Lead lead) {
    dynamic rawValue;
    if (_isEditing) {
      final customData = _formData['customData'];
      if (customData is Map) {
        rawValue = customData[field.key];
      }
    } else {
      rawValue = lead.customData[field.key];
    }

    String displayValue = rawValue?.toString() ?? '';

    if (!_isEditing && field.type == 'date' && displayValue.isNotEmpty) {
      try {
        displayValue = formatDate(DateTime.parse(displayValue));
      } catch (e) {
        // keep original
      }
    }

    if (!_isEditing) {
      return _buildInfoRow(
        icon: _getIconForFieldType(field.type),
        label: field.label,
        value: displayValue.isEmpty ? '-' : displayValue,
        iconColor: AppColors.primary,
      );
    }

    // EDITING MODE
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: _buildInputForCustomField(field, rawValue),
    );
  }

  Widget _buildInputForCustomField(CustomField field, dynamic currentValue) {
    print('=== CUSTOM FIELD INPUT DEBUG ===');
    print('Field: ${field.label}');
    print('Type: ${field.type}');
    print('Options: ${field.options}');
    print('Current value: $currentValue');

    // Helper to update custom data
    void updateCustomData(String val) {
      final customData = Map<String, dynamic>.from(
        _formData['customData'] ?? {},
      );
      customData[field.key] = val;
      _formData['customData'] = customData;
    }

    if (field.type == 'select') {
      final String? selectedValue = currentValue?.toString();
      return DropdownButtonFormField<String>(
        value: selectedValue != null && field.options.contains(selectedValue)
            ? selectedValue
            : null,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        items: field.options
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
            .toList(),
        onChanged: (val) {
          if (val != null) setState(() => updateCustomData(val));
        },
      );
    } else if (field.type == 'date') {
      return TextFormField(
        initialValue: currentValue,
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        onTap: () async {
          // Show Date Picker
          FocusScope.of(context).requestFocus(FocusNode()); // hide keyboard
          final date = await showDatePicker(
            context: context,
            initialDate:
                currentValue != null && currentValue.toString().isNotEmpty
                ? DateTime.tryParse(currentValue) ?? DateTime.now()
                : DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            final dateStr = date.toIso8601String();
            // Update controller if we were using one, but here strictly setState
            setState(() => updateCustomData(dateStr));
          }
        },
      );
    } else {
      return TextFormField(
        initialValue: currentValue?.toString(),
        decoration: InputDecoration(
          labelText: field.label,
          border: const OutlineInputBorder(),
        ),
        maxLines: field.type == 'textarea' ? 3 : 1,
        keyboardType: field.type == 'number'
            ? TextInputType.number
            : TextInputType.text,
        onChanged: (val) => updateCustomData(val),
      );
    }
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

  IconData _getIconForFieldType(String type) {
    switch (type) {
      case 'date':
        return Icons.calendar_today_rounded;
      case 'number':
        return Icons.numbers_rounded;
      case 'select':
        return Icons.list_rounded;
      case 'textarea':
        return Icons.notes_rounded;
      default:
        return Icons.text_fields_rounded;
    }
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
                            color: isSelected ? status.color : AppColors.border,
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
