import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class AccountUIState {
  final bool isEditingUsername;
  final bool isLoading;

  AccountUIState({this.isEditingUsername = false, this.isLoading = false});

  AccountUIState copyWith({bool? isEditingUsername, bool? isLoading}) {
    return AccountUIState(
      isEditingUsername: isEditingUsername ?? this.isEditingUsername,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AccountController extends Notifier<AccountUIState> {
  @override
  AccountUIState build() => AccountUIState();

  void toggleEditing() => state = state.copyWith(isEditingUsername: !state.isEditingUsername);
  void cancelEditing() => state = state.copyWith(isEditingUsername: false);

  Future<void> updateImage() async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(authProvider.notifier).pickAndUploadProfileImage();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> saveUsername(String newName) async {
    if (newName.trim().isEmpty) return cancelEditing();

    state = state.copyWith(isLoading: true);
    try {
      final success = await ref.read(authProvider.notifier).updateUsername(newName.trim());
      if (success) cancelEditing();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final accountControllerProvider = NotifierProvider<AccountController, AccountUIState>(() => AccountController());