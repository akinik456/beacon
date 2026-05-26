import 'dart:math';

class CodeService {
  CodeService._();

  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
	
	static String shortCodeFromId(String value, {int length = 6}) {
		final normalized = value.replaceAll('-', '').toUpperCase();

		var hash = 0;

		for (final unit in normalized.codeUnits) {
			hash = 0x1fffffff & (hash + unit);
			hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
			hash = hash ^ (hash >> 6);
		}

		hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
		hash = hash ^ (hash >> 11);
		hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));

		final buffer = StringBuffer();

		var n = hash.abs();

		for (int i = 0; i < length; i++) {
			buffer.write(_chars[n % _chars.length]);
			n ~/= _chars.length;
		}

		return buffer.toString();
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