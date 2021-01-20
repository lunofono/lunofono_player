@Tags(['unit', 'player'])

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' show Fake;

import 'package:lunofono_bundle/lunofono_bundle.dart';
import 'package:lunofono_player/src/media_player/single_medium_controller.dart'
    show SingleMediumController, Size;

import 'package:lunofono_player/src/media_player/multi_medium_state.dart'
    show SingleMediumState, SingleMediumStateFactory;

void main() {
  void verifyStateInvariants(
      SingleMediumState state, _FakeSingleMediumController controller) {
    expect(state.controller, same(controller));
    expect(state.widgetKey, controller.widgetKey);
  }

  void verifyStateInitialization(
      SingleMediumState state, _FakeSingleMediumController controller) {
    verifyStateInvariants(state, controller);
    expect(state.error, isNull);
    expect(state.isErroneous, isFalse);
    expect(state.size, isNull);
    expect(state.isInitialized, isFalse);
    expect(controller.calls, isEmpty);
  }

  void verifyStateError(
      SingleMediumState state, _FakeSingleMediumController controller) {
    verifyStateInvariants(state, controller);
    expect(state.size, isNull);
    expect(state.isInitialized, isFalse);
    expect(state.error, controller.medium.info.exception);
    expect(state.isErroneous, isTrue);
  }

  group('SingleMediumState', () {
    test('.erroneous() initializes with error', () async {
      final medium = _FakeSingleMedium('medium', size: Size(0.0, 0.0));

      expect(() => SingleMediumState.erroneous(null, 'Error'),
          throwsAssertionError);

      expect(() => SingleMediumState.erroneous(medium, null),
          throwsAssertionError);

      final state = SingleMediumState.erroneous(medium, 'Error 123');
      expect(state.controller, isNull);
      expect(state.widgetKey, isNull);
      expect(state.error, 'Error 123');
      expect(state.isErroneous, isTrue);
      expect(state.size, isNull);
      expect(state.isInitialized, isFalse);
    });

    group('on bad medium', () {
      Exception error;
      _FakeSingleMedium medium;
      _FakeSingleMediumController controller;
      SingleMediumState state;

      setUp(() {
        error = Exception('Initialization Error');
        medium = _FakeSingleMedium('bad-medium', exception: error);
        controller = _FakeSingleMediumController(medium);
        state = SingleMediumState(controller);
      });

      test('the state is properly initialized', () {
        verifyStateInitialization(state, controller);
      });

      test('.initialize() fills error', () async {
        await state.initialize(_FakeContext());
        verifyStateError(state, controller);
      });

      test('.play() fills error', () async {
        await state.play(_FakeContext());
        verifyStateError(state, controller);
      });

      test('.pause() fills error', () async {
        await state.pause(_FakeContext());
        verifyStateError(state, controller);
      });

      test('.dispose() fills error', () async {
        await state.dispose();
        verifyStateError(state, controller);
      });

      test('toString()', () async {
        expect(state.toString(), 'SingleMediumState(uninitialized)');
        await state.initialize(_FakeContext());
        expect(
            state.toString(),
            'SingleMediumState(uninitializederror: '
            'Exception: Initialization Error)');
      });

      test('debugFillProperties() and debugDescribeChildren()', () async {
        final identityHash = RegExp(r'#[0-9a-f]{5}');

        expect(
            state.toStringDeep().replaceAll(identityHash, ''),
            'SingleMediumState\n'
            '   medium: _FakeSingleMedium(resource: bad-medium, maxDuration:\n'
            '     8760:00:00.000000)\n'
            '   size: <uninitialized>\n'
            '');
        await state.initialize(_FakeContext());
        expect(
            state.toStringDeep().replaceAll(identityHash, ''),
            'SingleMediumState\n'
            '   medium: _FakeSingleMedium(resource: bad-medium, maxDuration:\n'
            '     8760:00:00.000000)\n'
            '   error: Exception: Initialization Error\n'
            '   size: <uninitialized>\n'
            '');
      });
    });

    group('on good medium', () {
      Size size;
      _FakeSingleMedium medium;
      _FakeSingleMediumController controller;
      SingleMediumState state;

      setUp(() {
        size = Size(0.0, 0.0);
        medium = _FakeSingleMedium('good-medium', size: size);
        controller = _FakeSingleMediumController(medium);
        state = SingleMediumState(controller);
      });

      void verifyStateInitialized() {
        verifyStateInvariants(state, controller);
        expect(state.size, size);
        expect(state.isInitialized, isTrue);
        expect(state.error, isNull);
        expect(state.isErroneous, isFalse);
      }

      test('constructor asserts on null controller', () {
        expect(() => SingleMediumState(null), throwsAssertionError);
      });

      test('the state is properly initialized', () {
        verifyStateInitialization(state, controller);
      });

      test('.initialize() gets the size', () async {
        await state.initialize(_FakeContext());
        verifyStateInitialized();
      });

      test('.initialize() sets error with assertion', () async {
        await state.initialize(_FakeContext());
        expect(() async => await state.initialize(_FakeContext()),
            throwsAssertionError);
      });

      test('.play() runs without error', () async {
        await state.play(_FakeContext());
        expect(state.error, isNull);
        expect(state.isErroneous, isFalse);
      });

      test('.pause() runs without error', () async {
        await state.pause(_FakeContext());
        expect(state.error, isNull);
        expect(state.isErroneous, isFalse);
      });

      test('.dispose() runs without error', () async {
        await state.dispose();
        expect(state.error, isNull);
        expect(state.isErroneous, isFalse);
      });

      test('.build() builds a widget with the expected key', () {
        final widget = state.build(_FakeContext());
        expect(widget.key, state.widgetKey);
      });

      test('toString()', () async {
        expect(state.toString(), 'SingleMediumState(uninitialized)');
        await state.initialize(_FakeContext());
        expect(state.toString(), 'SingleMediumState(0.0x0.0)');
      });

      test('debugFillProperties() and debugDescribeChildren()', () async {
        final identityHash = RegExp(r'#[0-9a-f]{5}');

        expect(
            state.toStringDeep().replaceAll(identityHash, ''),
            'SingleMediumState\n'
            '   medium: _FakeSingleMedium(resource: good-medium, maxDuration:\n'
            '     8760:00:00.000000)\n'
            '   size: <uninitialized>\n'
            '');
        await state.initialize(_FakeContext());
        expect(
            state.toStringDeep().replaceAll(identityHash, ''),
            'SingleMediumState\n'
            '   medium: _FakeSingleMedium(resource: good-medium, maxDuration:\n'
            '     8760:00:00.000000)\n'
            '   size: 0.0x0.0\n'
            '');
      });
    });
  });

  group('SingleMediumStateFactory', () {
    test('.good()', () {
      final medium = _FakeSingleMedium('bad-medium', size: Size(1.0, 1.0));
      final controller = _FakeSingleMediumController(medium);
      final state = SingleMediumStateFactory().good(controller);
      verifyStateInitialization(state, controller);
    });

    test('.bad()', () {
      final state = SingleMediumStateFactory()
          .bad(_FakeSingleMedium('error', size: Size(1.0, 1.0)), 'Error 123');
      expect(state.controller, isNull);
      expect(state.widgetKey, isNull);
      expect(state.error, 'Error 123');
      expect(state.isErroneous, isTrue);
      expect(state.size, isNull);
      expect(state.isInitialized, isFalse);
    });
  });
}

class _FakeContext extends Fake implements BuildContext {}

class _SingleMediumInfo {
  final Size size;
  final Exception exception;
  final Key widgetKey;
  _SingleMediumInfo(
    String location, {
    this.size,
    this.exception,
  })  : assert(location != null),
        assert(exception != null && size == null ||
            exception == null && size != null),
        widgetKey = GlobalKey(debugLabel: 'widgetKey(${location}');
}

class _FakeSingleMedium extends SingleMedium {
  final _SingleMediumInfo info;
  _FakeSingleMedium(
    String location, {
    Size size,
    Exception exception,
  })  : info = _SingleMediumInfo(location, size: size, exception: exception),
        super(Uri.parse(location));
}

class _FakeSingleMediumController extends Fake
    implements SingleMediumController {
  @override
  _FakeSingleMedium medium;

  @override
  Key widgetKey;

  @override
  void Function(BuildContext context) onMediumFinished;

  final calls = <String>[];

  _FakeSingleMediumController(
    this.medium, {
    Key widgetKey,
    this.onMediumFinished,
  })  : assert(medium != null),
        widgetKey = widgetKey ?? GlobalKey(debugLabel: 'mediumKey');

  Future<T> _errorOr<T>(String name, [T value]) {
    calls.add(name);
    return medium.info.exception != null
        ? Future.error(medium.info.exception)
        : Future<T>.value(value);
  }

  @override
  Future<Size> initialize(BuildContext context) =>
      _errorOr('initialize', medium.info.size);

  @override
  Future<void> play(BuildContext context) => _errorOr<void>('play');

  @override
  Future<void> pause(BuildContext context) => _errorOr<void>('pause');

  @override
  Future<void> dispose() => _errorOr<void>('dispose');

  @override
  Widget build(BuildContext context) {
    calls.add('build');
    return Container(key: widgetKey);
  }
}

// vim: set foldmethod=syntax foldminlines=3 :
