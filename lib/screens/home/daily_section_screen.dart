import 'package:flutter/material.dart';

import '../../models/study_models.dart';
import '../../services/study_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';

class DailySectionScreen extends StatefulWidget {
  const DailySectionScreen({super.key});

  @override
  State<DailySectionScreen> createState() => _DailySectionScreenState();
}

class _DailySectionScreenState extends State<DailySectionScreen> {
  final _studyService = StudyService.instance;
  bool _isLoading = true;
  DailySection? _dailySection;
  Section? _section;

  @override
  void initState() {
    super.initState();
    _loadDailySection();
  }

  Future<void> _loadDailySection() async {
    setState(() => _isLoading = true);

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final daily = await _studyService.getTodaysDailySection(userId);
    if (daily != null) {
      final section = await _studyService.getSection(daily.sectionId);
      setState(() {
        _dailySection = daily;
        _section = section;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markComplete() async {
    if (_dailySection == null) return;

    final success = await _studyService.markDailySectionComplete(_dailySection!.id);
    if (success) {
      setState(() {
        _dailySection = DailySection(
          id: _dailySection!.id,
          userId: _dailySection!.userId,
          sectionId: _dailySection!.sectionId,
          date: _dailySection!.date,
          completed: true,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Section completed! Come back tomorrow for the next one.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: SizedBox.shrink());
    }

    if (_dailySection == null || _section == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No study text available yet. Please upload a text first.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Today\'s Section',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Chapter ${_section!.chapterNumber}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.border,
              ),
            ),
            child: Text(
              _section!.text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 32),
          if (!_dailySection!.completed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _markComplete,
                child: const Text('Mark as Complete'),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Completed! Return tomorrow for the next section.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
