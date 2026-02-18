import 'package:flutter/material.dart';

import '../../services/inspiration_service.dart';
import '../../utils/app_theme.dart';
import 'inspiration_verse_screen.dart';

/// "How are you feeling today?" — pick a feeling to see a random verse.
class InspirationScreen extends StatelessWidget {
  const InspirationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Inspiration',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<FeelingCategory>>(
        future: InspirationService.instance.getFeelingCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return Center(
              child: Text(
                'No feeling categories loaded.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'How are you feeling today?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontFamily: 'Crimson Text',
                          color: AppColors.textDark,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose what resonates and receive a random verse.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'Lora',
                          color: AppColors.mutedBrown,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: categories.map((c) {
                      return _FeelingChip(
                        label: c.label,
                        onTap: () => _openFeeling(context, c.id, c.label),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFeeling(BuildContext context, String feelingId, String feelingLabel) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InspirationVerseScreen(
          feelingId: feelingId,
          feelingLabel: feelingLabel,
        ),
      ),
    );
  }
}

class _FeelingChip extends StatelessWidget {
  const _FeelingChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBeige,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'Lora',
                  color: AppColors.primary,
                ),
          ),
        ),
      ),
    );
  }
}
