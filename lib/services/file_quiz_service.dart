import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/study_text_config.dart';

enum FileQuizDifficulty { beginner, advanced }

class FileQuizQuestion {
  const FileQuizQuestion({
    required this.number,
    required this.prompt,
    required this.options,
    required this.answerKey,
    required this.verseRefs,
  });

  final int number;
  final String prompt;
  final Map<String, String> options;
  final String answerKey;
  final List<String> verseRefs;

  String get correctAnswerText => options[answerKey] ?? '';
}

class FileQuizService {
  FileQuizService._();

  static final FileQuizService instance = FileQuizService._();

  /// Cache: textId -> difficulty -> list of questions.
  final Map<String, Map<FileQuizDifficulty, List<FileQuizQuestion>>> _cache =
      {};

  Future<List<FileQuizQuestion>> loadQuestions(
    String textId,
    FileQuizDifficulty difficulty,
  ) async {
    final byDifficulty = _cache[textId];
    if (byDifficulty != null) {
      final cached = byDifficulty[difficulty];
      if (cached != null) return cached;
    }

    final config = getStudyText(textId);
    final path = difficulty == FileQuizDifficulty.beginner
        ? config?.quizBeginnerPath
        : config?.quizAdvancedPath;
    if (path == null || path.isEmpty) return [];

    try {
      final content = await rootBundle.loadString(path);
      final parsed = _parseQuestions(content);
      _cache[textId] ??= {};
      _cache[textId]![difficulty] = parsed;
      return parsed;
    } catch (_) {
      return [];
    }
  }

  @visibleForTesting
  List<FileQuizQuestion> parseQuestionsForTest(String content) {
    return _parseQuestions(content);
  }

  List<FileQuizQuestion> _parseQuestions(String content) {
    final lines = content.split('\n');
    final drafts = <_ParsedQuizQuestionDraft>[];

    final questionPattern = RegExp(r'^Q(\d+)\.\s*(.*)$');
    final optionPattern = RegExp(r'^([a-d])\)\s*(.*)$');
    final answerPattern =
        RegExp(r'^ANSWER:\s*([a-d])\s*$', caseSensitive: false);
    final verseRefsPattern =
        RegExp(r'^VERSE REF\(S\):\s*(.*)$', caseSensitive: false);
    final chapterPattern = RegExp(r'^CHAPTER\s+(\d+)\b', caseSensitive: false);

    int? currentChapter;
    var i = 0;
    while (i < lines.length) {
      final raw = lines[i].trimRight();
      final trimmed = raw.trim();

      final chapterMatch = chapterPattern.firstMatch(trimmed);
      if (chapterMatch != null) {
        currentChapter = int.tryParse(chapterMatch.group(1) ?? '');
        i++;
        continue;
      }

      final qMatch = questionPattern.firstMatch(trimmed);
      if (qMatch == null) {
        i++;
        continue;
      }

      final number = int.tryParse(qMatch.group(1) ?? '');
      if (number == null) {
        i++;
        continue;
      }
      final questionChapter = currentChapter;

      final prompt = (qMatch.group(2) ?? '').trim();
      final options = <String, String>{};
      String? answerKey;
      var explicitRefs = <String>[];

      i++;
      while (i < lines.length) {
        final current = lines[i].trimRight();
        final trimmed = current.trim();

        final chapterMatch = chapterPattern.firstMatch(trimmed);
        if (chapterMatch != null) {
          currentChapter = int.tryParse(chapterMatch.group(1) ?? '');
          i++;
          continue;
        }

        if (questionPattern.hasMatch(trimmed)) {
          break;
        }

        final optMatch = optionPattern.firstMatch(trimmed);
        if (optMatch != null) {
          final key = (optMatch.group(1) ?? '').toLowerCase();
          final text = (optMatch.group(2) ?? '').trim();
          if (key.isNotEmpty && text.isNotEmpty) {
            options[key] = text;
          }
          i++;
          continue;
        }

        final ansMatch = answerPattern.firstMatch(trimmed);
        if (ansMatch != null) {
          answerKey = (ansMatch.group(1) ?? '').toLowerCase();
          i++;
          continue;
        }

        final refsMatch = verseRefsPattern.firstMatch(trimmed);
        if (refsMatch != null) {
          explicitRefs = _extractVerseRefs(refsMatch.group(1) ?? '');
          i++;
          continue;
        }

        // Ignore chapter headers, verse text, and filler lines.
        i++;
      }

      if (answerKey == null || !options.containsKey(answerKey)) {
        continue;
      }

      final seedText =
          '$prompt ${options.values.join(' ')} ${options[answerKey] ?? ''}';
      final refs =
          explicitRefs.isNotEmpty ? explicitRefs : _extractVerseRefs(seedText);

      drafts.add(
        _ParsedQuizQuestionDraft(
          number: number,
          prompt: prompt,
          options: options,
          answerKey: answerKey,
          verseRefs: refs,
          chapter: questionChapter,
        ),
      );
    }

    _backfillMissingRefs(drafts);

    return drafts
        .map(
          (q) => FileQuizQuestion(
            number: q.number,
            prompt: q.prompt,
            options: q.options,
            answerKey: q.answerKey,
            verseRefs: q.verseRefs,
          ),
        )
        .toList(growable: false);
  }

  void _backfillMissingRefs(List<_ParsedQuizQuestionDraft> questions) {
    for (var i = 0; i < questions.length; i++) {
      if (questions[i].verseRefs.isNotEmpty) continue;
      final chapter = questions[i].chapter;

      List<String>? fallback;
      for (var prev = i - 1; prev >= 0; prev--) {
        if (chapter != null && questions[prev].chapter != chapter) continue;
        if (questions[prev].verseRefs.isEmpty) continue;
        fallback = questions[prev].verseRefs;
        break;
      }

      fallback ??= _findNextRefsInChapter(questions, i + 1, chapter);
      if (fallback == null) continue;
      questions[i].verseRefs = List<String>.from(fallback);
    }
  }

  List<String>? _findNextRefsInChapter(
    List<_ParsedQuizQuestionDraft> questions,
    int start,
    int? chapter,
  ) {
    for (var i = start; i < questions.length; i++) {
      if (chapter != null && questions[i].chapter != chapter) continue;
      if (questions[i].verseRefs.isEmpty) continue;
      return questions[i].verseRefs;
    }
    return null;
  }

  List<String> _extractVerseRefs(String text) {
    final refs = <String>{};

    final rangePattern = RegExp(
      r'(\d+)\.(\d+)(?:[a-z]+)?\s*[-–]\s*(?:(\d+)\.)?(\d+)(?:[a-z]+)?',
      caseSensitive: false,
    );
    for (final m in rangePattern.allMatches(text)) {
      final c1 = int.tryParse(m.group(1) ?? '');
      final v1 = int.tryParse(m.group(2) ?? '');
      final c2 = int.tryParse(m.group(3) ?? '') ?? c1;
      final v2 = int.tryParse(m.group(4) ?? '');
      if (c1 == null || v1 == null || c2 == null || v2 == null) continue;
      if (c1 < 1 || c1 > 10 || c2 < 1 || c2 > 10) continue;

      if (c1 == c2 && v2 >= v1 && (v2 - v1) <= 24) {
        for (var v = v1; v <= v2; v++) {
          refs.add('$c1.$v');
        }
      } else {
        refs.add('$c1.$v1');
        refs.add('$c2.$v2');
      }
    }

    final singlePattern =
        RegExp(r'(\d+)\.(\d+)(?:[a-z]+)?', caseSensitive: false);
    for (final m in singlePattern.allMatches(text)) {
      final c = int.tryParse(m.group(1) ?? '');
      final v = int.tryParse(m.group(2) ?? '');
      if (c == null || v == null) continue;
      if (c < 1 || c > 10) continue;
      refs.add('$c.$v');
    }

    final list = refs.toList();
    list.sort(_compareRefs);
    return list;
  }

  int _compareRefs(String a, String b) {
    final ap = a.split('.');
    final bp = b.split('.');
    final ac = ap.isNotEmpty ? int.tryParse(ap[0]) ?? 0 : 0;
    final av = ap.length > 1 ? int.tryParse(ap[1]) ?? 0 : 0;
    final bc = bp.isNotEmpty ? int.tryParse(bp[0]) ?? 0 : 0;
    final bv = bp.length > 1 ? int.tryParse(bp[1]) ?? 0 : 0;
    if (ac != bc) return ac.compareTo(bc);
    return av.compareTo(bv);
  }

  List<int> buildShuffledOrder(int count, Random random) {
    final order = List<int>.generate(count, (i) => i);
    order.shuffle(random);
    return order;
  }
}

class _ParsedQuizQuestionDraft {
  _ParsedQuizQuestionDraft({
    required this.number,
    required this.prompt,
    required this.options,
    required this.answerKey,
    required this.verseRefs,
    required this.chapter,
  });

  final int number;
  final String prompt;
  final Map<String, String> options;
  final String answerKey;
  List<String> verseRefs;
  final int? chapter;
}
