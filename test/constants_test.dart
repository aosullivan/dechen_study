import 'package:flutter_test/flutter_test.dart';

import 'package:dechen_study/utils/constants.dart' as constants;

void main() {
  group('constants', () {
    test('appEnvironment is test or prod', () {
      expect(constants.appEnvironment, isNotEmpty);
      expect(
        constants.appEnvironment == 'test' || constants.appEnvironment == 'prod',
        true,
      );
    });

    test('isTest and isProd are mutually exclusive', () {
      expect(constants.isTest, isNot(equals(constants.isProd)));
    });

    test('isTest is true when appEnvironment is test', () {
      expect(constants.isTest, equals(constants.appEnvironment == 'test'));
    });

    test('isProd is true when appEnvironment is prod', () {
      expect(constants.isProd, equals(constants.appEnvironment == 'prod'));
    });

    test('safeSupabaseUrl returns a string', () {
      expect(constants.safeSupabaseUrl, isA<String>());
    });

    test('safeSupabaseAnonKey returns a string', () {
      expect(constants.safeSupabaseAnonKey, isA<String>());
    });

    test('isSupabaseConfigured is true only when both url and key are non-empty', () {
      final urlEmpty = constants.safeSupabaseUrl.isEmpty;
      final keyEmpty = constants.safeSupabaseAnonKey.isEmpty;
      expect(constants.isSupabaseConfigured, equals(!urlEmpty && !keyEmpty));
    });
  });
}
