import 'package:flutter/material.dart';
import 'package:dechen_study/screens/landing/read_screen.dart';
import 'package:dechen_study/utils/app_theme.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.lightTheme(),
      themeMode: ThemeMode.light,
      home: const ReadScreen(
        textId: 'friendlyletter',
        title: 'Friendly Letter',
        initialChapterNumber: 1,
        scrollToVerseIndex: 0,
        highlightSectionIndices: {0, 1},
      ),
    ),
  );
}
