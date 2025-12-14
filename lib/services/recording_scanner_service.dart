import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class RecordingScannerService {
  /// Scans common recording directories for audio files created in the last [duration].
  Future<File?> scanForRecentRecording({
    Duration lookBack = const Duration(minutes: 5),
  }) async {
    // 1. Check Permissions
    if (await Permission.audio.status.isDenied) {
      await Permission.audio.request();
    }
    if (await Permission.storage.status.isDenied) {
      await Permission.storage.request();
    }

    // 2. Define common paths (Android)
    // Note: Scoped Storage limits access, but standard Music/Recordings folders might be accessible via READ_MEDIA_AUDIO
    final List<String> candidatePaths = [
      '/storage/emulated/0/Recordings',
      '/storage/emulated/0/Music/Recordings',
      '/storage/emulated/0/MIUI/sound_recorder/call_rec',
      '/storage/emulated/0/CallRecordings',
      '/storage/emulated/0/Sounds',
    ];

    File? mostRecentFile;
    DateTime? mostRecentTime;

    final now = DateTime.now();
    final cutoff = now.subtract(lookBack);

    for (final path in candidatePaths) {
      final dir = Directory(path);
      if (await dir.exists()) {
        try {
          final List<FileSystemEntity> files = dir.listSync(recursive: true);
          for (final entity in files) {
            if (entity is File) {
              // Filter by extension
              if (!_isAudioFile(entity.path)) continue;

              final stats = await entity.stat();
              // Check modification time
              if (stats.modified.isAfter(cutoff)) {
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

    return mostRecentFile;
  }

  bool _isAudioFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.amr') ||
        lower.endsWith('.ogg');
  }
}
