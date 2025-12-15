import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  final _deviceInfo = DeviceInfoPlugin();

  Future<bool> checkAllRequired() async {
    // Check both phone and call log permissions
    bool phoneGranted = await Permission.phone.isGranted;

    // For Android, we need READ_CALL_LOG permission separately
    // permission_handler doesn't have Permission.callLog, so we use phone permission
    // which should cover READ_CALL_LOG if declared in manifest

    PermissionStatus storageStatus = await _getStorageStatus();
    bool storageGranted = storageStatus.isGranted;

    return phoneGranted && storageGranted;
  }

  // Actually, let's make it granular for the UI.

  Future<Map<String, PermissionStatus>> checkStatuses() async {
    return {
      'Phone & Call Logs': await Permission.phone.status,
      'Storage': await _getStorageStatus(),
    };
  }

  Future<PermissionStatus> _getStorageStatus() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return await Permission.audio.status;
      } else {
        return await Permission.storage.status;
      }
    }
    return PermissionStatus.granted; // iOS etc
  }

  Future<bool> requestPhone() async {
    // Requesting phone permission which includes READ_PHONE_STATE and READ_CALL_LOG
    // when both are declared in AndroidManifest.xml
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  Future<bool> requestStorage() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.audio.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    }
    return true;
  }

  /// Request all potentially needed permissions
  Future<Map<Permission, PermissionStatus>> requestAll() async {
    final perms = <Permission>[Permission.phone];

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        perms.add(Permission.audio);
        // perms.add(Permission.notification); // Optional
      } else {
        perms.add(Permission.storage);
      }
    }

    return await perms.request();
  }
}
