import 'dart:math';

import 'package:flutter/services.dart';

enum BcvFileQuizDifficulty { beginner, advanced }

class BcvFileQuizQuestion {
  const BcvFileQuizQuestion({
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

class BcvFileQuizService {
  BcvFileQuizService._();

  static final BcvFileQuizService instance = BcvFileQuizService._();

  static const _beginnerPath = 'texts/root_text_quiz.txt';
  static const _advancedPath = 'texts/root_text_quiz_400.txt';

  List<BcvFileQuizQuestion>? _beginner;
  List<BcvFileQuizQuestion>? _advanced;

  Future<List<BcvFileQuizQuestion>> loadQuestions(
    BcvFileQuizDifficulty difficulty,
  ) async {
    if (difficulty == BcvFileQuizDifficulty.beginner && _beginner != null) {
      return _beginner!;
    }
    if (difficulty == BcvFileQuizDifficulty.advanced && _advanced != null) {
      return _advanced!;
    }

    final path = difficulty == BcvFileQuizDifficulty.beginner
        ? _beginnerPath
        : _advancedPath;
    final content = await rootBundle.loadString(path);
    final parsed = _parseQuestions(content);

    if (difficulty == BcvFileQuizDifficulty.beginner) {
      _beginner = parsed;
    } else {
      _advanced = parsed;
    }
    return parsed;
  }

  List<BcvFileQuizQuestion> _parseQuestions(String content) {
    final lines = content.split('\n');
    final questions = <BcvFileQuizQuestion>[];

    final questionPattern = RegExp(r'^Q(\d+)\.\s*(.*)$');
    final optionPattern = RegExp(r'^([a-d])\)\s*(.*)$');
    final answerPattern =
        RegExp(r'^ANSWER:\s*([a-d])\s*$', caseSensitive: false);
    final verseRefsPattern =
        RegExp(r'^VERSE REF\(S\):\s*(.*)$', caseSensitive: false);

    var i = 0;
    while (i < lines.length) {
      final raw = lines[i].trimRight();
      final qMatch = questionPattern.firstMatch(raw);
      if (qMatch == null) {
        i++;
        continue;
      }

      final number = int.tryParse(qMatch.group(1) ?? '');
      if (number == null) {
        i++;
        continue;
      }

      final prompt = (qMatch.group(2) ?? '').trim();
      final options = <String, String>{};
      String? answerKey;
      var explicitRefs = <String>[];

      i++;
      while (i < lines.length) {
        final current = lines[i].trimRight();
        final trimmed = current.trim();

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

      final seedText = '$prompt ${options[answerKey] ?? ''}';
      final refs =
          explicitRefs.isNotEmpty ? explicitRefs : _extractVerseRefs(seedText);

      questions.add(
        BcvFileQuizQuestion(
          number: number,
          prompt: prompt,
          options: options,
          answerKey: answerKey,
          verseRefs: refs,
        ),
      );
    }

    return questions;
  }

  List<String> _extractVerseRefs(String text) {
    final refs = <String>{};

    final rangePattern = RegExp(
      r'(\d+)\.(\d+)(?:[a-d]+)?\s*[-–]\s*(?:(\d+)\.)?(\d+)(?:[a-d]+)?',
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
        RegExp(r'(\d+)\.(\d+)(?:[a-d]+)?', caseSensitive: false);
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
