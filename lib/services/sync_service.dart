import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/lead_provider.dart';
import '../services/call_log_service.dart';
import '../models/lead.dart';

class SyncService {
  final CallLogService _callLogService = CallLogService();

  /// Syncs call logs for all leads in the [LeadProvider].
  /// This should be called on app startup or when the leads list is refreshed.
  Future<void> syncGlobalCallLogs(
    LeadProvider leadProvider,
    dynamic currentUser,
  ) async {
    try {
      print('=== GLOBAL SYNC STARTED ===');

      if (currentUser == null) {
        print('Global Sync: No current user');
        return;
      }

      // 1. Check permission first
      final hasPermission = await _callLogService.checkPermission();
      if (!hasPermission) {
        print('Global Sync: No permission');
        return;
      }

      // 2. Fetch ALL device logs (maybe limit to last 30 days if possible,
      // but package fetches all. Filter in memory).
      // Optimization: Fetch once, use for all leads.
      final allDeviceLogs = await _callLogService.fetchCallLogs();
      if (allDeviceLogs.isEmpty) {
        print('Global Sync: No device logs found');
        return;
      }

      // 3. Iterate through all leads in the provider
      // Use a copy of the list to avoid concurrent modification issues if provider updates
      final leads = List<Lead>.from(leadProvider.leads);

      int updatedCount = 0;

      for (final lead in leads) {
        // Filter device logs for his lead's phone number
        final leadNumber = lead.phone.replaceAll(RegExp(r'[^0-9+]'), '');
        if (leadNumber.isEmpty) continue;

        // Find device logs matching this lead
        final leadDeviceLogs = allDeviceLogs.where((log) {
          if (log.number == null) return false;
          final logNumber = log.number!.replaceAll(RegExp(r'[^0-9+]'), '');
          // Match last 10 digits
          if (logNumber.length >= 10 && leadNumber.length >= 10) {
            return logNumber.endsWith(
              leadNumber.substring(leadNumber.length - 10),
            );
          }
          return logNumber == leadNumber;
        });

        if (leadDeviceLogs.isEmpty) continue;

        // Identify unsynced logs
        final unsynced = _callLogService.getUnsyncedLogs(
          leadDeviceLogs,
          lead.callLogs,
        );

        if (unsynced.isNotEmpty) {
          print('Syncing ${unsynced.length} calls for lead ${lead.name}');

          // Convert and upload
          final newLogs = unsynced
              .map(
                (log) => _callLogService.mapToCallLog(
                  log,
                  currentUser.id,
                  currentUser.name,
                ),
              )
              .toList();

          final updatedCallLogs = [
            ...lead.callLogs,
            ...newLogs,
          ].map((e) => e.toJson()).toList();

          await leadProvider.updateLead(lead.id, {'callLogs': updatedCallLogs});

          updatedCount++;
        }
      }

      print('=== GLOBAL SYNC COMPLETED: Updated $updatedCount leads ===');
    } catch (e) {
      print('Global Sync Error: $e');
    }
  }
}
