/// pin_hasher.dart — Secure PIN hashing utilities
///
/// Uses SHA-256 with a per-user random salt (16 bytes).
/// Salt and hash are stored as hex strings in the users table.
library;

import 'dart:math';
import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Generates a random 16-byte salt and returns it as a hex string.
String generateSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// Hashes a PIN with the given salt using SHA-256.
///
/// Returns the hex-encoded digest of SHA-256(salt + pin).
String hashPin(String pin, String salt) {
  final bytes = utf8.encode(salt + pin);
  return sha256.convert(bytes).toString();
}

/// Verifies a PIN against a stored salt+hash pair.
bool verifyPin(String pin, String salt, String expectedHash) {
  return hashPin(pin, salt) == expectedHash;
}