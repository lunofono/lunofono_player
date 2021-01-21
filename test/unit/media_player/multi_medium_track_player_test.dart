@Tags(['unit', 'player'])

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:provider/provider.dart' show ChangeNotifierProvider, Provider;

import 'package:lunofono_player/src/media_player/multi_medium_track_player.dart'
    show MultiMediumTrackPlayer;
import 'package:lunofono_player/src/media_player/multi_medium_track_state.dart'
    show MultiMediumTrackState;
import 'package:lunofono_player/src/media_player/single_medium_player.dart'
    show SingleMediumPlayer;
import 'package:lunofono_player/src/media_player/single_medium_state.dart'
    show SingleMediumState;

import '../../util/foundation.dart' show FakeDiagnosticableMixin;

void main() {
  group('MultiMediumTrackPlayer', () {
    testWidgets('createTrackPlayer() returns a MultiMediumTrackPlayer',
        (WidgetTester tester) async {
      final player = _TestMultiMediumTrackPlayer();
      expect(player.createSingleMediumPlayerFromSuper(),
          isA<SingleMediumPlayer>());
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
                  child: _TestMultiMediumTrackPlayer(),
                ),
              ),
            );

            final playerFinder = find.byType(_FakeSingleMediumPlayer);
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
    with FakeDiagnosticableMixin, ChangeNotifier
    implements SingleMediumState {
  @override
  Future<void> dispose() async => super.dispose();
}

class _TestMultiMediumTrackPlayer extends MultiMediumTrackPlayer {
  Widget createSingleMediumPlayerFromSuper() =>
      super.createSingleMediumPlayer();
  @override
  Widget createSingleMediumPlayer() => _FakeSingleMediumPlayer();
}

class _FakeSingleMediumPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}

class _FakeMultiMediumTrackState extends Fake
    with FakeDiagnosticableMixin, ChangeNotifier
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
