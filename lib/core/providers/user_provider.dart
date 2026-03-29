import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/repository_providers.dart'; // Where databaseProvider is
import 'package:lifter/features/user/models/user_profile.dart';
import 'package:lifter/features/user/repositories/user_repository.dart';

final userRepositoryProvider = FutureProvider<UserRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return LocalUserRepository(db);
});

final userProfileProvider = AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(() {
  return UserProfileNotifier();
});

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  // We assume a single local user with ID 1
  static const int _localUserId = 1;

  @override
  Future<UserProfile?> build() async {
    final repo = await ref.watch(userRepositoryProvider.future);
    return await repo.getUser(_localUserId);
  }

  Future<void> setUsername(String username) async {
    final repo = await ref.read(userRepositoryProvider.future);
    
    var currentUser = state.value;
    if (currentUser != null) {
      currentUser = currentUser.copyWith(username: username);
    } else {
      currentUser = UserProfile(id: _localUserId, username: username);
    }

    await repo.saveUser(currentUser);
    
    state = AsyncData(currentUser);
  }
  
  // You can now easily add methods for other fields!
  Future<void> setFirstName(String firstName) async {
    final repo = await ref.read(userRepositoryProvider.future);
    if (state.value != null) {
      final updatedUser = state.value!.copyWith(firstName: firstName);
      await repo.saveUser(updatedUser);
      state = AsyncData(updatedUser);
    }
  }

  Future<void> setLastName(String lastName) async {
    final repo = await ref.read(userRepositoryProvider.future);
    if (state.value != null) {
      final updatedUser = state.value!.copyWith(lastName: lastName);
      await repo.saveUser(updatedUser);
      state = AsyncData(updatedUser);
    }
  }

  Future<void> setEmail(String email) async {
    final repo = await ref.read(userRepositoryProvider.future);
    if (state.value != null) {
      final updatedUser = state.value!.copyWith(email: email);
      await repo.saveUser(updatedUser);
      state = AsyncData(updatedUser);
    }
  }
}
