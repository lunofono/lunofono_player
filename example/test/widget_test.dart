import 'package:flutter_test/flutter_test.dart';

import 'package:lunofono_player/lunofono_player.dart';
import 'package:lunofono_player_example/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    expect(find.byType(BundlePlayer), findsOneWidget);
  });
}
