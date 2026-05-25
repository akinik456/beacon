import 'dart:math';

class CodeService {
  CodeService._();

  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generateShortCode({int length = 6}) {
    final random = Random.secure();

    return List.generate(
      length,
      (_) => _chars[random.nextInt(_chars.length)],
    ).join();
  }

  static String normalizeCode(String value) {
    return value.trim().toUpperCase().replaceAll(' ', '');
  }

  static bool isValidCode(String value, {int length = 6}) {
    final code = normalizeCode(value);

    if (code.length != length) return false;

    return code.split('').every(_chars.contains);
  }
}