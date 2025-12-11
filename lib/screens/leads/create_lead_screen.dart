import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/lead_provider.dart';
import '../../models/custom_field.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart'; // For date formatting helpers if needed
import 'package:intl/intl.dart';

class CreateLeadScreen extends StatefulWidget {
  const CreateLeadScreen({super.key});

  @override
  State<CreateLeadScreen> createState() => _CreateLeadScreenState();
}

class _CreateLeadScreenState extends State<CreateLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _sourceController = TextEditingController(text: 'Manual');
  
  // Custom Data State
  final Map<String, dynamic> _customData = {};
  final Map<String, TextEditingController> _customControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeadProvider>(context, listen: false).fetchCustomFields();
    });
  }

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _sourceController.dispose();
    for (var controller in _customControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final leadProvider = Provider.of<LeadProvider>(context, listen: false);
    
    final Map<String, dynamic> leadData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'source': _sourceController.text.trim(),
      'status': 'NEW',
      'customData': _customData,
    };

    final success = await leadProvider.createLead(leadData);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lead created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(leadProvider.error ?? 'Failed to create lead'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Create New Lead',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Contact Information Section
            _buildSectionHeader('Contact Information'),
            _buildCard(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  // Email is optional for manual leads usually, but validation is good if entered
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            const SizedBox(height: 24),
            
            // Dynamic Custom Fields
            Consumer<LeadProvider>(
              builder: (context, leadProvider, child) {
                if (leadProvider.customFields.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                // Group fields
                final groupedFields = <String, List<CustomField>>{};
                for (var field in leadProvider.customFields) {
                  if (field.group.isEmpty) {
                    groupedFields.putIfAbsent('Additional Info', () => []).add(field);
                  } else {
                    groupedFields.putIfAbsent(field.group, () => []).add(field);
                  }
                }

                return Column(
                  children: groupedFields.entries.map((entry) {
                    final group = entry.key;
                    final fields = entry.value..sort((a, b) => a.order.compareTo(b.order));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(group),
                        _buildCard(
                          children: fields.map((field) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildCustomFieldInput(field),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 30),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'CREATE LEAD',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
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
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildCustomFieldInput(CustomField field) {
    // Determine icon based on field type or name
    IconData icon = Icons.data_usage;
    TextInputType keyboardType = TextInputType.text;

    if (field.type == 'number') {
      icon = Icons.numbers;
      keyboardType = TextInputType.number;
    } else if (field.type == 'date') {
      icon = Icons.calendar_today;
    } else if (field.type == 'textarea') {
      icon = Icons.note;
      keyboardType = TextInputType.multiline;
    } else if (field.type == 'select') {
      icon = Icons.list;
    }

    if (field.type == 'select') {
      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: field.label + (field.required ? ' *' : ''),
          prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.border),
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
        value: _customData[field.key], // might be null initially
        items: field.options.map((opt) {
          return DropdownMenuItem<String>(
            value: opt,
            child: Text(opt),
          );
        }).toList(),
        onChanged: (val) {
          setState(() {
            _customData[field.key] = val;
          });
        },
        validator: field.required
            ? (value) => value == null || value.isEmpty ? 'Required' : null
            : null,
      );
    } else if (field.type == 'date') {
       // Date Picker field
       return InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() {
               // Store as ISO string
               _customData[field.key] = picked.toIso8601String();
               // Also update controller for display if we used one, but here we can just rebuild
               // But to show text we need a controller or just a read-only input
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            prefixIcon: Icon(icon, color: AppColors.primary.withOpacity(0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
          child: Text(
            _customData[field.key] != null 
              ? DateFormat.yMMMd().format(DateTime.parse(_customData[field.key])) 
              : 'Select Date',
            style: TextStyle(
              color: _customData[field.key] != null ? Colors.black : Colors.grey[600]
            ),
          ),
        ),
      );
    } else {
      // Text, Number, Textarea
      
      // Ensure controller exists
      if (!_customControllers.containsKey(field.key)) {
        _customControllers[field.key] = TextEditingController(text: _customData[field.key]?.toString() ?? '');
        _customControllers[field.key]!.addListener(() {
             _customData[field.key] = _customControllers[field.key]!.text;
        });
      }

      return _buildTextField(
        controller: _customControllers[field.key]!,
        label: field.label + (field.required ? ' *' : ''),
        icon: icon,
        keyboardType: keyboardType,
        maxLines: field.type == 'textarea' ? 3 : 1,
        validator: field.required
            ? (value) => value == null || value.isEmpty ? 'Required' : null
            : null,
      );
    }
  }
}
