// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:game_launcher/main.dart';
import 'package:game_launcher/settings_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    final settingsProvider = SettingsProvider();
    
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: settingsProvider,
        child: const GameLauncherApp(),
      ),
    );

    // Verify that the app builds without crashing
    expect(find.text('Game Launcher'), findsOneWidget);
  });
}
