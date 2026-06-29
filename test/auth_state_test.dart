import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:curvetype/presentation/state/auth_state.dart';

void main() {
  test('authProvider initial state, email sign up, and sign out', () async {
    final container = ProviderContainer();
    final notifier = container.read(authProvider.notifier);

    // 1. Check initial state
    final initialState = container.read(authProvider);
    expect(initialState.user, isNull);
    expect(initialState.isLoading, isFalse);

    // 2. Email Sign Up
    final user = await notifier.signUpWithEmail('Test Designer', 'test@example.com', 'password123');
    expect(user, isNotNull);
    expect(user!.displayName, 'Test Designer');
    expect(user.email, 'test@example.com');
    expect(user.providerId, 'email');

    final loggedInState = container.read(authProvider);
    expect(loggedInState.user, isNotNull);
    expect(loggedInState.user!.displayName, 'Test Designer');
    expect(loggedInState.isLoading, isFalse);

    // 3. Sign Out
    await notifier.signOut();
    final loggedOutState = container.read(authProvider);
    expect(loggedOutState.user, isNull);
    expect(loggedOutState.isLoading, isFalse);
  });

  test('authProvider phone number authentication and OTP verification flow', () async {
    final container = ProviderContainer();
    final notifier = container.read(authProvider.notifier);

    // 1. Verify phone number
    String? verifiedId;
    String? verifyError;
    
    await notifier.verifyPhoneNumber(
      '+1555019922',
      onCodeSent: (id) {
        verifiedId = id;
      },
      onError: (err) {
        verifyError = err;
      },
    );

    expect(verifyError, isNull);
    expect(verifiedId, 'mock_verification_id_+1555019922');

    // 2. Complete OTP sign in
    final user = await notifier.signInWithPhoneNumber(verifiedId!, '123456');
    expect(user, isNotNull);
    expect(user!.displayName, 'Phone User');
    expect(user.email, '+1555019922');
    expect(user.providerId, 'phone');

    final loggedInState = container.read(authProvider);
    expect(loggedInState.user, isNotNull);
    expect(loggedInState.user!.email, '+1555019922');
    expect(loggedInState.user!.providerId, 'phone');
    expect(loggedInState.isLoading, isFalse);

    // 3. Sign Out
    await notifier.signOut();
    final loggedOutState = container.read(authProvider);
    expect(loggedOutState.user, isNull);
  });
}
