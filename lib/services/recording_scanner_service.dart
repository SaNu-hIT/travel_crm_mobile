import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingScannerService {
  /// Scans common recording directories for audio files created in the last [duration].
  Future<File?> scanForRecentRecording({
    Duration lookBack = const Duration(minutes: 5),
    String? phoneNumber,
    DateTime? callTimestamp,
  }) async {
    // 1. Check Permissions
    if (await Permission.audio.status.isDenied) {
      await Permission.audio.request();
    }
    if (await Permission.storage.status.isDenied) {
      await Permission.storage.request();
    }

    // 2. Load Custom Path
    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('recording_path');

    // 3. Define common paths (Android)
    // Note: Scoped Storage limits access, but standard Music/Recordings folders might be accessible via READ_MEDIA_AUDIO
    final List<String> candidatePaths = [];

    if (customPath != null && customPath.isNotEmpty) {
      candidatePaths.add(customPath);
    }

    // Add default paths as fallbacks (or primary if no custom path)
    candidatePaths.addAll([
      '/storage/emulated/0/Recordings',
      '/storage/emulated/0/Music/Recordings',
      '/storage/emulated/0/MIUI/sound_recorder/call_rec',
      '/storage/emulated/0/CallRecordings',
      '/storage/emulated/0/Sounds',
    ]);

    File? mostRecentFile;
    DateTime? mostRecentTime;

    final now = DateTime.now();
    final cutoff = callTimestamp?.subtract(lookBack) ?? now.subtract(lookBack);
    final upperLimit = callTimestamp?.add(lookBack) ?? now;

    // Clean phone number for matching in filename
    final cleanNumber = phoneNumber?.replaceAll(RegExp(r'[^0-9]'), '');

    print('=== RECORDING SCANNER ===');
    print('Looking for recordings from: $cutoff to $upperLimit');
    if (phoneNumber != null) {
      print('Filtering for phone number: $phoneNumber (cleaned: $cleanNumber)');
    }

    for (final path in candidatePaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        print('Scanning directory: $path');
        try {
          // Use async listing to avoid blocking UI thread
          await for (final entity in dir.list(
            recursive: true,
            followLinks: false,
          )) {
            if (entity is File) {
              // Filter by extension
              if (!_isAudioFile(entity.path)) continue;

              final stats = await entity.stat();
              final fileName = entity.path.split('/').last.toLowerCase();

              // Check modification time within range
              if (stats.modified.isBefore(cutoff) ||
                  stats.modified.isAfter(upperLimit)) {
                continue;
              }

              // If phone number provided, try to match in filename
              bool phoneMatches = true;
              if (cleanNumber != null && cleanNumber.isNotEmpty) {
                // Check if filename contains any portion of the phone number
                // Many recording apps include phone numbers in filenames
                phoneMatches = fileName.contains(cleanNumber) ||
                    fileName.contains(cleanNumber.substring(cleanNumber.length > 10 ? cleanNumber.length - 10 : 0));
              }

              if (phoneMatches) {
                print('  Found candidate: ${entity.path}');
                print('    Modified: ${stats.modified}');
                print('    Size: ${stats.size} bytes');

                if (mostRecentTime == null ||
                    stats.modified.isAfter(mostRecentTime)) {
                  mostRecentTime = stats.modified;
                  mostRecentFile = entity;
                }
              }
            }
          }
        } catch (e) {
          print('Error scanning directory $path: $e');
        }
      }
    }

    if (mostRecentFile != null) {
      print('✓ Selected recording: ${mostRecentFile.path}');
      print('  Modified at: $mostRecentTime');
    } else {
      print('✗ No matching recording found');
    }

    return mostRecentFile;
  }

  /// Get all audio files in configured directories for testing/debugging
  Future<List<File>> getAllAudioFiles({Duration? lookBack}) async {
    final List<File> audioFiles = [];

    final prefs = await SharedPreferences.getInstance();
    final customPath = prefs.getString('recording_path');

    final List<String> candidatePaths = [];
    if (customPath != null && customPath.isNotEmpty) {
      candidatePaths.add(customPath);
    }

    candidatePaths.addAll([
      '/storage/emulated/0/Recordings',
      '/storage/emulated/0/Music/Recordings',
      '/storage/emulated/0/MIUI/sound_recorder/call_rec',
      '/storage/emulated/0/CallRecordings',
      '/storage/emulated/0/Sounds',
    ]);

    final now = DateTime.now();
    final cutoff = lookBack != null ? now.subtract(lookBack) : null;

    for (final path in candidatePaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          await for (final entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is File && _isAudioFile(entity.path)) {
              if (cutoff != null) {
                final stats = await entity.stat();
                if (stats.modified.isAfter(cutoff)) {
                  audioFiles.add(entity);
                }
              } else {
                audioFiles.add(entity);
              }
            }
          }
        } catch (e) {
          print('Error scanning $path: $e');
        }
      }
    }

    return audioFiles;
  }

  bool _isAudioFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.amr') ||
        lower.endsWith('.awb') ||  // Adaptive Multi-Rate Wideband (call recordings)
        lower.endsWith('.ogg') ||
        lower.endsWith('.3gp') ||  // 3GPP (very common on Android)
        lower.endsWith('.3ga') ||  // 3GPP Audio
        lower.endsWith('.opus') || // Opus codec
        lower.endsWith('.flac') || // FLAC lossless
        lower.endsWith('.wma') ||  // Windows Media Audio
        lower.endsWith('.webm');   // WebM audio
  }
}
