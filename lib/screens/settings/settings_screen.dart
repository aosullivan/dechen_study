import 'package:flutter/material.dart';

import '../../config/study_destination_catalog.dart';
import '../../services/app_preferences_service.dart';
import '../../services/daily_notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _destinations = getStudyDestinations();

  bool _loading = true;
  Set<String> _selectedIds = <String>{};
  bool _dailyNotificationsEnabled = false;
  int _dailyNotificationMinutesLocal =
      AppPreferencesService.defaultDailyNotificationMinutesLocal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await AppPreferencesService.instance.load();
    if (!mounted) return;
    setState(() {
      _selectedIds = prefs.selectedTextIds;
      _dailyNotificationsEnabled = prefs.dailyNotificationsEnabled;
      _dailyNotificationMinutesLocal = prefs.dailyNotificationMinutesLocal;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: SizedBox.shrink())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _SectionTitle('Selected texts'),
                ..._destinations.map(_buildDestinationTile),
                const SizedBox(height: 20),
                const _SectionTitle('Daily notifications'),
                SwitchListTile(
                  value: _dailyNotificationsEnabled,
                  title: const Text('Enable daily verse reminder'),
                  subtitle: const Text('One reminder each day on this device'),
                  onChanged: _toggleDailyNotifications,
                ),
                ListTile(
                  enabled: _dailyNotificationsEnabled,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reminder time'),
                  subtitle:
                      Text(_formatMinutes(_dailyNotificationMinutesLocal)),
                  trailing: const Icon(Icons.schedule),
                  onTap: _dailyNotificationsEnabled ? _pickTime : null,
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Appearance'),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Theme'),
                  subtitle: Text('Using the default light theme'),
                ),
              ],
            ),
    );
  }

  Widget _buildDestinationTile(StudyDestination destination) {
    final selected = _selectedIds.contains(destination.id);
    final disableUncheck = selected && _selectedIds.length <= 1;

    return CheckboxListTile(
      value: selected,
      title: Text(destination.title),
      subtitle: Text(destination.author),
      contentPadding: EdgeInsets.zero,
      onChanged: disableUncheck
          ? (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Select at least one destination.'),
                ),
              );
            }
          : (value) => _toggleSelected(destination.id, value == true),
    );
  }

  Future<void> _toggleSelected(String destinationId, bool selected) async {
    final updated = <String>{..._selectedIds};
    if (selected) {
      updated.add(destinationId);
    } else {
      updated.remove(destinationId);
    }

    if (updated.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one destination.')),
      );
      return;
    }

    setState(() => _selectedIds = updated);
    await AppPreferencesService.instance.updateSelectedTextIds(updated);
    final prefs = await AppPreferencesService.instance.load();
    if (prefs.dailyNotificationsEnabled) {
      final granted =
          await DailyNotificationService.instance.requestPermissionIfNeeded();
      if (granted) {
        await DailyNotificationService.instance.applySchedule(prefs);
      } else {
        await DailyNotificationService.instance.cancel();
      }
    }
  }

  Future<void> _toggleDailyNotifications(bool enabled) async {
    if (enabled) {
      final hasDailySource =
          getDailyEligibleDestinations(_selectedIds).isNotEmpty;
      if (!hasDailySource) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Choose at least one Daily-capable text before enabling reminders.',
            ),
          ),
        );
        return;
      }

      final granted =
          await DailyNotificationService.instance.requestPermissionIfNeeded();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission was not granted.'),
          ),
        );
        return;
      }
    }

    setState(() => _dailyNotificationsEnabled = enabled);
    final prefs = await AppPreferencesService.instance.load();
    final updated = prefs.copyWith(dailyNotificationsEnabled: enabled);
    await AppPreferencesService.instance.save(updated);
    if (enabled) {
      await DailyNotificationService.instance.applySchedule(updated);
    } else {
      await DailyNotificationService.instance.cancel();
    }
  }

  Future<void> _pickTime() async {
    final current = TimeOfDay(
      hour: _dailyNotificationMinutesLocal ~/ 60,
      minute: _dailyNotificationMinutesLocal % 60,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked == null) return;

    final minutes = (picked.hour * 60) + picked.minute;
    setState(() => _dailyNotificationMinutesLocal = minutes);

    await AppPreferencesService.instance.setDailyNotificationMinutesLocal(
      minutes,
    );

    if (_dailyNotificationsEnabled) {
      final prefs = await AppPreferencesService.instance.load();
      await DailyNotificationService.instance.applySchedule(prefs);
    }
  }

  String _formatMinutes(int minutes) {
    final hour = (minutes ~/ 60) % 24;
    final minute = minutes % 60;
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(
      TimeOfDay(hour: hour, minute: minute),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}
