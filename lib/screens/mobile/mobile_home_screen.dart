import 'dart:async';

import 'package:flutter/material.dart';

import '../../config/study_destination_catalog.dart';
import '../../screens/landing/gateway_landing_screen.dart';
import '../../screens/landing/text_options_screen.dart';
import '../../services/app_preferences_service.dart';
import '../../services/usage_metrics_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/web_navigation.dart';
import '../../widgets/dechen_home_action.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({
    super.key,
    this.showDailySettingsPrompt = false,
  });

  final bool showDailySettingsPrompt;

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  final _usageMetrics = UsageMetricsService.instance;

  bool _loading = true;
  Set<String> _selectedIds = <String>{};
  bool _promptShown = false;

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
      _loading = false;
    });

    if (widget.showDailySettingsPrompt && !_promptShown) {
      _promptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Select at least one Daily-capable text in Settings to open daily verses.',
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDestinations = getSelectedDestinations(_selectedIds);

    return Scaffold(
      backgroundColor: AppSurfaceColors.landingBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Dechen Study',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        actions: const [DechenHomeAction()],
      ),
      body: _loading
          ? const Center(child: SizedBox.shrink())
          : selectedDestinations.isEmpty
              ? _EmptyHome(onReload: _load)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemBuilder: (_, index) {
                    final destination = selectedDestinations[index];
                    return Card(
                      color: AppSurfaceColors.cardBackground(context),
                      child: ListTile(
                        title: Text(destination.title),
                        subtitle: Text(destination.author),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _openDestination(destination),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: selectedDestinations.length,
                ),
    );
  }

  Future<void> _openDestination(StudyDestination destination) async {
    pushAppPath(destination.path);
    unawaited(_usageMetrics.trackEvent(
      eventName: 'text_opened',
      textId: destination.id,
      mode: 'mobile_home',
      properties: {
        'destination_id': destination.id,
      },
    ));

    if (destination.isGateway) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const GatewayLandingScreen(),
        ),
      );
    } else if (destination.textId != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TextOptionsScreen(
            textId: destination.textId!,
            title: destination.title,
          ),
        ),
      );
    }

    if (!mounted) return;
    _load();
  }
}

class _EmptyHome extends StatelessWidget {
  const _EmptyHome({required this.onReload});

  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No selected texts yet.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
                'Open Settings from the top-right menu to choose texts.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onReload(),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
