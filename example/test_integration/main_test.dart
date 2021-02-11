import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter/material.dart' hide Image;

import 'package:lunofono_player_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('test video playing from local assets',
      (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    await tester.pumpAndSettle();

    expect(findByMaterialColor(Colors.amber), findsOneWidget);
    expect(findByMaterialColor(Colors.red), findsOneWidget);

    await tester.tap(findByMaterialColor(Colors.amber));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(findSubString('Media could not be played: '), findsNothing);
  });
}

Finder findByMaterialColor(Color c) => find.byWidgetPredicate(
      (w) => w is Material && w.color == c,
    );

/// Finds a [Text] widget whose content contains the [substring].
Finder findSubString(String substring) {
  return find.byWidgetPredicate((widget) {
    if (widget is Text) {
      if (widget.data != null) {
        return widget.data.contains(substring);
      }
      return widget.textSpan.toPlainText().contains(substring);
    }
    return false;
  });
}
