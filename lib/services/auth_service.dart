
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _saltKey = 'spectrum_pin_salt';
  static const _hashKey = 'spectrum_pin_hash';
  static const _attemptsKey = 'spectrum_pin_attempts';
  static const _lockUntilKey = 'spectrum_pin_lock_until';
  static const _profileKey = 'spectrum_user_profile';

  static const _maxAttempts = 5;
  static const _lockDuration = Duration(minutes: 1);

  final Pbkdf2 _algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 210000,
    bits: 256,
  );

  Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  Future<bool> get hasPin async {
    final prefs = await _prefs;
    return prefs.containsKey(_saltKey) &&
        prefs.containsKey(_hashKey);
  }

  Future<bool> get isLocked async {
    final prefs = await _prefs;
    final lockUntil = prefs.getInt(_lockUntilKey) ?? 0;
    return DateTime.now().millisecondsSinceEpoch < lockUntil;
  }

  Future<Duration> get remainingLockDuration async {
    final prefs = await _prefs;
    final lockUntil = prefs.getInt(_lockUntilKey) ?? 0;
    final remaining =
        lockUntil - DateTime.now().millisecondsSinceEpoch;

    return Duration(milliseconds: remaining > 0 ? remaining : 0);
  }

  bool _validPin(String pin) =>
      RegExp(r'^\d{4,6}$').hasMatch(pin);

  Future<String> _deriveHash(String pin, List<int> salt) async {
    final key = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );

    return base64Encode(await key.extractBytes());
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;

    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }

  Future<void> setPin(String pin) async {
    if (!_validPin(pin)) {
      throw Exception('PIN must contain 4 to 6 digits.');
    }

    final prefs = await _prefs;
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));

    final hash = await _deriveHash(pin, salt);

    await prefs.setString(_saltKey, base64Encode(salt));
    await prefs.setString(_hashKey, hash);
    await prefs.setInt(_attemptsKey, 0);
    await prefs.remove(_lockUntilKey);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await _prefs;

    if (await isLocked) {
      throw Exception('Too many attempts. Please wait before trying again.');
    }

    final saltString = prefs.getString(_saltKey);
    final savedHash = prefs.getString(_hashKey);

    if (saltString == null || savedHash == null) {
      throw Exception('No PIN has been configured.');
    }

    final salt = base64Decode(saltString);
    final enteredHash = await _deriveHash(pin, salt);

    if (_constantTimeEquals(enteredHash, savedHash)) {
      await prefs.setInt(_attemptsKey, 0);
      await prefs.remove(_lockUntilKey);
      return true;
    }

    final attempts = (prefs.getInt(_attemptsKey) ?? 0) + 1;
    await prefs.setInt(_attemptsKey, attempts);

    if (attempts >= _maxAttempts) {
      final lockUntil = DateTime.now()
          .add(_lockDuration)
          .millisecondsSinceEpoch;
      await prefs.setInt(_lockUntilKey, lockUntil);
      await prefs.setInt(_attemptsKey, 0);
    }

    return false;
  }

  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_profileKey);

    if (raw == null) {
      return {
        'fullName': '',
        'email': '',
        'phone': '',
        'businessName': '',
        'address': '',
      };
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return {
        'fullName': '',
        'email': '',
        'phone': '',
        'businessName': '',
        'address': '',
      };
    }
  }

  Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await _prefs;
    await prefs.setString(_profileKey, jsonEncode(profile));
  }

  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    final valid = await verifyPin(currentPin);

    if (!valid) {
      throw Exception('Your current PIN is incorrect.');
    }

    await setPin(newPin);
  }
}
