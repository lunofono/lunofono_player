@Tags(['unit', 'platform'])

import 'package:flutter_test/flutter_test.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart' show Orientation;
import 'package:lunofono_player/src/platform_services.dart';

// XXX: Note that these tests will just test that the basic API is as expected,
// and no errors are thrown when services are used, but it DOES NOT verify that
// the services are doing what they are supposed to do. We just rely on
// upstream being tested (finger crossed).
//
// They are also included as Widget tests as the platform services need the
// Flutter machinery to be up and running to be invoked.

void main() {
  group('PlatformServices', () {
    // These are testWidgets() calls instead of plain dart test() calls because
    // some bindings need to be initialized to use platform services.
    void testInstance(PlatformServices instance) {
      testWidgets('setFullScreen()', (WidgetTester tester) async {
        expect(
          () async => await instance.setFullScreen(on: true),
          returnsNormally,
        );
        expect(
          () async => await instance.setFullScreen(on: false),
          returnsNormally,
        );
      });

      testWidgets('setOrientation()', (WidgetTester tester) async {
        for (final orientation in Orientation.values) {
          expect(
            () async => await instance.setOrientation(orientation),
            returnsNormally,
            reason: 'Orientation: $orientation',
          );
        }
      });

      testWidgets('inhibitScreenOff()', (WidgetTester tester) async {
        expect(
          () async => await instance.inhibitScreenOff(on: true),
          returnsNormally,
        );
        expect(
          () async => await instance.inhibitScreenOff(on: false),
          returnsNormally,
        );
      });
    }

    group('new const instance', () {
      testInstance(const PlatformServices());
    });

    group('new instance', () {
      testInstance(const PlatformServices());
    });
  });
}
