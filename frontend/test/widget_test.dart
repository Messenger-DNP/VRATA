import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('VrataApp renders', (tester) async {
    await tester.pumpWidget(const VrataApp());

    expect(find.text('VRATA'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
