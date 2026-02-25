import 'package:dechen_study/screens/auth/login_screen.dart';
import 'package:dechen_study/screens/auth/signup_screen.dart';
import 'package:dechen_study/screens/landing/bcv_file_quiz_screen.dart';
import 'package:dechen_study/screens/landing/gateway_landing_screen.dart';
import 'package:dechen_study/screens/landing/text_options_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Screen smoke tests', () {
    testWidgets('LoginScreen builds and shows key elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pump();
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Don\'t have an account? Sign up'), findsOneWidget);
    });

    testWidgets('SignUpScreen builds and shows key elements', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignUpScreen(),
        ),
      );
      await tester.pump();
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('TextOptionsScreen builds and shows study modes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TextOptionsScreen(
            textId: 'bodhicaryavatara',
            title: 'Bodhicaryavatara',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Bodhicaryavatara'), findsWidgets);
      expect(find.text('Daily Verses'), findsOneWidget);
      expect(find.text('Guess the Chapter'), findsOneWidget);
    });

    testWidgets('GatewayLandingScreen builds and shows title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: GatewayLandingScreen(),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Gateway to Knowledge'), findsWidgets);
    });

    testWidgets('BcvFileQuizScreen builds and shows Quiz', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BcvFileQuizScreen(),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Quiz'), findsWidgets);
    });
  });
}
