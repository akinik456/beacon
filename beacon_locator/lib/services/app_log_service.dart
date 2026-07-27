import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/log.dart';

enum AppLogType {
  gps,
  presence,
  scheduler,
  motion,
  watcher,
  network,
  fcm,
  rtdb,
  permission,
  warning,
  error,
}

class AppLogService {
  AppLogService._();

  static File? _file;

  static const int _maxSharedLogBytes =
      2 * 1024 * 1024;

  static Future<void> startSession({
    required String source,
  }) async {
    await log(
      type: AppLogType.presence,
      source: source,
      text:
          "============================================================",
    );

    await log(
      type: AppLogType.presence,
      source: source,
      text: "SESSION START",
    );

    await log(
      type: AppLogType.presence,
      source: source,
      text:
          "============================================================",
    );
  }

  static Future<void> shareLog() async {
    try {
      final file = await _getFile();

      if (!await file.exists()) {
        Log.e("APP LOG => file not found");
        return;
      }

      final fileSize = await file.length();

      File fileToShare = file;

      if (fileSize > _maxSharedLogBytes) {
        fileToShare = await _createTrimmedShareFile(
          sourceFile: file,
        );
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(fileToShare.path),
          ],
        ),
      );
    } catch (e) {
      Log.e("APP LOG => share failed", e);
    }
  }

  static Future<File> _createTrimmedShareFile({
    required File sourceFile,
  }) async {
    final bytes = await sourceFile.readAsBytes();

    int startIndex =
        bytes.length - _maxSharedLogBytes;

    if (startIndex < 0) {
      startIndex = 0;
    }

    /*
     * Dosyanın ortasındaki eksik bir log satırıyla
     * başlamamak için ilk satır sonuna ilerliyoruz.
     */
    if (startIndex > 0) {
      while (startIndex < bytes.length &&
          bytes[startIndex] != 10) {
        startIndex++;
      }

      if (startIndex < bytes.length) {
        startIndex++;
      }
    }

    final selectedBytes = bytes.sublist(
      startIndex,
    );

    /*
     * Kırpma işlemi bir UTF-8 karakterinin ortasına
     * denk gelirse hata vermemesi için allowMalformed
     * kullanıyoruz.
     */
    final selectedText = utf8.decode(
      selectedBytes,
      allowMalformed: true,
    );

    final tempDirectory =
        await getTemporaryDirectory();

    final shareFile = File(
      p.join(
        tempDirectory.path,
        'lynra_log_share.txt',
      ),
    );

    final header = startIndex > 0
        ? '============================================================\n'
            'LYNRA LOG\n'
            'Showing the latest 2 MB of the log file.\n'
            'Generated: ${DateTime.now().toIso8601String()}\n'
            '============================================================\n\n'
        : '';

    await shareFile.writeAsString(
      '$header$selectedText',
      flush: true,
    );

    return shareFile;
  }

  static Future<File> _getFile() async {
    if (_file != null) {
      return _file!;
    }

    final directory =
        await getApplicationDocumentsDirectory();

    final filePath = p.join(
      directory.path,
      'lynra_log.txt',
    );

    _file = File(filePath);

    if (!await _file!.exists()) {
      await _file!.create(
        recursive: true,
      );
    }

    return _file!;
  }

  static Future<void> log({
    required AppLogType type,
    required String text,
    String source = 'SERVICE',
  }) async {
    try {
      final file = await _getFile();
      final now = DateTime.now();

      final tag = switch (type) {
        AppLogType.gps => 'GPS',
        AppLogType.presence => 'PRESENCE',
        AppLogType.scheduler => 'SCHED',
        AppLogType.motion => 'MOTION',
        AppLogType.watcher => 'WATCHER',
        AppLogType.network => 'NETWORK',
        AppLogType.fcm => 'FCM',
        AppLogType.rtdb => 'RTDB',
        AppLogType.permission => 'PERMISSION',
        AppLogType.warning => 'WARNING',
        AppLogType.error => 'ERROR',
      };

      final line =
          '[${now.toIso8601String()}] '
          '[$source] '
          '[$tag] '
          '$text\n';

      await file.writeAsString(
        line,
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final file = await _getFile();

      await file.writeAsString(
        '',
        flush: true,
      );

      final tempDirectory =
          await getTemporaryDirectory();

      final shareFile = File(
        p.join(
          tempDirectory.path,
          'lynra_log_share.txt',
        ),
      );

      if (await shareFile.exists()) {
        await shareFile.delete();
      }
    } catch (_) {}
  }

  static Future<String> getFilePath() async {
    final file = await _getFile();
    return file.path;
  }
}