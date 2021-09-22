@Tags(['unit', 'player'])

import 'package:flutter/material.dart' hide Action;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show Action, Button, Color, StyledButton;
import 'package:lunofono_player/src/action_player.dart';
import 'package:lunofono_player/src/button_player.dart';

class FakeAction extends Action {}

class FakeActionPlayer extends ActionPlayer {
  @override
  final FakeAction action;
  @override
  void act(BuildContext context, ButtonPlayer button) {}
  FakeActionPlayer(this.action);
}

class FakeButton extends Button {
  FakeButton() : super(FakeAction());
}

class _FakeButtonPlayer extends ButtonPlayer {
  @override
  final FakeButton button;

  @override
  Widget build(BuildContext context) => Container(key: ObjectKey(button));

  _FakeButtonPlayer(this.button) : super(button);
}

class FakeContext extends Fake implements BuildContext {}

void main() {
  group('ButtonPlayer', () {
    final oldButtonRegistry = ButtonPlayer.registry;
    FakeButton? fakeButton;
    late FakeContext fakeContext;
    Color? color;

    setUp(() {
      fakeButton = FakeButton();
      fakeContext = FakeContext();
      color = const Color(0x12ab4523);

      ActionPlayer.registry = ActionPlayerRegistry();
      ActionPlayer.registry
          .register(FakeAction, (a) => FakeActionPlayer(a as FakeAction));
    });

    tearDown(() => ButtonPlayer.registry = oldButtonRegistry);

    test('empty registry is empty', () {
      ButtonPlayer.registry = ButtonPlayerRegistry();
      expect(ButtonPlayer.registry, isEmpty);
      expect(() => ButtonPlayer.wrap(fakeButton!), throwsAssertionError);
    });

    test('registration and base ButtonPlayer implementation works', () {
      ButtonPlayer.registry = ButtonPlayerRegistry();
      ButtonPlayer.registry
          .register(FakeButton, (b) => _FakeButtonPlayer(b as FakeButton));
      final buttonPlayer = ButtonPlayer.wrap(fakeButton!);
      expect(buttonPlayer.backgroundColor, isNull);
      expect(buttonPlayer.action.action, fakeButton!.action);
      final widget = buttonPlayer.build(fakeContext);
      expect(widget.key, ObjectKey(fakeButton));
    });

    test('builtin types are registered', () {
      final styledButton = StyledButton(FakeAction(), backgroundColor: color);
      expect(ButtonPlayer.wrap(styledButton), isA<ButtonPlayer>());
    });
  });
}
