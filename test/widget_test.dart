// Test file for Flutter widget testing
// This app uses authentication, so widget tests are minimal

import 'package:flutter_test/flutter_test.dart';
import 'package:gestao_incidentes_desktop/main.dart';

void main() {
  testWidgets('App initializes without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());

    // Verify the app builds successfully
    expect(find.byType(App), findsOneWidget);
  });
}
