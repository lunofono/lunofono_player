@Tags(['unit', 'player'])

import 'package:flutter/material.dart' show ValueKey, BuildContext;

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
  FakeActionPlayer(this.action) : assert(action != null);
}

class FakeButton extends Button {
  FakeButton() : super(FakeAction());
}

class FakeButtonPlayer extends ButtonPlayer {
  @override
  final FakeButton button;

  @override
  GridButtonItem create(BuildContext context) {
    return GridButtonItem(color: backgroundColor, value: action, title: '');
  }

  FakeButtonPlayer(this.button) : super(button);
}

class FakeContext extends Fake implements BuildContext {}

void main() {
  group('ButtonPlayer', () {
    final oldButtonRegistry = ButtonPlayer.registry;
    FakeButton fakeButton;
    FakeContext fakeContext;
    Color color;

    setUp(() {
      fakeButton = FakeButton();
      fakeContext = FakeContext();
      color = Color(0x12ab4523);

      ActionPlayer.registry = ActionPlayerRegistry();
      ActionPlayer.registry
          .register(FakeAction, (a) => FakeActionPlayer(a as FakeAction));
    });

    tearDown(() => ButtonPlayer.registry = oldButtonRegistry);

    test('empty registry is empty', () {
      ButtonPlayer.registry = ButtonPlayerRegistry();
      expect(ButtonPlayer.registry, isEmpty);
      expect(() => ButtonPlayer.wrap(fakeButton), throwsAssertionError);
    });

    test('registration and base ButtonPlayer implementation works', () {
      expect(() => FakeButtonPlayer(null), throwsAssertionError);
      ButtonPlayer.registry = ButtonPlayerRegistry();
      ButtonPlayer.registry
          .register(FakeButton, (b) => FakeButtonPlayer(b as FakeButton));
      final buttonPlayer = ButtonPlayer.wrap(fakeButton);
      expect(buttonPlayer.backgroundColor, isNull);
      expect(buttonPlayer.action.action, fakeButton.action);
      final gridItem = buttonPlayer.create(fakeContext);
      expect(gridItem.color, buttonPlayer.backgroundColor);
      expect(gridItem.value, buttonPlayer.action);
      expect(gridItem.title, '');
    });

    test('builtin types are registered and work as expected', () {
      expect(() => StyledButtonPlayer(null), throwsAssertionError);
      final styledButton = StyledButton(FakeAction(), backgroundColor: color);
      final buttonPlayer = ButtonPlayer.wrap(styledButton);
      final gridButtonItem = buttonPlayer.create(fakeContext);
      expect(gridButtonItem.color, color);
      expect(gridButtonItem.key, isA<ValueKey>());
      expect(gridButtonItem.title, '');
      expect(gridButtonItem.value, buttonPlayer);
      expect(gridButtonItem.borderRadius, 50);
    });
  });
}
