import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

typedef OnlineIdentityGenerator = String Function();
typedef OnlinePreferencesProvider = Future<SharedPreferences> Function();

enum OnlineIdentityPersistenceError { invalidGeneratedIdentity, writeFailed }

class OnlineIdentityPersistenceException implements Exception {
  final OnlineIdentityPersistenceError error;

  const OnlineIdentityPersistenceException(this.error);

  @override
  String toString() => 'OnlineIdentityPersistenceException(${error.name})';
}

class OnlineIdentityService {
  OnlineIdentityService({
    OnlineIdentityGenerator? idGenerator,
    OnlinePreferencesProvider? preferencesProvider,
  })  : _idGenerator = idGenerator ?? (() => const Uuid().v4()),
        _preferencesProvider =
            preferencesProvider ?? SharedPreferences.getInstance;

  static const String _identityKey = 'online_anonymous_device_id';
  static Future<void> _operationChain = Future<void>.value();

  final OnlineIdentityGenerator _idGenerator;
  final OnlinePreferencesProvider _preferencesProvider;

  Future<String> getOrCreate() => _synchronized(_getOrCreate);

  /// Replaces the identity only after the server confirms online-data
  /// deletion. Calling this before deletion would orphan the old records.
  Future<String> reset() => _synchronized(_reset);

  Future<String> _getOrCreate() async {
    final SharedPreferences preferences = await _preferencesProvider();
    final String? existingIdentity = preferences.getString(_identityKey);
    if (existingIdentity != null && _isValidIdentity(existingIdentity)) {
      return existingIdentity;
    }

    return _replaceIdentity(preferences);
  }

  Future<String> _reset() async {
    final SharedPreferences preferences = await _preferencesProvider();
    return _replaceIdentity(preferences);
  }

  Future<String> _replaceIdentity(SharedPreferences preferences) async {
    final String identity = _idGenerator();
    if (!_isValidIdentity(identity)) {
      throw const OnlineIdentityPersistenceException(
        OnlineIdentityPersistenceError.invalidGeneratedIdentity,
      );
    }
    final bool stored = await preferences.setString(_identityKey, identity);
    if (!stored) {
      throw const OnlineIdentityPersistenceException(
        OnlineIdentityPersistenceError.writeFailed,
      );
    }
    return identity;
  }

  static Future<T> _synchronized<T>(Future<T> Function() operation) {
    final Completer<T> completer = Completer<T>();
    _operationChain = _operationChain.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  static bool _isValidIdentity(String value) =>
      value.length >= 8 &&
      value.length <= 128 &&
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);
}
