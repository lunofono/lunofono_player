@Tags(['unit', 'player'])

import 'package:flutter/material.dart' hide Orientation;
import 'package:flutter_test/flutter_test.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show Bundle, Menu, Orientation;
import 'package:lunofono_player/src/platform_services.dart'
    show PlatformServices;
import 'package:lunofono_player/src/bundle_player.dart' show BundlePlayer;
import 'package:lunofono_player/src/menu_player.dart'
    show MenuPlayer, MenuPlayerRegistry;

void main() {
  group('BundlePlayer', () {
    testWidgets(
      'PlatformServices are called and the rootMenu is built',
      (WidgetTester tester) async {
        // Setup fake environment
        final services = FakePlatformServices();
        MenuPlayer.registry = MenuPlayerRegistry();
        MenuPlayer.registry
            .register(FakeMenu, (m) => FakeMenuPlayer(m as FakeMenu));

        // Create test bundle, player and app
        final testBundle = Bundle(FakeMenu());
        final bundlePlayer =
            BundlePlayer(testBundle, platformServices: services);
        // XXX: We need to make it inside a MaterialApp, see the first test.
        final testBundleApp = MaterialApp(title: 'Test', home: bundlePlayer);

        // Pump the test app
        await tester.pumpWidget(testBundleApp);

        // Services should have been called
        expect(services.calledFullScreen, isTrue);
        expect(services.calledOrientation, Orientation.portrait);
        expect(services.calledInhibitScreenOff, isTrue);

        // The FakeMenu should have been built.
        expect(find.byKey(FakeMenuPlayer.globalKey), findsOneWidget);
      },
    );
  });
}

class FakeMenu extends Menu {}

class FakeMenuPlayer extends MenuPlayer {
  static Key globalKey = GlobalKey(debugLabel: 'FakeMenuPlayerKey');
  FakeMenuPlayer(this.menu);
  @override
  final FakeMenu menu;
  @override
  Widget build(BuildContext context) {
    return Container(child: Text('FakeMenu'), key: globalKey);
  }
}

class FakePlatformServices extends PlatformServices {
  bool? calledFullScreen;
  Orientation? calledOrientation;
  bool? calledInhibitScreenOff;
  @override
  Future<void> setFullScreen({required bool on}) async {
    calledFullScreen = on;
  }

  @override
  Future<void> setOrientation(Orientation orientation) async {
    calledOrientation = orientation;
  }

  @override
  Future<void> inhibitScreenOff({required bool on}) async {
    calledInhibitScreenOff = on;
  }
}
