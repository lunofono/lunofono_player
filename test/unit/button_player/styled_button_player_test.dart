@Tags(['unit', 'player'])

import 'package:flutter/material.dart' hide Action;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show Action, Color, StyledButton;

import 'package:lunofono_player/src/action_player.dart';
import 'package:lunofono_player/src/button_player.dart';

import 'package:lunofono_player/src/button_player/styled_button_player.dart';

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
  FakeActionPlayer(this.action);
}

class FakeContext extends Fake implements BuildContext {}

void main() {
  final oldActionRegistry = ActionPlayer.registry;
  setUp(() {
    ActionPlayer.registry = ActionPlayerRegistry();
    ActionPlayer.registry
        .register(FakeAction, (a) => FakeActionPlayer(a as FakeAction));
  });

  tearDown(() => ActionPlayer.registry = oldActionRegistry);

  group('StyledButtonPlayer', () {
    late FakeContext fakeContext;
    Color? color;

    setUp(() {
      fakeContext = FakeContext();
      color = const Color(0x12ab4523);
    });

    test('build creates a StyledButtonWidget', () {
      final styledButton = StyledButton(FakeAction(), backgroundColor: color);
      final buttonPlayer = ButtonPlayer.wrap(styledButton);
      expect(buttonPlayer.button, same(styledButton));
      expect(buttonPlayer.backgroundColor, styledButton.backgroundColor);
      final widget = buttonPlayer.build(fakeContext);
      expect(widget.key, ObjectKey(styledButton));
    });
  });

  group('StyledButtonWidget', () {
    testWidgets('tapping calls action.act()', (tester) async {
      final action = FakeAction();
      final button = StyledButton(action);
      final buttonPlayer = ButtonPlayer.wrap(button);
      Widget? widget;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            widget = buttonPlayer.build(context);
            return widget!;
          }),
        ),
      );
      expect(widget!.key, ObjectKey(button));
      expect(widget, isA<StyledButtonWidget>());
      expect((widget as StyledButtonWidget).button, same(buttonPlayer));
      expect(find.byType(Image), findsNothing);
      expect(action.actCalls.length, 0);

      // tap the button should call button.act()
      final buttonFinder = find.byKey(ObjectKey(button));
      expect(buttonFinder, findsOneWidget);
      await tester.tap(buttonFinder);
      await tester.pump();
      expect(action.actCalls.length, 1);
      expect(action.actCalls.last, buttonPlayer);
    });

    testWidgets(
        'shows foregroundImage and tapping the image also calls action.act()',
        (tester) async {
      final action = FakeAction();
      final button = StyledButton(action,
          foregroundImage: Uri.parse('assets/10x10-red.png'));
      final buttonPlayer = ButtonPlayer.wrap(button);
      late final Widget widget;
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
      expect(widget, isA<StyledButtonWidget>());
      expect((widget as StyledButtonWidget).button, same(buttonPlayer));
      expect(action.actCalls.length, 0);
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      // tap the button should call button.act()
      // FIXME: The warnIfMissed had to be added in one update of Flutter, and
      // it is not clear why it happens that it says the images is not being
      // hit, but the action is called.
      await tester.tap(imageFinder, warnIfMissed: false);
      await tester.pump();
      expect(action.actCalls.length, 1);
      expect(action.actCalls.last, buttonPlayer);
    });
  });
}
