import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final User? user;
  final bool loading;
  final String? error;

  const AuthState({
    this.user,
    this.loading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;
  bool get isLoading => loading;
  String? get errorMessage => error;
  String get uid => user?.uid ?? '';
  
  String get displayName {
    if (user == null) return '';
    return user!.displayName ?? user!.email?.split('@').first ?? 'User';
  }
  
  String get email => user?.email ?? '';
  String? get photoURL => user?.photoURL;

  AuthState copyWith({
    User? user,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService = AuthService();

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((user) {
      state = state.copyWith(user: user, loading: false);
    });
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _authService.signInWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        loading: false,
        error: _mapAuthError(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> registerWithEmail(String email, String password) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _authService.registerWithEmail(email, password);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        loading: false,
        error: _mapAuthError(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final userCred = await _authService.signInWithGoogle();
      if (userCred == null) {
        state = state.copyWith(loading: false);
        return false;
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Google sign-in failed. Please try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(loading: true);
    await _authService.signOut();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}