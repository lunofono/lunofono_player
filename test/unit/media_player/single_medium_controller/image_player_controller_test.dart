@Tags(['unit', 'player'])

import 'dart:ui' as ui;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:lunofono_bundle/lunofono_bundle.dart' as bundle show Image;
import 'package:lunofono_player/src/media_player/single_medium_controller.dart';

import 'single_medium_controller_common.dart';

class _FakeContext extends Fake implements BuildContext {}

void main() {
  group('ImagePlayerController', () {
    late ImagePlayerController controller;
    tearDown(() async => await controller.dispose());

    testWidgets(
      'initializes with error',
      (WidgetTester tester) async {
        controller = ImagePlayerController(
          bundle.Image(Uri.parse('i-dont-exist.png')),
          widgetKey: globalSuccessKey,
        );
        final widget = TestWidget(controller);
        await tester.pumpWidget(widget);
        expectLoading(tester, widget);

        await tester.pumpAndSettle();
        expectInitError(tester, widget);
      },
    );

    testWidgets(
      'initialization of 10x10 asset without onMediumFinished',
      (WidgetTester tester) async {
        controller = ImagePlayerController(
          bundle.Image(Uri.parse('assets/10x10-red.png')),
          widgetKey: globalSuccessKey,
        );
        final widget = TestWidget(controller);
        await tester.pumpWidget(widget);
        expectLoading(tester, widget);

        await tester.runAsync(() async => await undeadlockAsync()); // XXX!!!
        await tester.pumpAndSettle();
        expectSuccess(tester, widget,
            size: Size(10.0, 10.0), findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
      },
    );

    testWidgets(
      'onMediumFinished is not called plays forever (forever is 10 days)',
      (WidgetTester tester) async {
        var hasStopped = false;
        controller = ImagePlayerController(
          bundle.Image(Uri.parse('assets/10x10-red.png')),
          onMediumFinished: (context) => hasStopped = true,
          widgetKey: globalSuccessKey,
        );
        final widget = TestWidget(controller);

        await tester.pumpWidget(widget);
        expectLoading(tester, widget);
        expect(hasStopped, false);

        await tester.runAsync(() async => await undeadlockAsync()); // XXX!!!
        await tester.pumpAndSettle();
        final size = Size(10.0, 10.0);
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, false);

        // pause() has not effect when there is no maxDuration.
        await controller.pause(_FakeContext());

        await tester.pump(Duration(days: 10));
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, false);
      },
    );

    testWidgets(
      'onMediumFinished is called if maxDuration is set',
      (WidgetTester tester) async {
        var hasStopped = false;
        final image = bundle.Image(
          Uri.parse('assets/10x10-red.png'),
          maxDuration: Duration(seconds: 1),
        );
        controller = ImagePlayerController(
          image,
          onMediumFinished: (context) => hasStopped = true,
          widgetKey: globalSuccessKey,
        );
        final widget = TestWidget(controller);

        await tester.pumpWidget(widget);
        expectLoading(tester, widget);
        expect(hasStopped, false);

        await tester.runAsync(() async => await undeadlockAsync()); // XXX!!!
        await tester.pumpAndSettle();
        final size = Size(10.0, 10.0);
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, false);

        // Half the time passes, it should be still playing
        await tester.pump(image.maxDuration ~/ 2);
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, false);

        // Now all the time passed, so onMediumFinished should have been called
        await tester.pump(image.maxDuration ~/ 2);
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, true);
      },
    );

    testWidgets(
      'onMediumFinished pause() works when maxDuration is set',
      (WidgetTester tester) async {
        var hasStopped = false;
        final image = bundle.Image(
          Uri.parse('assets/10x10-red.png'),
          maxDuration: Duration(seconds: 1),
        );
        controller = ImagePlayerController(
          image,
          onMediumFinished: (context) => hasStopped = true,
          widgetKey: globalSuccessKey,
        );
        final widget = TestWidget(controller);

        await tester.pumpWidget(widget);
        expectLoading(tester, widget);
        expect(hasStopped, false);

        await tester.runAsync(() async => await undeadlockAsync()); // XXX!!!
        await tester.pumpAndSettle();
        final size = Size(10.0, 10.0);
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, false);

        // Half the time passes, it should be still playing
        await tester.pump(image.maxDuration ~/ 2);
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, false);

        // Now we pause and let a day go by and it should be still playing
        await controller.pause(_FakeContext());
        await tester.pump(Duration(days: 1));
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, false);

        // Now we resume playing and let the final half of the maxDuration pass
        // and it should have finished
        await controller.play(_FakeContext());
        await tester.pump(image.maxDuration ~/ 2);
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, true);
      },
    );

    testWidgets(
      'maxDurationTimer is started when the image is first played',
      (WidgetTester tester) async {
        var hasStopped = false;
        final image = bundle.Image(
          Uri.parse('assets/10x10-red.png'),
          maxDuration: Duration(seconds: 1),
        );
        controller = ImagePlayerController(
          image,
          onMediumFinished: (context) => hasStopped = true,
          widgetKey: globalSuccessKey,
        );
        final widget = TestWidget(controller, startPlaying: false);

        await tester.pumpWidget(widget);
        expectLoading(tester, widget);
        expect(hasStopped, false);

        await tester.runAsync(() async => await undeadlockAsync()); // XXX!!!
        await tester.pumpAndSettle();
        final size = Size(10.0, 10.0);
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, false);

        // Wait for a few seconds, the media should haven't stopped (it
        // shouldn't have started playing to be precise)
        await tester.pump(image.maxDuration * 5);

        // Now start playing
        await controller.play(_FakeContext());
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, false);

        // Half the time passes, it should be still playing
        await tester.pump(image.maxDuration ~/ 2);
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, false);

        // Now we let the final half of the maxDuration pass and it should have
        // finished
        await tester.pump(image.maxDuration ~/ 2);
        expectSuccess(tester, widget, size: size, findWidget: Image);
        expect(find.byWidget(controller.image), findsOneWidget);
        expect(hasStopped, true);
      },
    );
  });
}

// XXX: This is an awful hack, for some reason this fixes a deadlock in the
//      pumpAndSettle() call. See this issue for details:
//      https://github.com/flutter/flutter/issues/64564
Future<void> undeadlockAsync() async {
  const kTransparentImage = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE
  ];
  final codec =
      await ui.instantiateImageCodec(Uint8List.fromList(kTransparentImage));
  await codec.getNextFrame();
  return;
}
