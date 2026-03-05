import 'package:flutter/material.dart';
import 'package:dechen_study/screens/landing/read_screen.dart';
import 'package:dechen_study/services/verse_service.dart';
import 'package:dechen_study/utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const textId = 'bodhicaryavatara';
  await VerseService.instance.getChapters(textId);
  final idx = VerseService.instance.getIndexForRefWithFallback(textId, '4.26c') ?? 0;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.lightTheme(),
      themeMode: ThemeMode.light,
      home: ReadScreen(
        textId: textId,
        title: 'Bodhicaryavatara',
        scrollToVerseIndex: idx,
        initialSegmentRef: '4.26c',
        highlightSectionIndices: {idx},
      ),
    ),
  );
}
