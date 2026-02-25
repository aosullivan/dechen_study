import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/services/commentary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = CommentaryService.instance;

  test('appends adjacent continuation when a section ends with a question',
      () async {
    final entry = await service.getCommentaryForRefWithContinuation('bodhicaryavatara', '1.2');
    expect(entry, isNotNull);
    expect(
      entry!.commentaryText,
      contains('In that case, what is the purpose of composing it?'),
    );
    expect(
      entry.commentaryText,
      contains('I composed it only to develop my own understanding.'),
    );
    expect(entry.refsInBlock, contains('1.2'));
    expect(entry.refsInBlock, contains('1.3ab'));
  });

  test('does not append continuation when section already ends normally',
      () async {
    final base = await service.getCommentaryForRef('bodhicaryavatara', '1.3ab');
    final chained = await service.getCommentaryForRefWithContinuation('bodhicaryavatara', '1.3ab');
    expect(base, isNotNull);
    expect(chained, isNotNull);
    expect(chained!.commentaryText, base!.commentaryText);
    expect(chained.refsInBlock, equals(base.refsInBlock));
  });
}
