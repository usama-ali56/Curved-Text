import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/database_helper.dart';

class AuthUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String providerId; // 'google' or 'email'

  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.providerId,
  });
}

class AuthState {
  final AuthUser? user;
  final bool isLoading;

  const AuthState({
    this.user,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthUser? Function()? user,
    bool? isLoading,
  }) {
    return AuthState(
      user: user != null ? user() : this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  AuthState build() {
    return const AuthState();
  }

  // Defensive helper to save session details locally in SQLite settings
  Future<void> _saveSession({
    required String email,
    required String name,
    required String provider,
  }) async {
    try {
      await DatabaseHelper.instance.setSetting('user_logged_in', 'true');
      await DatabaseHelper.instance.setSetting('user_email', email);
      await DatabaseHelper.instance.setSetting('user_profile_name', name);
      await DatabaseHelper.instance.setSetting('auth_provider', provider);
    } catch (e) {
      // Handled gracefully during unit testing where native sqlite is not loaded
      print('SQLite session persistence skipped: $e');
    }
  }

  // Defensive helper to clear session details locally
  Future<void> _clearSession() async {
    try {
      await DatabaseHelper.instance.setSetting('user_logged_in', 'false');
      await DatabaseHelper.instance.setSetting('user_email', '');
      await DatabaseHelper.instance.setSetting('auth_provider', '');
    } catch (e) {
      print('SQLite session clearing skipped: $e');
    }
  }

  Future<AuthUser?> signIn() async {
    state = state.copyWith(isLoading: true);
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final user = AuthUser(
          uid: account.id,
          email: account.email,
          displayName: account.displayName ?? 'Google User',
          photoUrl: account.photoUrl,
          providerId: 'google',
        );

        await _saveSession(
          email: account.email,
          name: account.displayName ?? 'Google User',
          provider: 'google',
        );

        state = AuthState(user: user);
        return user;
      } else {
        state = state.copyWith(isLoading: false);
      }
      return null;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<AuthUser?> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true);
    // Simulate network request delay
    await Future.delayed(const Duration(milliseconds: 800));

    final namePart = email.split('@').first;
    final displayName = namePart[0].toUpperCase() + namePart.substring(1);

    final user = AuthUser(
      uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      providerId: 'email',
    );

    await _saveSession(
      email: email,
      name: displayName,
      provider: 'email',
    );

    state = AuthState(user: user);
    return user;
  }

  Future<AuthUser?> signUpWithEmail(String name, String email, String password) async {
    state = state.copyWith(isLoading: true);
    // Simulate network request delay
    await Future.delayed(const Duration(milliseconds: 800));

    final user = AuthUser(
      uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: name,
      providerId: 'email',
    );

    await _saveSession(
      email: email,
      name: name,
      provider: 'email',
    );

    state = AuthState(user: user);
    return user;
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    await _clearSession();

    state = const AuthState();
  }

  Future<AuthUser?> signInSilently() async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Check Google session
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        final user = AuthUser(
          uid: account.id,
          email: account.email,
          displayName: account.displayName ?? 'Google User',
          photoUrl: account.photoUrl,
          providerId: 'google',
        );
        state = AuthState(user: user);
        return user;
      }

      // 2. Check local email session
      try {
        final loggedIn = await DatabaseHelper.instance.getSetting('user_logged_in');
        if (loggedIn == 'true') {
          final email = await DatabaseHelper.instance.getSetting('user_email') ?? '';
          final name = await DatabaseHelper.instance.getSetting('user_profile_name') ?? 'Creative';
          final provider = await DatabaseHelper.instance.getSetting('auth_provider') ?? 'email';

          final user = AuthUser(
            uid: 'local_user',
            email: email,
            displayName: name,
            providerId: provider,
          );
          state = AuthState(user: user);
          return user;
        }
      } catch (_) {
        // Suppress database lookup failures in unit testing
      }

      state = const AuthState();
      return null;
    } catch (e) {
      state = const AuthState();
      return null;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
