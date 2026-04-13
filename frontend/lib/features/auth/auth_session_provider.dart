import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';

final authSessionProvider =
    NotifierProvider<AuthSessionController, AuthSession?>(
  AuthSessionController.new,
);

class AuthSessionController extends Notifier<AuthSession?> {
  @override
  AuthSession? build() => null;

  void setSession(AuthSession session) {
    state = session;
  }

  void clearSession() {
    state = null;
  }
}
