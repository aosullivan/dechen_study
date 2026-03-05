import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dechen_study/main.dart';
import 'package:dechen_study/screens/mobile/mobile_home_screen.dart';
import 'package:dechen_study/screens/mobile/mobile_text_selection_screen.dart';
import 'package:dechen_study/services/app_preferences_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('first launch on mobile shows text selection', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(MobileTextSelectionScreen), findsOneWidget);
  });

  testWidgets('completed onboarding opens mobile home', (tester) async {
    await AppPreferencesService.instance.completeOnboarding(
      const {'gateway_to_knowledge', 'bodhicaryavatara'},
    );

    await tester.pumpWidget(const MyApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(MobileHomeScreen), findsOneWidget);
    expect(find.text('Gateway to Knowledge'), findsOneWidget);
  });
}
