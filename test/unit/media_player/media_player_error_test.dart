@Tags(['unit', 'player'])

import 'package:flutter/material.dart' show Directionality, TextDirection;
import 'package:flutter/services.dart' show PlatformException;

import 'package:flutter_test/flutter_test.dart';

import 'package:lunofono_player/src/media_player/media_player_error.dart'
    show MediaPlayerError;

import '../../util/finders.dart' show findSubString;

void main() {
  group('MediaPlayerError', () {
    testWidgets('Exception', (WidgetTester tester) async {
      final exception = Exception('This is an error');
      final widget = MediaPlayerError(exception);
      await tester.pumpWidget(
          Directionality(textDirection: TextDirection.ltr, child: widget));
      expect(find.text('Media could not be played: $exception'), findsWidgets);
    });

    testWidgets('PlatformException', (WidgetTester tester) async {
      final exception = PlatformException(
        code: 'Error Code',
        message: 'Error message',
        details: 'Error details',
      );
      final widget = MediaPlayerError(exception);
      await tester.pumpWidget(
          Directionality(textDirection: TextDirection.ltr, child: widget));
      expect(findSubString('Media could not be played'), findsOneWidget);
      expect(findSubString(exception.message), findsOneWidget);
      expect(findSubString(exception.details.toString()), findsOneWidget);
    });
  });
}
