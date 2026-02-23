import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/services/bcv_file_quiz_service.dart';

void main() {
  test('backfills missing refs from nearby questions in same chapter', () {
    const content = '''
CHAPTER 1: SAMPLE
Q1. What does verse 1.2 teach?
a) Option one
b) Option two
c) Option three
d) Option four
ANSWER: a

Q2. Follow-up question without explicit verse reference?
a) Option one
b) Option two
c) Option three
d) Option four
ANSWER: b

CHAPTER 2: SAMPLE
Q3. Opening question in chapter 2 without explicit verse reference?
a) Option one
b) Option two
c) Option three
d) Option four
ANSWER: c

Q4. According to verse 2.5, what is correct?
a) Option one
b) Option two
c) Option three
d) Option four
ANSWER: d
''';

    final parsed = BcvFileQuizService.instance.parseQuestionsForTest(content);

    expect(parsed, hasLength(4));
    expect(parsed[0].verseRefs, equals(const ['1.2']));
    expect(parsed[1].verseRefs, equals(const ['1.2']));
    expect(parsed[2].verseRefs, equals(const ['2.5']));
    expect(parsed[3].verseRefs, equals(const ['2.5']));
  });

  test('advanced source question 337 has a resolved verse reference', () {
    final content = File('texts/root_text_quiz_400.txt').readAsStringSync();
    final parsed = BcvFileQuizService.instance.parseQuestionsForTest(content);
    final q337 = parsed.firstWhere((q) => q.number == 337);

    expect(q337.verseRefs, isNotEmpty);
    expect(q337.verseRefs.first, startsWith('9.'));
  });
}
