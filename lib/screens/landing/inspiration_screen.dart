import 'package:flutter/material.dart';

import '../../services/inspiration_service.dart';
import '../../utils/app_theme.dart';
import 'inspiration_verse_screen.dart';

/// "How are you feeling today?" — pick a negative emotion to see relevant sections.
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
      body: SafeArea(
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
                'Choose what resonates and receive a related teaching.',
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
                children: InspirationService.negativeEmotions.map((emotion) {
                  final label =
                      InspirationService.emotionLabels[emotion] ?? emotion;
                  return _EmotionChip(
                    label: label,
                    onTap: () => _openEmotion(context, emotion),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEmotion(BuildContext context, String emotion) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InspirationVerseScreen(emotion: emotion),
      ),
    );
  }
}

class _EmotionChip extends StatelessWidget {
  const _EmotionChip({required this.label, required this.onTap});

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
