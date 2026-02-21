import 'package:flutter/material.dart';

import '../../services/bcv_verse_service.dart';
import '../../services/verse_hierarchy_service.dart';
import '../../utils/app_theme.dart';
import 'bcv_file_quiz_screen.dart';
import 'bcv_quiz_screen.dart';
import 'bcv_read_screen.dart';
import 'daily_verse_screen.dart';
import 'textual_overview_screen.dart';

/// Shows top-level study modes for a text.
class TextOptionsScreen extends StatefulWidget {
  const TextOptionsScreen({
    super.key,
    required this.textId,
    required this.title,
  });

  final String textId;
  final String title;

  @override
  State<TextOptionsScreen> createState() => _TextOptionsScreenState();
}

class _TextOptionsScreenState extends State<TextOptionsScreen> {
  @override
  void initState() {
    super.initState();
    // Pre-warm services so the read screen opens quickly.
    if (widget.textId == 'bodhicaryavatara') {
      BcvVerseService.instance.preload();
      VerseHierarchyService.instance.preload();
    }
  }

  String get textId => widget.textId;
  String get title => widget.title;

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
            label: 'Guess the Chapter',
            onTap: () => _openGuessTheChapter(context),
          ),
          _OptionTile(
            icon: Icons.fact_check_outlined,
            label: 'Quiz',
            onTap: () => _openQuiz(context),
          ),
          _OptionTile(
            icon: Icons.book_outlined,
            label: 'Read',
            onTap: () => _openRead(context),
          ),
          _OptionTile(
            icon: Icons.account_tree_outlined,
            label: 'Textual Overview',
            onTap: () => _openOverview(context),
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

  void _openGuessTheChapter(BuildContext context) {
    if (textId == 'bodhicaryavatara') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const BcvQuizScreen(),
        ),
      );
    } else {
      _showComingSoon(context, 'Guess the Chapter');
    }
  }

  void _openQuiz(BuildContext context) {
    if (textId == 'bodhicaryavatara') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const BcvFileQuizScreen(),
        ),
      );
    } else {
      _showComingSoon(context, 'Quiz');
    }
  }

  void _openOverview(BuildContext context) {
    if (textId == 'bodhicaryavatara') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const TextualOverviewScreen(),
        ),
      );
    } else {
      _showComingSoon(context, 'Textual Overview');
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
