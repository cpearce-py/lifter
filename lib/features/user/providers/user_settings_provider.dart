import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/shared_preferences_provider.dart';
import 'package:lifter/features/user/models/user_profile.dart';
import 'package:lifter/features/workouts/models/base_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSettingsNotifier extends Notifier<UserSettings> {
  late SharedPreferences _prefs;

  @override
  UserSettings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _loadFromDisk();
  }

  UserSettings _loadFromDisk() {
    final themeIndex = _prefs.getInt('themeMode') ?? ThemeMode.system.index;
    return UserSettings(
      bodyWeight: _prefs.getDouble('bodyWeight') ?? 70.0,
      preferredHand: Hand.values[_prefs.getInt('preferredHand') ?? 0],
      maxPullLeft: _prefs.getDouble('maxPullLeft') ?? 0.0,
      maxPullRight: _prefs.getDouble('maxPullRight') ?? 0.0,
      useLbs: _prefs.getBool('useLbs') ?? false,
      themeMode: ThemeMode.values[themeIndex],
    );
  }

  void updateThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs.setInt('themeMode', mode.index);
  }

  void updateWeight(double weight) {
    state = state.copyWith(bodyWeight: weight);
    _prefs.setDouble('bodyWeight', weight);
  }

  void updateHand(Hand hand) {
    state = state.copyWith(preferredHand: hand);
    _prefs.setInt('preferredHand', hand.index);
  }

  void updateMaxPulls(double left, double right) {
    state = state.copyWith(maxPullLeft: left, maxPullRight: right);
    _prefs.setDouble('maxPullLeft', left);
    _prefs.setDouble('maxPullRight', right);
  }

  void toggleMetric(bool useLbs) {
    state = state.copyWith(useLbs: useLbs);
    _prefs.setBool('useLbs', useLbs);
  }
}

final userSettingsProvider = NotifierProvider<UserSettingsNotifier, UserSettings>(
  UserSettingsNotifier.new,
);
