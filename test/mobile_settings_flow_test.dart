import 'package:dechen_study/screens/landing/text_options_screen.dart';
import 'package:dechen_study/screens/mobile/mobile_home_screen.dart';
import 'package:dechen_study/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'selected_text_ids': ['gateway_to_knowledge', 'bodhicaryavatara'],
      'daily_notifications_enabled': false,
      'daily_notification_minutes_local': 480,
    });
  });

  testWidgets('settings updates selected destinations and persists',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MobileHomeScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);

    await tester
        .tap(find.widgetWithText(CheckboxListTile, 'Gateway to Knowledge'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs.getStringList('selected_text_ids'), equals(['bodhicaryavatara']));
  });

  testWidgets('text screens show mobile settings overflow action',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TextOptionsScreen(
          textId: 'bodhicaryavatara',
          title: 'Bodhicaryavatara',
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });
}
