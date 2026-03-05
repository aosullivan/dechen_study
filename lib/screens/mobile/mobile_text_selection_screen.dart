import 'package:flutter/material.dart';

import '../../config/study_destination_catalog.dart';
import '../../services/app_preferences_service.dart';
import '../../services/daily_notification_service.dart';
import '../../utils/app_theme.dart';
import 'mobile_home_screen.dart';

class MobileTextSelectionScreen extends StatefulWidget {
  const MobileTextSelectionScreen({super.key});

  @override
  State<MobileTextSelectionScreen> createState() =>
      _MobileTextSelectionScreenState();
}

class _MobileTextSelectionScreenState extends State<MobileTextSelectionScreen> {
  final _destinations = getStudyDestinations();
  final Set<String> _selectedIds = <String>{};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppSurfaceColors.landingBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Choose texts',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Select the texts you want on Home. You can edit this anytime in Settings.',
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _destinations.length,
                itemBuilder: (_, index) {
                  final destination = _destinations[index];
                  final selected = _selectedIds.contains(destination.id);
                  return Card(
                    color: AppSurfaceColors.cardBackground(context),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: selected,
                      title: Text(destination.title),
                      subtitle: Text(destination.author),
                      onChanged: _saving
                          ? null
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedIds.add(destination.id);
                                } else {
                                  _selectedIds.remove(destination.id);
                                }
                              });
                            },
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_saving || _selectedIds.isEmpty)
                        ? null
                        : _completeOnboarding,
                    child: Text(_saving ? 'Saving...' : 'Continue'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() => _saving = true);
    try {
      await AppPreferencesService.instance.completeOnboarding(_selectedIds);
      final updatedPreferences = await AppPreferencesService.instance.load();
      if (updatedPreferences.dailyNotificationsEnabled) {
        final granted =
            await DailyNotificationService.instance.requestPermissionIfNeeded();
        if (granted) {
          await DailyNotificationService.instance
              .applySchedule(updatedPreferences);
        } else {
          await DailyNotificationService.instance.cancel();
        }
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MobileHomeScreen()),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
