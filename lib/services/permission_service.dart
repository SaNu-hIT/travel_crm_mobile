import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  final _deviceInfo = DeviceInfoPlugin();

  Future<bool> checkAllRequired() async {
    // Check phone, call log, and storage permissions
    bool phoneGranted = await Permission.phone.isGranted;

    // READ_CALL_LOG is a separate permission from READ_PHONE_STATE
    // Using permission_handler's callLog permission
    bool callLogGranted = false;
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 23) {
        // Android 6.0+ requires runtime permission for call logs
        callLogGranted = await Permission.phone.isGranted; // phone permission includes call log on Android
      } else {
        callLogGranted = true;
      }
    } else {
      callLogGranted = true; // iOS doesn't have call log access
    }

    PermissionStatus storageStatus = await _getStorageStatus();
    bool storageGranted = storageStatus.isGranted;

    return phoneGranted && callLogGranted && storageGranted;
  }

  // Granular checks for UI

  Future<bool> checkPhone() async {
    return await Permission.phone.isGranted;
  }

  Future<bool> checkCallLog() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 23) {
        return await Permission.phone.isGranted;
      }
    }
    return true;
  }

  Future<bool> checkStorage() async {
    final status = await _getStorageStatus();
    return status.isGranted;
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
    // Requesting phone permission which includes READ_PHONE_STATE
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  Future<bool> requestCallLog() async {
    // On Android, call log permission is requested through phone permission
    // Both READ_PHONE_STATE and READ_CALL_LOG are in the PHONE permission group
    if (Platform.isAndroid) {
      final status = await Permission.phone.request();
      return status.isGranted;
    }
    return true; // iOS doesn't have call log access
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
