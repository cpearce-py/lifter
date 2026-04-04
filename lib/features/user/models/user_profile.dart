import 'package:flutter/material.dart';
import 'package:lifter/features/workouts/models/base_models.dart';

class UserProfile {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;

  UserProfile({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
  });

  UserProfile copyWith({
    int? id,
    String? username,
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'update_time': DateTime.now().toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['user_id'] as int,
      username: map['username'] as String,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      email: map['email'] as String?,
    );
  }
}

// Data class for shared_preference User defaults.
class UserSettings {
  final double bodyWeight;
  final Hand preferredHand;
  final double maxPullLeft;
  final double maxPullRight;
  final bool useLbs; // true = lbs, false = kg
  final ThemeMode themeMode;

  const UserSettings({
    this.bodyWeight = 70.0,
    this.preferredHand = Hand.left,
    this.maxPullLeft = 0.0,
    this.maxPullRight = 0.0,
    this.useLbs = false,
    this.themeMode = ThemeMode.system,
  });

  UserSettings copyWith({
    double? bodyWeight,
    Hand? preferredHand,
    double? maxPullLeft,
    double? maxPullRight,
    bool? useLbs,
    ThemeMode? themeMode,
  }) {
    return UserSettings(
      bodyWeight: bodyWeight ?? this.bodyWeight,
      preferredHand: preferredHand ?? this.preferredHand,
      maxPullLeft: maxPullLeft ?? this.maxPullLeft,
      maxPullRight: maxPullRight ?? this.maxPullRight,
      useLbs: useLbs ?? this.useLbs,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
