import 'package:dechen_study/screens/landing/bcv/bcv_inline_commentary_panel.dart';
import 'package:dechen_study/screens/landing/read_screen.dart';
import 'package:dechen_study/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDown(() {
    VisibilityDetectorController.instance.updateInterval =
        const Duration(milliseconds: 500);
  });

  testWidgets(
    'KOA reader hides chapter pane controls and does not open commentary',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            scaffoldBackgroundColor: AppColors.scaffoldBackground,
          ),
          home: const ReadScreen(
            textId: 'kingofaspirations',
            title: 'The King of Aspiration Prayers',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byTooltip('Show Chapter'), findsNothing);
      expect(find.byTooltip('Hide Chapter'), findsNothing);
      expect(find.textContaining('Chapter 1:'), findsNothing);

      await tester.tap(find.textContaining('To all the buddhas').first);
      await tester.pumpAndSettle();

      expect(find.byType(BcvInlineCommentaryPanel), findsNothing);
    },
  );
}
