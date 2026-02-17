import 'package:flutter/material.dart';

import '../../services/bcv_verse_service.dart';
import '../../services/verse_hierarchy_service.dart';
import '../../utils/app_theme.dart';
import 'bcv_quiz_screen.dart';
import 'bcv_read_screen.dart';
import 'daily_verse_screen.dart';
import 'inspiration_screen.dart';
import 'textual_overview_screen.dart';

/// Shows Daily / Quiz / Read for a given text. Daily opens random verse; Quiz guesses chapter.
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
  /// Label of the tile currently loading (null = none).
  String? _loadingLabel;

  @override
  void initState() {
    super.initState();
    // Pre-warm services so the read screen opens instantly.
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
            loading: _loadingLabel == 'Daily',
            onTap: () => _openDaily(context),
          ),
          _OptionTile(
            icon: Icons.self_improvement_outlined,
            label: 'Inspiration',
            loading: _loadingLabel == 'Inspiration',
            onTap: () => _openInspiration(context),
          ),
          _OptionTile(
            icon: Icons.quiz_outlined,
            label: 'Quiz',
            loading: _loadingLabel == 'Quiz',
            onTap: () => _openQuiz(context),
          ),
          _OptionTile(
            icon: Icons.book_outlined,
            label: 'Read',
            loading: _loadingLabel == 'Read',
            onTap: () => _openRead(context),
          ),
          _OptionTile(
            icon: Icons.account_tree_outlined,
            label: 'Textual Overview',
            loading: _loadingLabel == 'Textual Overview',
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

  void _openInspiration(BuildContext context) {
    if (textId == 'bodhicaryavatara') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const InspirationScreen(),
        ),
      );
    } else {
      _showComingSoon(context, 'Inspiration');
    }
  }

  void _openRead(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(width: 16),
            Text('Loading Reader...'),
          ],
        ),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (textId == 'bodhicaryavatara') {
      setState(() => _loadingLabel = 'Read');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context)
            .push(
              PageRouteBuilder<void>(
                pageBuilder: (_, __, ___) => BcvReadScreen(title: title),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            )
            .then((_) {
          if (mounted) setState(() => _loadingLabel = null);
        });
      });
    } else {
      _showComingSoon(context, 'Read');
    }
  }

  void _openQuiz(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(width: 16),
            Text('Loading Quiz...'),
          ],
        ),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  void _openOverview(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            SizedBox(width: 16),
            Text('Loading Textual Overview...'),
          ],
        ),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (textId == 'bodhicaryavatara') {
      setState(() => _loadingLabel = 'Textual Overview');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context)
            .push(
              MaterialPageRoute<void>(
                builder: (_) => const TextualOverviewScreen(),
              ),
            )
            .then((_) {
          if (mounted) setState(() => _loadingLabel = null);
        });
      });
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
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;

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
        leading: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Icon(icon, color: AppColors.primary),
        title: Text(
          label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        onTap: loading ? null : onTap,
      ),
    );
  }
}
