import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import 'bcv_quiz_screen.dart';
import 'bcv_read_screen.dart';
import 'daily_verse_screen.dart';

/// Shows Daily / Quiz / Read for a given text. Daily opens random verse; Quiz guesses chapter.
class TextOptionsScreen extends StatelessWidget {
  const TextOptionsScreen({
    super.key,
    required this.textId,
    required this.title,
  });

  final String textId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _OptionTile(
            icon: Icons.today_outlined,
            label: 'Daily',
            onTap: () => _openDaily(context),
          ),
          _OptionTile(
            icon: Icons.quiz_outlined,
            label: 'Quiz',
            onTap: () => _openQuiz(context),
          ),
          _OptionTile(
            icon: Icons.book_outlined,
            label: 'Read',
            onTap: () => _openRead(context),
          ),
        ],
      ),
    );
  }

  void _openDaily(BuildContext context) {
    if (textId == 'bodhicaryavatara') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const DailyVerseScreen(),
        ),
      );
    } else {
      _showComingSoon(context, 'Daily');
    }
  }

  void _openRead(BuildContext context) {
    if (textId == 'bodhicaryavatara') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BcvReadScreen(title: title),
        ),
      );
    } else {
      _showComingSoon(context, 'Read');
    }
  }

  void _openQuiz(BuildContext context) {
    if (textId == 'bodhicaryavatara') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const BcvQuizScreen(),
        ),
      );
    } else {
      _showComingSoon(context, 'Quiz');
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBeige,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        onTap: onTap,
      ),
    );
  }
}
