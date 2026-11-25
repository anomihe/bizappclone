import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Real fingerprint / Face ID check through the operating system.
class Biometrics {
  Biometrics._();

  /// Replaceable in tests (there is no biometric hardware there).
  static Future<bool> Function(String reason) authenticate = _osAuthenticate;

  static final _auth = LocalAuthentication();
  static const _prefKey = 'biometric_login';

  /// The owner chose "Log in with fingerprint / Face ID" on this device.
  static Future<bool> isEnabled() async {
    try {
      return (await SharedPreferences.getInstance()).getBool(_prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Turning it on needs a passed prompt first, so only the owner can enable it.
  /// Returns the new state.
  static Future<bool> setEnabled(bool on) async {
    if (on && !await authenticate('Confirm it’s you to turn on fingerprint / Face ID login')) return false;
    try {
      await (await SharedPreferences.getInstance()).setBool(_prefKey, on);
    } catch (_) {}
    return on;
  }

  /// True when the device can do fingerprint / Face ID / device credential.
  static Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Shows the system prompt; true only if the user really passed it.
  static Future<bool> _osAuthenticate(String reason) async {
    try {
      if (!await available()) return false;
      return await _auth.authenticate(localizedReason: reason, persistAcrossBackgrounding: true);
    } catch (_) {
      // Cancelled, locked out, not enrolled or no plugin: never treat as passed.
      return false;
    }
  }
}
