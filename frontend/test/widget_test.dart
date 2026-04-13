import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/auth_session_provider.dart';
import 'package:frontend/features/auth/domain/entities/auth_session.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('VrataApp renders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: VrataApp(),
      ),
    );

    expect(find.text('VRATA'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('authenticated app opens lobby', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(() => FakeAuthSessionController()),
        ],
        child: const VrataApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lobby'), findsOneWidget);
    expect(find.textContaining('Signed in as tester'), findsOneWidget);
  });
}

class FakeAuthSessionController extends AuthSessionController {
  @override
  AuthSession? build() {
    return AuthSession(
      userId: 1,
      username: 'tester',
      tokenType: 'Bearer',
      accessToken: 'token',
      expiresAt: DateTime.utc(2026, 1, 1),
    );
  }
}
