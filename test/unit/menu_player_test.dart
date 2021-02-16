@Tags(['unit', 'player'])

import 'package:flutter/material.dart' hide Orientation, Action;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:flutter_grid_button/flutter_grid_button.dart'
    show GridButtonItem;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show GridMenu, Button, Action, Menu;
import 'package:lunofono_player/src/action_player.dart'
    show ActionPlayer, ActionPlayerRegistry;
import 'package:lunofono_player/src/button_player.dart'
    show ButtonPlayer, ButtonPlayerRegistry;
import 'package:lunofono_player/src/menu_player.dart';

void main() {
  group('MenuPlayer', () {
    FakeButton fakeButtonRed;
    FakeButton fakeButtonBlue;
    final oldActionRegistry = ActionPlayer.registry;
    final oldButtonRegistry = ButtonPlayer.registry;

    setUp(() {
      fakeButtonRed = FakeButton(Colors.red);
      fakeButtonBlue = FakeButton(Colors.blue);

      ActionPlayer.registry = ActionPlayerRegistry();
      ActionPlayer.registry.register(
          FakeAction, (action) => FakeActionPlayer(action as FakeAction));

      ButtonPlayer.registry = ButtonPlayerRegistry();
      ButtonPlayer.registry
          .register(FakeButton, (b) => FakeButtonPlayer(b as FakeButton));
    });

    tearDown(() {
      ActionPlayer.registry = oldActionRegistry;
      ButtonPlayer.registry = oldButtonRegistry;
    });

    group('MenuPlayerRegistry', () {
      final oldMenuRegistry = MenuPlayer.registry;
      FakeContext fakeContext;
      FakeMenu fakeMenu;

      setUp(() {
        fakeContext = FakeContext();
        fakeMenu = FakeMenu();
      });

      tearDown(() => MenuPlayer.registry = oldMenuRegistry);

      test('empty', () {
        MenuPlayer.registry = MenuPlayerRegistry();
        expect(MenuPlayer.registry, isEmpty);
        expect(() => MenuPlayer.wrap(fakeMenu), throwsAssertionError);
      });

      test('registration and calling from empty', () {
        MenuPlayer.registry = MenuPlayerRegistry();
        MenuPlayer.registry
            .register(FakeMenu, (m) => FakeMenuPlayer(m as FakeMenu));

        final builtWidget = MenuPlayer.wrap(fakeMenu).build(fakeContext);
        expect(fakeMenu.buildCalls.length, 1);
        expect(fakeMenu.buildCalls.last.context, same(fakeContext));
        expect(fakeMenu.buildCalls.last.returnedWidget, same(builtWidget));
      });

      group('builtin', () {
        group('GridMenuPlayer', () {
          Menu menu;
          MenuPlayer menuPlayer;

          setUp(() {
            // XXX: We need to build this in the setUp() method because
            // fakeButtonXxx are also built in a setUp() method because they
            // store state, and need to be reset on each test run.
            menu = GridMenu(
              rows: 1,
              columns: 2,
              buttons: [
                fakeButtonRed,
                fakeButtonBlue,
              ],
            );
            menuPlayer = MenuPlayer.wrap(menu);
          });

          test('constructor asserts if menu is null', () {
            expect(() => GridMenuPlayer(null), throwsAssertionError);
          });

          testWidgets(
            'build() builds the right widgets',
            (WidgetTester tester) async {
              expect(menuPlayer, isA<GridMenuPlayer>());
              final gridMenuPlayer = menuPlayer as GridMenuPlayer;
              final gridMenu = menu as GridMenu;

              // Matches the underlaying menu
              expect(gridMenuPlayer.rows, gridMenu.rows);
              expect(gridMenuPlayer.columns, gridMenu.columns);
              expect(
                  gridMenuPlayer.buttons.first.button, gridMenu.buttonAt(0, 0));

              // Build returns a GridMenuWidget
              final menuWidget = menuPlayer.build(fakeContext);
              expect(menuWidget, isA<GridMenuWidget>());
              expect((menuWidget as GridMenuWidget).menu, same(menuPlayer));

              // Builds the right buttons (we have text, so we need
              // a Directionality)
              await tester.pumpWidget(Directionality(
                textDirection: TextDirection.ltr,
                child: menuWidget,
              ));
              expect(fakeButtonRed.createCalls.length, 1);
              expect(
                  (fakeButtonRed.createCalls.last.value as FakeButtonPlayer)
                      .button,
                  same(fakeButtonRed));
              expect(fakeButtonRed.actCalls, isEmpty);
              expect(fakeButtonBlue.createCalls.length, 1);
              expect(
                  (fakeButtonBlue.createCalls.last.value as FakeButtonPlayer)
                      .button,
                  same(fakeButtonBlue));
              expect(fakeButtonBlue.actCalls, isEmpty);
            },
          );

          testWidgets('GridMenuWidget tap calls button.action.act()',
              (WidgetTester tester) async {
            await tester.pumpWidget(
              Directionality(
                textDirection: TextDirection.ltr,
                child: Builder(
                  builder: (context) => menuPlayer.build(context),
                ),
              ),
            );

            Finder findButtonByColor(Color c) {
              return find.byWidgetPredicate(
                (w) => w is Material && w.color == c,
              );
            }

            // Tap red, only red's button act() was called
            expect(findButtonByColor(Colors.red), findsOneWidget);
            await tester.tap(findButtonByColor(Colors.red));
            await tester.pump();
            expect(fakeButtonRed.actCalls.length, 1);
            expect(fakeButtonRed.actCalls.last.button, fakeButtonRed);
            expect(fakeButtonBlue.actCalls, isEmpty);

            // Tap blue, only blue's button act() was called
            expect(findButtonByColor(Colors.blue), findsOneWidget);
            await tester.tap(findButtonByColor(Colors.blue));
            await tester.pump();
            expect(fakeButtonRed.actCalls.length, 1);
            expect(fakeButtonRed.actCalls.last.button, fakeButtonRed);
            expect(fakeButtonBlue.actCalls.length, 1);
            expect(fakeButtonBlue.actCalls.last.button, fakeButtonBlue);

            // Tap blue 3 times, only blue's button act() was called 3 times
            for (var i = 1; i <= 3; i++) {
              expect(findButtonByColor(Colors.blue), findsOneWidget);
              await tester.tap(findButtonByColor(Colors.blue));
              await tester.pump();
              expect(fakeButtonRed.actCalls.length, 1);
              expect(fakeButtonRed.actCalls.last.button, fakeButtonRed);
              expect(fakeButtonBlue.actCalls.length, 1 + i);
              expect(fakeButtonBlue.actCalls.last.button, fakeButtonBlue);
            }

            // Tap red again, only red's button act() was called
            expect(findButtonByColor(Colors.red), findsOneWidget);
            await tester.tap(findButtonByColor(Colors.red));
            await tester.pump();
            expect(fakeButtonRed.actCalls.length, 2);
            expect(fakeButtonRed.actCalls.last.button, fakeButtonRed);
            expect(fakeButtonBlue.actCalls.length, 4);
            expect(fakeButtonBlue.actCalls.last.button, fakeButtonBlue);
          });
        });
      });
    });
  });
}

class FakeContext extends Fake implements BuildContext {}

class BuildCall {
  final BuildContext context;
  final Widget returnedWidget;
  BuildCall(this.context, this.returnedWidget);
}

class FakeMenu extends Menu {
  final buildCalls = <BuildCall>[];
}

class FakeMenuPlayer extends MenuPlayer {
  @override
  final FakeMenu menu;
  FakeMenuPlayer(this.menu) : assert(menu != null);
  static Key globalKey = GlobalKey(debugLabel: 'FakeMenuPlayerKey');
  @override
  Widget build(BuildContext context) {
    final widget = Container(child: Text('FakeMenu'), key: globalKey);
    menu.buildCalls.add(BuildCall(context, widget));
    return widget;
  }
}

class FakeAction extends Action {
  final actCalls = <ButtonPlayer>[];
}

class FakeActionPlayer extends ActionPlayer {
  @override
  final FakeAction action;
  const FakeActionPlayer(this.action) : assert(action != null);
  @override
  void act(BuildContext context, ButtonPlayer button) =>
      action.actCalls.add(button);
}

class FakeButton extends Button {
  final Color color;
  FakeButton(this.color) : super(FakeAction());
  final createCalls = <GridButtonItem>[];
  List<ButtonPlayer> get actCalls => (action as FakeAction).actCalls;
}

class FakeButtonPlayer extends ButtonPlayer {
  @override
  final FakeButton button;
  @override
  GridButtonItem create(BuildContext context) {
    final item = GridButtonItem(
      value: this,
      title: '',
      color: button.color,
    );
    button.createCalls.add(item);
    return item;
  }

  FakeButtonPlayer(this.button) : super(button);
}
