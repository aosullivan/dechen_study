import 'package:dechen_study/config/study_destination_catalog.dart';
import 'package:dechen_study/services/app_preferences_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('load defaults for first run', () async {
    final prefs = await AppPreferencesService.instance.load();

    expect(prefs.onboardingCompleted, isFalse);
    expect(prefs.selectedTextIds, isEmpty);
    expect(prefs.dailyNotificationsEnabled, isFalse);
    expect(
      prefs.dailyNotificationMinutesLocal,
      AppPreferencesService.defaultDailyNotificationMinutesLocal,
    );
  });

  test('complete onboarding persists selected ids', () async {
    final ids = <String>{gatewayDestinationId, 'bodhicaryavatara'};

    await AppPreferencesService.instance.completeOnboarding(ids);
    final loaded = await AppPreferencesService.instance.load();

    expect(loaded.onboardingCompleted, isTrue);
    expect(loaded.selectedTextIds, ids);
  });

  test('save rejects empty selected ids', () async {
    expect(
      () => AppPreferencesService.instance.save(
        const AppPreferences(
          selectedTextIds: <String>{},
          onboardingCompleted: true,
          dailyNotificationsEnabled: false,
          dailyNotificationMinutesLocal: 480,
        ),
      ),
      throwsArgumentError,
    );
  });

  test('save and reload notification settings', () async {
    await AppPreferencesService.instance.save(
      const AppPreferences(
        selectedTextIds: <String>{'bodhicaryavatara'},
        onboardingCompleted: true,
        dailyNotificationsEnabled: true,
        dailyNotificationMinutesLocal: 555,
      ),
    );

    final loaded = await AppPreferencesService.instance.load();
    expect(loaded.dailyNotificationsEnabled, isTrue);
    expect(loaded.dailyNotificationMinutesLocal, 555);
  });
}
