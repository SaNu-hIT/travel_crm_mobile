import 'package:flutter/material.dart';
import '../models/lead.dart';
import '../utils/constants.dart';

class LeadConversionDialog extends StatefulWidget {
  final Lead lead;
  final Function(Map<String, dynamic>) onConvert;

  const LeadConversionDialog({
    super.key,
    required this.lead,
    required this.onConvert,
  });

  @override
  State<LeadConversionDialog> createState() => _LeadConversionDialogState();
}

class _LeadConversionDialogState extends State<LeadConversionDialog> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _passportController = TextEditingController();
  final TextEditingController _arrivalDateController = TextEditingController();
  final TextEditingController _arrivalTimeController = TextEditingController();
  final TextEditingController _flightNumberController = TextEditingController();

  DateTime? _selectedDob;
  DateTime? _selectedArrivalDate;
  TimeOfDay? _selectedArrivalTime;

  @override
  void dispose() {
    _dobController.dispose();
    _passportController.dispose();
    _arrivalDateController.dispose();
    _arrivalTimeController.dispose();
    _flightNumberController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDob) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isDob) {
          _selectedDob = picked;
          _dobController.text = "${picked.toLocal()}".split(' ')[0];
        } else {
          _selectedArrivalDate = picked;
          _arrivalDateController.text = "${picked.toLocal()}".split(' ')[0];
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedArrivalTime = picked;
        _arrivalTimeController.text = picked.format(context);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedArrivalDate == null) {
        // Should not happen due to validator
        return;
      }

      // Construct Arrival DateTime
      DateTime arrivalDateTime = _selectedArrivalDate!;
      if (_selectedArrivalTime != null) {
        arrivalDateTime = DateTime(
          arrivalDateTime.year,
          arrivalDateTime.month,
          arrivalDateTime.day,
          _selectedArrivalTime!.hour,
          _selectedArrivalTime!.minute,
        );
      }

      final Map<String, dynamic> updateData = {
        'isCustomer': true,
        'status': 'CLOSED_WON', // Value match enum
        'convertedAt': DateTime.now().toIso8601String(),
        'customerDetails': {
          'dob': _selectedDob?.toIso8601String(),
          'passportNumber': _passportController.text.isNotEmpty ? _passportController.text : null,
          'arrivalTime': arrivalDateTime.toIso8601String(),
          'flightNumber': _flightNumberController.text.isNotEmpty ? _flightNumberController.text : null,
        }
      };

      widget.onConvert(updateData);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Convert to Customer'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter customer details to finalize the booking.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              
              // DOB
              TextFormField(
                controller: _dobController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Birthday',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(height: 12),

              // Passport
              TextFormField(
                controller: _passportController,
                decoration: const InputDecoration(
                  labelText: 'Passport No.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Arrival Date
              TextFormField(
                controller: _arrivalDateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Arrival Date *',
                  suffixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectDate(context, false),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select arrival date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Arrival Time
              TextFormField(
                controller: _arrivalTimeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Arrival Time',
                  suffixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                onTap: () => _selectTime(context),
              ),
              const SizedBox(height: 12),

              // Flight No
              TextFormField(
                controller: _flightNumberController,
                decoration: const InputDecoration(
                  labelText: 'Flight No.',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Convert & Save'),
        ),
      ],
    );
  }
}
