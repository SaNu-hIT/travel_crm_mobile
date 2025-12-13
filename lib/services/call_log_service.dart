import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/call_log.dart' as app_model;

class CallLogService {
  /// Checks and requests the required permissions for accessing call logs.
  Future<bool> checkPermission() async {
    final status = await Permission.phone.status;
    if (status.isGranted) {
      return true;
    }

    // Request permission
    final result = await Permission.phone.request();
    return result.isGranted;
  }

  /// Fetches call logs from the device.
  /// If [phoneNumber] is provided, filters the logs for that specific number.
  Future<Iterable<CallLogEntry>> fetchCallLogs({String? phoneNumber}) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    // Fetch logs
    // We fetch all and filter manually if needed because query limitations can vary across devices
    // However, CallLog.query supports basic filtering.

    if (phoneNumber != null) {
      // Clean the phone number for better matching (remove spaces, dashes)
      // This is a naive cleanup.
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      // Attempt to query with number
      // verify if the package supports direct filtering by number reliably.
      // Often better to fetch recent logs and filter in memory for partial matches.

      var entries = await CallLog.get();
      return entries.where((entry) {
        if (entry.number == null) return false;
        final entryNumber = entry.number!.replaceAll(RegExp(r'[^0-9+]'), '');
        // Check if numbers end with the same sequence (last 10 digits) to handle country codes
        if (entryNumber.length >= 10 && cleanNumber.length >= 10) {
          return entryNumber.endsWith(
            cleanNumber.substring(cleanNumber.length - 10),
          );
        }
        return entryNumber == cleanNumber;
      });
    } else {
      return await CallLog.get();
    }
  }

  /// Filters device logs to find ones that haven't been synced yet.
  /// Matches based on timestamp (within 10 seconds margin) and duration.
  List<CallLogEntry> getUnsyncedLogs(
    Iterable<CallLogEntry> deviceLogs,
    List<app_model.CallLog> existingLogs,
  ) {
    final unsynced = <CallLogEntry>[];

    for (final deviceLog in deviceLogs) {
      if (deviceLog.timestamp == null) continue;

      final deviceTime = deviceLog.timestamp!;
      // deviceLog.duration is in seconds
      final deviceDuration = deviceLog.duration ?? 0;

      // Check if this log matches any existing log
      bool exists = existingLogs.any((existing) {
        final existingTime = existing.createdAt.millisecondsSinceEpoch;
        final timeDiff = (existingTime - deviceTime).abs();

        // Match if time difference is less than 10 seconds AND duration is exact
        // Note: Sometimes duration might vary slightly? usually not.
        return timeDiff < 10000 && existing.duration == deviceDuration;
      });

      if (!exists) {
        unsynced.add(deviceLog);
      }
    }

    return unsynced;
  }

  /// Maps a device [CallLogEntry] to the app's [app_model.CallLog] model.
  app_model.CallLog mapToCallLog(
    CallLogEntry entry,
    String userId,
    String userName,
  ) {
    app_model.CallType type;
    switch (entry.callType) {
      case CallType.incoming:
        type = app_model.CallType.incoming;
        break;
      case CallType.outgoing:
        type = app_model.CallType.outgoing;
        break;
      case CallType.missed:
        type = app_model.CallType.missed;
        break;
      case CallType.rejected:
      case CallType.blocked:
        type =
            app_model.CallType.missed; // Map rejected/blocked to missed for now
        break;
      default:
        type = app_model.CallType.incoming; // Default to incoming
    }

    return app_model.CallLog(
      userId: userId,
      userName: userName,
      callType: type,
      duration: entry.duration ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        entry.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      ),
      notes: '',
      outcome: app_model.CallOutcome.noAnswer, // Default outcome
    );
  }
}
