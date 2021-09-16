@Tags(['unit', 'player'])

import 'package:flutter/material.dart' show BuildContext;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show Action, Color, Playable, PlayContentAction;
import 'package:lunofono_player/src/action_player.dart';
import 'package:lunofono_player/src/button_player.dart' show ButtonPlayer;
import 'package:lunofono_player/src/playable_player.dart'
    show PlayablePlayer, PlayablePlayerRegistry;

class FakePlayable extends Playable {
  BuildContext? playedContext;
  Color? playedColor;

  void expectCalled(BuildContext? context, Color backgroundColor) {
    expect(playedContext, context);
    expect(playedColor, backgroundColor);
  }
}

class FakePlayablePlayer extends PlayablePlayer {
  @override
  final FakePlayable playable;
  @override
  void play(BuildContext context, [Color? backgroundColor]) {
    playable.playedContext = context;
    playable.playedColor = backgroundColor;
  }

  FakePlayablePlayer(this.playable);
}

class FakeAction extends Action {}

class FakeActionPlayer extends ActionPlayer {
  late final Action calledAction;
  late final BuildContext calledContext;
  late final ButtonPlayer calledButton;

  @override
  final FakeAction action;
  @override
  void act(BuildContext context, ButtonPlayer button) {
    calledAction = action;
    calledContext = context;
    calledButton = button;
  }

  FakeActionPlayer(this.action);
}

class FakeButtonPlayer extends Fake implements ButtonPlayer {
  @override
  Color get backgroundColor => Color(0x12345678);
}

class FakeContext extends Fake implements BuildContext {}

void main() {
  group('ActionPlayer', () {
    final oldActionRegistry = ActionPlayer.registry;
    FakeContext? fakeContext;
    FakeAction? fakeAction;
    FakeButtonPlayer? fakeButton;

    setUp(() {
      fakeContext = FakeContext();
      fakeAction = FakeAction();
      fakeButton = FakeButtonPlayer();
    });

    tearDown(() => ActionPlayer.registry = oldActionRegistry);

    test('empty', () {
      ActionPlayer.registry = ActionPlayerRegistry();
      expect(ActionPlayer.registry.isEmpty, isTrue);
      expect(
          () => ActionPlayer.wrap(fakeAction!).act(fakeContext!, fakeButton!),
          throwsAssertionError);
    });

    test('registration and base ActionPlayer implementation works', () {
      ActionPlayer.registry = ActionPlayerRegistry();
      ActionPlayer.registry.register(
          FakeAction, (action) => FakeActionPlayer(action as FakeAction));
      final actionPlayer = ActionPlayer.wrap(fakeAction!) as FakeActionPlayer;
      actionPlayer.act(fakeContext!, fakeButton!);
      expect(actionPlayer.calledAction, same(fakeAction));
      expect(actionPlayer.calledContext, same(fakeContext));
      expect(actionPlayer.calledButton, same(fakeButton));
    });

    group('PlayContentAction builtin', () {
      var fakePlayable = FakePlayable();
      final oldPlayableRegistry = PlayablePlayer.registry;

      setUp(() {
        PlayablePlayer.registry = PlayablePlayerRegistry();
        PlayablePlayer.registry.register(FakePlayable,
            (playable) => FakePlayablePlayer(playable as FakePlayable));
        fakePlayable = FakePlayable();
      });

      tearDown(() => PlayablePlayer.registry = oldPlayableRegistry);

      test('dynamic dispatch', () {
        final Action action = PlayContentAction(fakePlayable);
        final actionPlayer = ActionPlayer.wrap(action);
        actionPlayer.act(fakeContext!, fakeButton!);
        fakePlayable.expectCalled(fakeContext, fakeButton!.backgroundColor);
      });

      test('direct call', () {
        final action = ActionPlayer.wrap(PlayContentAction(fakePlayable));
        action.act(fakeContext!, fakeButton!);
        fakePlayable.expectCalled(fakeContext, fakeButton!.backgroundColor);
      });
    });
  });
}
