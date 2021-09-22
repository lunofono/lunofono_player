@Tags(['unit', 'player'])

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:lunofono_player/src/media_player/media_progress_indicator.dart';

void main() {
  group('MediaProgressIndicator', () {
    Future<void> testInnerWidgets(WidgetTester tester,
        {required IconData icon, required bool visualizable}) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaProgressIndicator(visualizable: visualizable),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsOneWidget);
      expect((tester.widget(iconFinder) as Icon).icon, icon);
    }

    testWidgets(
        'if not visualizable has a CircularProgressIndicator and '
        'a musical note icon', (WidgetTester tester) async {
      await testInnerWidgets(tester,
          visualizable: false, icon: Icons.music_note);
    });

    testWidgets(
        'if t is visualizable has a CircularProgressIndicator and '
        'a movie film icon', (WidgetTester tester) async {
      await testInnerWidgets(tester,
          visualizable: true, icon: Icons.local_movies);
    });
  });
}
