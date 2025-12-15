import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/lead_provider.dart';
import '../services/call_log_service.dart';
import '../models/lead.dart';

class SyncResult {
  final bool success;
  final String message;
  final int leadsUpdated;
  final int callLogsAdded;

  SyncResult({
    required this.success,
    required this.message,
    this.leadsUpdated = 0,
    this.callLogsAdded = 0,
  });
}

class SyncService {
  final CallLogService _callLogService = CallLogService();

  /// Syncs call logs for a single lead.
  /// More efficient than syncing all leads when you know which lead to sync.
  Future<SyncResult> syncSingleLeadCallLogs(
    LeadProvider leadProvider,
    String leadId,
    dynamic currentUser,
  ) async {
    try {
      print('=== SINGLE LEAD CALL LOG SYNC STARTED ===');

      if (currentUser == null) {
        print('Single Sync: No current user');
        return SyncResult(
          success: false,
          message: 'No user logged in',
        );
      }

      // Check permission first
      final hasPermission = await _callLogService.checkPermission();
      if (!hasPermission) {
        print('Single Sync: Permission denied');
        return SyncResult(
          success: false,
          message: 'Call log permission denied',
        );
      }

      // Refresh the lead data from API to get latest call logs
      print('Fetching latest lead data from API...');
      await leadProvider.fetchLeadById(leadId);

      // Get the refreshed lead
      final lead = leadProvider.currentLead;
      if (lead == null) {
        throw Exception('Lead not found after refresh');
      }

      print('Syncing call logs for: ${lead.name} (${lead.phone})');

      // Fetch device logs for this specific phone number
      final leadNumber = lead.phone.replaceAll(RegExp(r'[^0-9]'), '');
      final deviceLogs = await _callLogService.fetchCallLogs(
        phoneNumber: lead.phone,
      );

      if (deviceLogs.isEmpty) {
        print('Single Sync: No device logs found for this number');
        return SyncResult(
          success: true,
          message: 'No call logs found',
        );
      }

      print('Found ${deviceLogs.length} device log(s) for this lead');

      // Identify unsynced logs
      final unsynced = _callLogService.getUnsyncedLogs(
        deviceLogs,
        lead.callLogs,
      );

      print('Unsynced logs: ${unsynced.length}');

      if (unsynced.isEmpty) {
        return SyncResult(
          success: true,
          message: 'All call logs are up to date',
        );
      }

      print('Syncing ${unsynced.length} new call(s)');

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

      final success =
          await leadProvider.updateLead(lead.id, {'callLogs': updatedCallLogs});

      if (success) {
        print('✓ Successfully synced ${unsynced.length} call log(s)');
        return SyncResult(
          success: true,
          message: 'Synced ${unsynced.length} call log(s)',
          leadsUpdated: 1,
          callLogsAdded: unsynced.length,
        );
      } else {
        print('✗ Failed to update lead');
        return SyncResult(
          success: false,
          message: 'Failed to sync call logs',
        );
      }
    } catch (e, stackTrace) {
      print('Single Sync Error: $e');
      print('Stack trace: $stackTrace');
      return SyncResult(
        success: false,
        message: 'Sync failed: ${e.toString()}',
      );
    }
  }

  /// Syncs call logs for all leads in the [LeadProvider].
  /// This should be called on app startup or when the leads list is refreshed.
  /// Returns a [SyncResult] with sync status information.
  Future<SyncResult> syncGlobalCallLogs(
    LeadProvider leadProvider,
    dynamic currentUser,
  ) async {
    try {
      print('=== GLOBAL CALL LOG SYNC STARTED ===');

      if (currentUser == null) {
        print('Global Sync: No current user');
        return SyncResult(
          success: false,
          message: 'No user logged in',
        );
      }

      // 1. Check permission first
      final hasPermission = await _callLogService.checkPermission();
      if (!hasPermission) {
        print('Global Sync: Permission denied');
        return SyncResult(
          success: false,
          message: 'Call log permission denied. Please enable in settings.',
        );
      }

      // 2. Fetch ALL device logs (last 60 days)
      // Optimization: Fetch once, use for all leads.
      final allDeviceLogs = await _callLogService.fetchCallLogs();
      if (allDeviceLogs.isEmpty) {
        print('Global Sync: No device logs found');
        return SyncResult(
          success: true,
          message: 'No call logs found on device',
        );
      }

      // 3. Iterate through all leads in the provider
      // Use a copy of the list to avoid concurrent modification issues if provider updates
      final leads = List<Lead>.from(leadProvider.leads);

      if (leads.isEmpty) {
        print('Global Sync: No leads to sync');
        return SyncResult(
          success: true,
          message: 'No leads to sync',
        );
      }

      int updatedCount = 0;
      int totalCallLogsAdded = 0;
      final Map<String, int> unsyncedByLead = {};

      print('=== CHECKING ${leads.length} LEADS FOR CALL LOG MATCHES ===');

      for (final lead in leads) {
        // Filter device logs for this lead's phone number
        final leadNumber = lead.phone.replaceAll(RegExp(r'[^0-9+]'), '');
        if (leadNumber.isEmpty) {
          print('Lead "${lead.name}" has empty phone number, skipping');
          continue;
        }

        print('Checking lead: ${lead.name} (${lead.phone} -> cleaned: $leadNumber)');

        // Refresh this lead's data from API to get latest call logs
        await leadProvider.fetchLeadById(lead.id);
        final refreshedLead = leadProvider.currentLead;
        if (refreshedLead == null) {
          print('  Failed to refresh lead data, skipping');
          continue;
        }
        print('  Lead refreshed, has ${refreshedLead.callLogs.length} existing logs in DB');

        // Find device logs matching this lead
        final leadDeviceLogs = allDeviceLogs.where((log) {
          if (log.number == null) return false;
          final logNumber = log.number!.replaceAll(RegExp(r'[^0-9]'), ''); // Remove + sign too
          final cleanLeadNumber = leadNumber.replaceAll(RegExp(r'[^0-9]'), '');

          // Match last 10 digits (handles country code differences)
          if (logNumber.length >= 10 && cleanLeadNumber.length >= 10) {
            final logLast10 = logNumber.substring(logNumber.length - 10);
            final leadLast10 = cleanLeadNumber.substring(cleanLeadNumber.length - 10);
            return logLast10 == leadLast10;
          }
          return logNumber == cleanLeadNumber;
        }).toList();

        if (leadDeviceLogs.isEmpty) {
          print('  No device logs found for this lead');
          continue;
        }

        print('  Found ${leadDeviceLogs.length} device log(s) for this lead');

        // Identify unsynced logs using refreshed data
        final unsynced = _callLogService.getUnsyncedLogs(
          leadDeviceLogs,
          refreshedLead.callLogs,
        );

        print('  Unsynced logs: ${unsynced.length}');

        if (unsynced.isNotEmpty) {
          unsyncedByLead[refreshedLead.name] = unsynced.length;
          print('  Syncing ${unsynced.length} new call(s) for lead: ${refreshedLead.name}');

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
            ...refreshedLead.callLogs,
            ...newLogs,
          ].map((e) => e.toJson()).toList();

          final success =
              await leadProvider.updateLead(refreshedLead.id, {'callLogs': updatedCallLogs});

          if (success) {
            updatedCount++;
            totalCallLogsAdded += unsynced.length;
            print('  ✓ Successfully added ${unsynced.length} call log(s). Lead now has ${updatedCallLogs.length} total logs.');
          } else {
            print('  ✗ Failed to update lead ${refreshedLead.name}');
          }
        }
      }

      print('=== GLOBAL CALL LOG SYNC COMPLETED ===');
      print('Updated $updatedCount lead(s) with $totalCallLogsAdded call log(s)');
      if (unsyncedByLead.isNotEmpty) {
        print('Breakdown by lead:');
        unsyncedByLead.forEach((leadName, count) {
          print('  - $leadName: $count new logs');
        });
      }

      return SyncResult(
        success: true,
        message: updatedCount > 0
            ? 'Synced $totalCallLogsAdded call log(s) for $updatedCount lead(s)'
            : 'All call logs are up to date',
        leadsUpdated: updatedCount,
        callLogsAdded: totalCallLogsAdded,
      );
    } catch (e, stackTrace) {
      print('Global Sync Error: $e');
      print('Stack trace: $stackTrace');
      return SyncResult(
        success: false,
        message: 'Sync failed: ${e.toString()}',
      );
    }
  }
}
