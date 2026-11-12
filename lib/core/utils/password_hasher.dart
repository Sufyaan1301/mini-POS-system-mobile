import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hashes and verifies offline cashier passwords using a per-user random salt + SHA-256.
class PasswordHasher {
  PasswordHasher._();

  static String hashPassword(String plainPassword) {
    final salt = _generateSalt();
    final digest = _computeDigest(salt, plainPassword);
    return '$salt:$digest';
  }

  static bool verifyPassword(String plainPassword, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    final salt = parts[0];
    final expectedDigest = parts[1];
    final actualDigest = _computeDigest(salt, plainPassword);
    return actualDigest == expectedDigest;
  }

  static String _generateSalt([int length = 16]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _computeDigest(String salt, String plainPassword) {
    final bytes = utf8.encode('$salt::$plainPassword');
    return sha256.convert(bytes).toString();
  }
}
