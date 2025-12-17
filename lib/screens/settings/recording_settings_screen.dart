import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../utils/constants.dart';
import '../../services/recording_scanner_service.dart';

class RecordingSettingsScreen extends StatefulWidget {
  const RecordingSettingsScreen({super.key});

  @override
  State<RecordingSettingsScreen> createState() =>
      _RecordingSettingsScreenState();
}

class _RecordingSettingsScreenState extends State<RecordingSettingsScreen> {
  String? _currentPath;
  bool _isLoading = true;
  final RecordingScannerService _scanner = RecordingScannerService();

  final List<Map<String, String>> _commonPaths = [
    {
      'name': 'Default Recordings',
      'path': '/storage/emulated/0/Recordings'
    },
    {
      'name': 'Call Recordings',
      'path': '/storage/emulated/0/Call Recordings'
    },
    {
      'name': 'CallRecordings',
      'path': '/storage/emulated/0/CallRecordings'
    },
    {
      'name': 'MIUI Call Recorder',
      'path': '/storage/emulated/0/MIUI/sound_recorder/call_rec'
    },
    {'name': 'PhoneRecord', 'path': '/storage/emulated/0/PhoneRecord'},
    {
      'name': 'Music - Call Recordings',
      'path': '/storage/emulated/0/Music/Call Recordings'
    },
    {
      'name': 'Google Dialer',
      'path':
          '/storage/emulated/0/Android/data/com.google.android.dialer/files/Call Recordings'
    },
    {'name': 'Sounds', 'path': '/storage/emulated/0/Sounds'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentPath();
  }

  Future<void> _loadCurrentPath() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentPath = prefs.getString('recording_path');
      _isLoading = false;
    });
  }

  Future<void> _selectDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        // Verify directory exists
        final dir = Directory(selectedDirectory);
        if (await dir.exists()) {
          await _savePath(selectedDirectory);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Directory set to: $selectedDirectory'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected directory does not exist'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting directory: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _savePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('recording_path', path);
    setState(() {
      _currentPath = path;
    });
  }

  Future<void> _resetPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recording_path');
    setState(() {
      _currentPath = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to default paths'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _testDirectory() async {
    if (_currentPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No custom directory set. Will use default paths.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Test for recordings - get all files to show count
    final allFiles = await _scanner.getAllAudioFiles(
      lookBack: const Duration(days: 30),
    );

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (allFiles.isNotEmpty) {
        // Sort by modification time (newest first)
        allFiles.sort((a, b) {
          final statsA = a.statSync();
          final statsB = b.statSync();
          return statsB.modified.compareTo(statsA.modified);
        });

        final mostRecent = allFiles.first;
        final stats = await mostRecent.stat();
        final extension = mostRecent.path.split('.').last.toUpperCase();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 8),
                Text('Found ${allFiles.length} Recording${allFiles.length > 1 ? 's' : ''}!'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mic, color: AppColors.success, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${allFiles.length} audio file${allFiles.length > 1 ? 's' : ''} detected in last 30 days',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Most Recent:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mostRecent.path.split('/').last,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Format: $extension',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Modified: ${stats.modified}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${(stats.size / 1024 / 1024).toStringAsFixed(2)} MB',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (allFiles.length > 1) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Other ${allFiles.length - 1} recording${allFiles.length - 1 > 1 ? 's' : ''}:',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    ...allFiles.skip(1).take(5).map((f) {
                      final name = f.path.split('/').last;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $name',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                    if (allFiles.length > 6)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '... and ${allFiles.length - 6} more',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: AppColors.warning),
                SizedBox(width: 8),
                Text('No Recordings Found'),
              ],
            ),
            content: const Text(
              'No recordings found in the selected directory or default paths. '
              'Please verify:\n\n'
              '1. The correct directory is selected\n'
              '2. Call recordings exist in that folder\n'
              '3. The app has storage permissions',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
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
        title: const Text('Recording Settings'),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Directory Card
                  Container(
                    width: double.infinity,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.folder, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'Current Directory',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _currentPath ?? 'Using default paths',
                            style: TextStyle(
                              fontSize: 12,
                              color: _currentPath != null
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Browse Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _selectDirectory,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Browse & Select Directory'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Common Paths Section
                  const Text(
                    'Common Locations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap to quickly select a common recording location',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Common Paths List
                  ..._commonPaths.map((pathInfo) {
                    final isSelected = _currentPath == pathInfo['path'];
                    return GestureDetector(
                      onTap: () => _savePath(pathInfo['path']!),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pathInfo['name']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pathInfo['path']!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'monospace',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _testDirectory,
                          icon: const Icon(Icons.search),
                          label: const Text('Test'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetPath,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Tips',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Use "Browse" to select any custom directory\n'
                          '• Try "Test" to verify recordings are detected\n'
                          '• Different call recorders save to different locations\n'
                          '• The app will search default paths if no custom path is set',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
