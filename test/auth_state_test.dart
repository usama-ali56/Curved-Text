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
}
