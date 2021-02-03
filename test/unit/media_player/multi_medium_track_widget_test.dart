@Tags(['unit', 'player'])

import 'package:flutter/foundation.dart' show DiagnosticableTreeMixin;
import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:provider/provider.dart' show ChangeNotifierProvider, Provider;

import 'package:lunofono_player/src/media_player/multi_medium_track_widget.dart'
    show MultiMediumTrackWidget;
import 'package:lunofono_player/src/media_player/multi_medium_track_state.dart'
    show MultiMediumTrackState;
import 'package:lunofono_player/src/media_player/single_medium_widget.dart'
    show SingleMediumWidget;
import 'package:lunofono_player/src/media_player/single_medium_state.dart'
    show SingleMediumState;

void main() {
  group('MultiMediumTrackWidget', () {
    testWidgets('createTrackWidget() returns a MultiMediumTrackWidget',
        (WidgetTester tester) async {
      final player = _TestMultiMediumTrackWidget();
      expect(player.createSingleMediumWidgetFromSuper(),
          isA<SingleMediumWidget>());
    });

    group('passes SingleMediumState for ', () {
      void testPassedState(String name, _FakeMultiMediumTrackState trackState,
              _FakeSingleMediumState expectedSingleMediumState) =>
          testWidgets(name, (WidgetTester tester) async {
            await tester.pumpWidget(
              Directionality(
                textDirection: TextDirection.ltr,
                child: ChangeNotifierProvider<MultiMediumTrackState>.value(
                  value: trackState,
                  child: _TestMultiMediumTrackWidget(),
                ),
              ),
            );

            final playerFinder = find.byType(_FakeSingleMediumWidget);
            expect(playerFinder, findsOneWidget);
            final playerContext = tester.element(playerFinder);
            final playerState = Provider.of<SingleMediumState>(
              playerContext,
              listen: false,
            );

            expect(playerState, same(expectedSingleMediumState));
          });

      final currentState = _FakeSingleMediumState();
      final lastState = _FakeSingleMediumState();

      testPassedState(
        'current if it is non-null',
        _FakeMultiMediumTrackState(
          current: currentState,
          last: lastState,
        ),
        currentState,
      );

      testPassedState(
        'last if current is null',
        _FakeMultiMediumTrackState(last: lastState),
        lastState,
      );
    });
  });
}

class _FakeSingleMediumState extends Fake
    with DiagnosticableTreeMixin, ChangeNotifier
    implements SingleMediumState {
  @override
  Future<void> dispose() async => super.dispose();
}

class _TestMultiMediumTrackWidget extends MultiMediumTrackWidget {
  Widget createSingleMediumWidgetFromSuper() =>
      super.createSingleMediumWidget();
  @override
  Widget createSingleMediumWidget() => _FakeSingleMediumWidget();
}

class _FakeSingleMediumWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}

class _FakeMultiMediumTrackState extends Fake
    with DiagnosticableTreeMixin, ChangeNotifier
    implements MultiMediumTrackState {
  @override
  _FakeSingleMediumState current;
  @override
  _FakeSingleMediumState last;
  @override
  Future<void> dispose() async => super.dispose();
  _FakeMultiMediumTrackState({
    this.current,
    _FakeSingleMediumState last,
  }) : last = last ?? current;
}
