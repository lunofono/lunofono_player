@Tags(['unit', 'player'])

import 'package:flutter/material.dart' hide Action;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart' show Action, ImageButton;

import 'package:lunofono_player/src/action_player.dart';
import 'package:lunofono_player/src/button_player.dart';

import 'package:lunofono_player/src/button_player/image_button_player.dart';

import '../../util/test_asset_bundle.dart' show TestAssetBundle;

class FakeAction extends Action {
  final actCalls = <ButtonPlayer>[];
}

class FakeActionPlayer extends ActionPlayer {
  @override
  final FakeAction action;
  @override
  void act(BuildContext context, ButtonPlayer button) =>
      action.actCalls.add(button);
  FakeActionPlayer(this.action) : assert(action != null);
}

class FakeContext extends Fake implements BuildContext {}

void main() {
  final imageUri = Uri.parse('assets/10x10-red.png');
  final oldActionRegistry = ActionPlayer.registry;

  setUp(() {
    ActionPlayer.registry = ActionPlayerRegistry();
    ActionPlayer.registry
        .register(FakeAction, (a) => FakeActionPlayer(a as FakeAction));
  });

  tearDown(() => ActionPlayer.registry = oldActionRegistry);

  group('ImageButtonPlayer', () {
    FakeContext fakeContext;

    setUp(() {
      fakeContext = FakeContext();
    });

    test('constructor asserts on null', () {
      expect(() => ImageButtonPlayer(null), throwsAssertionError);
    });

    test('build creates a ImageButtonWidget', () {
      final button = ImageButton(FakeAction(), imageUri);
      final buttonPlayer = ButtonPlayer.wrap(button);
      expect(buttonPlayer.button, same(button));
      expect((buttonPlayer as ImageButtonPlayer).imageUri, button.imageUri);
      final widget = buttonPlayer.build(fakeContext);
      expect(widget.key, ObjectKey(button));
    });
  });

  group('ImageButtonWidget', () {
    test('constructor asserts on null button', () {
      expect(() => ImageButtonWidget(button: null), throwsAssertionError);
    });

    testWidgets('tapping calls action.act()', (tester) async {
      final action = FakeAction();
      final button = ImageButton(action, imageUri);
      final buttonPlayer = ButtonPlayer.wrap(button);
      Widget widget;
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultAssetBundle(
            bundle: TestAssetBundle(),
            child: Builder(builder: (context) {
              widget = buttonPlayer.build(context);
              return widget;
            }),
          ),
        ),
      );
      expect(widget.key, ObjectKey(button));
      expect(widget, isA<ImageButtonWidget>());
      expect((widget as ImageButtonWidget).button, same(buttonPlayer));
      expect(action.actCalls.length, 0);
      final buttonFinder = find.byKey(ObjectKey(button));
      expect(buttonFinder, findsOneWidget);
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      // tap the button should call button.act()
      await tester.tap(buttonFinder);
      await tester.pump();
      expect(action.actCalls.length, 1);
      expect(action.actCalls.last, buttonPlayer);

      // tap the image should call button.act()
      await tester.tap(imageFinder);
      await tester.pump();
      expect(action.actCalls.length, 2);
      expect(action.actCalls.last, buttonPlayer);
    });
  });
}
