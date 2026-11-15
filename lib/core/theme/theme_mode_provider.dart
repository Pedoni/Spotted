import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_provider.g.dart';

/// Preferenze salvate sul telefono. Si sostituisce in `main` (e nei test) con
/// l'istanza vera.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider va sostituito');

/// Tema scelto dall'utente: chiaro (default), scuro o come il telefono.
@Riverpod(keepAlive: true)
class ThemeModeSetting extends _$ThemeModeSetting {
  static const storageKey = 'theme_mode';

  @override
  ThemeMode build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(storageKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.light,
    );
  }

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(storageKey, mode.name);
  }
}
