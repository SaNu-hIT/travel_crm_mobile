import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/permission_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/shimmer_widgets.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final PermissionService _permissionService = PermissionService();

  bool _phoneGranted = false;
  bool _callLogGranted = false;
  bool _storageGranted = false;
  String? _recordingPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    // Check Permissions
    final phoneStatus = await Permission.phone.status;

    PermissionStatus storageStatus;
    if (Platform.isAndroid) {
      // We rely on service logic or just direct check helper
      // Using the service we just made
      // But wait, the service I wrote had internal checks.
      // I'll just reuse the request logic or manual checks here.
      // Let's use the service helpers if I expose them, or raw checks.
      // The service only exposed requestAll.
      // Let's quickly re-implement safe check here or update service later.
      // I'll use safe check logic here directly for UI state.
      // Actually `PermissionService` didn't expose simple getters.
      // Ill access Permission directly for state.

      // Android 13+ check
      // I need device_info again? Or just try/catch?
      // Easier: Use the PermissionService instance if I update it to expose status.
      // I will update PermissionService to have `checkPhone()` and `checkStorage()`
      // For now, I'll inline the logic to be safe.
      if (await Permission.audio.status.isGranted ||
          await Permission.storage.status.isGranted) {
        storageStatus = PermissionStatus.granted;
      } else {
        // We don't know exact version easily without device_info,
        // but we can check if EITHER is granted?
        // No, we need to know which one to request.
        // I'll trust the user interaction to request the right one via Service.
        storageStatus = PermissionStatus.denied;
      }
    } else {
      storageStatus = PermissionStatus.granted;
    }

    // Check Saved Path
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('recording_path');

    // Additional check for Android 11+
    bool manageStorage = false;
    if (Platform.isAndroid) {
      manageStorage = await Permission.manageExternalStorage.isGranted;
    }

    if (mounted) {
      setState(() {
        _phoneGranted = phoneStatus.isGranted;
        _storageGranted = storageStatus.isGranted || manageStorage;
        _recordingPath = savedPath;
        _isLoading = false;
      });
    }

    // Fix the async setState issue above by moving it out?
    // Doing a re-check properly below
    _refreshState();
  }

  Future<void> _refreshState() async {
    final phone = await _permissionService.checkPhone();
    final callLog = await _permissionService.checkCallLog();
    final storage = await _permissionService.checkStorage();

    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('recording_path');

    if (mounted) {
      setState(() {
        _phoneGranted = phone;
        _callLogGranted = callLog;
        _storageGranted = storage;
        _recordingPath = path;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPhone() async {
    await _permissionService.requestPhone();
    _refreshState();
  }

  Future<void> _requestCallLog() async {
    await _permissionService.requestCallLog();
    _refreshState();
  }

  Future<void> _requestStorage() async {
    await _permissionService.requestStorage();
    _refreshState();
  }

  Future<void> _selectFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('recording_path', selectedDirectory);
      _refreshState();
    }
  }

  Future<void> _useDefaultFolder() async {
    // Logic to find a reasonable default?
    // Just set it to null or empty string to indicate "Auto Scan" (default behavior)
    // But user wants "option to select".
    // Let's set a flag "use_default_path" = true?
    // Or just clear the path key to mean "Default".
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recording_path');
    // We need to show "Default Selected" in UI then.

    // Let's manually check if default folders exist to reassure user?
    // /storage/emulated/0/Recordings etc.
    // Keep it simple.

    // We will treat "null" recording_path as "Default"
    _refreshState();
  }

  Future<void> _finishSetup() async {
    if (_allGood) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('setup_completed', true);

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacementNamed('/login'); // Or home depending on auth
      }
    }
  }

  bool get _allGood =>
      _phoneGranted && _callLogGranted && _storageGranted; // Path can be null (default)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('App Setup'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const ShimmerPermissionScreen()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permissions Required',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'To enable call tracking and recording uploads, please grant the following permissions.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  // Phone Permission
                  _buildPermissionCard(
                    title: 'Phone Access',
                    description:
                        'Required to make calls and detect call status.',
                    icon: Icons.phone,
                    isGranted: _phoneGranted,
                    onAction: _requestPhone,
                  ),

                  const SizedBox(height: 16),

                  // Call Log Permission
                  _buildPermissionCard(
                    title: 'Call Log Access',
                    description:
                        'Required to read call history and track calls.',
                    icon: Icons.history,
                    isGranted: _callLogGranted,
                    onAction: _requestCallLog,
                  ),

                  const SizedBox(height: 16),

                  // Storage Permission
                  _buildPermissionCard(
                    title: 'Storage Access',
                    description:
                        'Required to scan and upload call recording files.',
                    icon: Icons.folder,
                    isGranted: _storageGranted,
                    onAction: _requestStorage,
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Recording Location',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Where does your phone save call recordings?',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.folder_open,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _recordingPath ?? 'Default System Folders',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _useDefaultFolder,
                                child: const Text('Use Default'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _selectFolder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Select Folder'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _allGood ? _finishSetup : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: const Text(
            'Check & Continue',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted ? AppColors.success : AppColors.border,
          width: isGranted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isGranted ? AppColors.success : AppColors.primary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isGranted ? Icons.check : icon,
              color: isGranted ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (!isGranted)
            TextButton(onPressed: onAction, child: const Text('Allow')),
        ],
      ),
    );
  }
}
