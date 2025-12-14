import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class CallLogDialog extends StatefulWidget {
  final bool hasRecording;
  final int? initialDuration;

  const CallLogDialog({
    super.key,
    this.hasRecording = false,
    this.initialDuration,
  });

  @override
  State<CallLogDialog> createState() => _CallLogDialogState();
}

class _CallLogDialogState extends State<CallLogDialog> {
  final _formKey = GlobalKey<FormState>();

  String _outcome = 'ANSWERED';
  late TextEditingController _durationController;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _outcomes = [
    'ANSWERED',
    'NO_ANSWER',
    'BUSY',
    'VOICEMAIL',
    'CALLBACK_REQUESTED',
  ];

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(
      text: widget.initialDuration?.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'outcome': _outcome,
        'duration': int.tryParse(_durationController.text) ?? 0,
        'notes': _notesController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.hasRecording ? 'Call Recorded Details' : 'Log Call Details',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.hasRecording)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.mic, color: AppColors.success, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Recording Attached',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              DropdownButtonFormField<String>(
                value: _outcome,
                decoration: const InputDecoration(labelText: 'Outcome'),
                items: _outcomes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value.replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _outcome = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duration (seconds)',
                  suffixText: 'sec',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // Cancel
          child: const Text('Skip Log'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Save Log')),
      ],
    );
  }
}
