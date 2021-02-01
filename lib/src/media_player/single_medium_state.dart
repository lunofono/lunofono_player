import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:lunofono_bundle/lunofono_bundle.dart' show SingleMedium;

import 'controller_registry.dart' show ControllerRegistry;
import 'single_medium_controller.dart' show SingleMediumController, Size;
import 'single_medium_widget.dart' show SingleMediumWidget;

/// A state of a [SingleMediumWidget].
///
/// The medium can have 3 states:
/// 1. Uninitialized, represented by [error] and [size] being null.
/// 2. Successfully initialized: represented by [size] being non-null.
/// 3. Erroneous: represented by [error] being non-null. The error can occur
///    while constructing the controller, [initialize()]ing, [play()]ing,
///    [pause()]ing, etc. Having both [error] and [size] non-null can happen if
///    the error happens after initialization is successful.
class SingleMediumState with ChangeNotifier, DiagnosticableTreeMixin {
  /// The medium this state tracks.
  final SingleMedium medium;

  /// The player controller used to control this medium.
  ///
  /// It can be null if there was an error while creating the controller (if
  /// it is null, error is non-null).
  SingleMediumController get controller => _controller;
  SingleMediumController _controller;

  /// If true, the medium needs to be visualized, otherwise it plays in the
  /// background without any visual representation (except for errors or
  /// progress).
  final bool isVisualizable;

  /// The last error that happened while using this medium.
  ///
  /// It can be null, meaning there was no error so far.
  dynamic error;

  /// The size of this medium.
  ///
  /// The size is only available after [initialize()] is successful, so if this
  /// is non-null, it means the [controller] for this medium was initialized
  /// successfully.
  Size size;

  /// True if there was an error ([error] is non-null).
  bool get isErroneous => error != null;

  /// True if it was successfully initialized ([size] != null).
  ///
  /// Even if it is initialized successfully, there could be an error after
  /// that, so [isErroneous] should be always checked first before assuming this
  /// medium is in a good state.
  bool get isInitialized => size != null;

  /// Creates a state from a [medium].
  ///
  /// The [medium] and [isVisualizable] must be non-null. A [controller] will
  /// be created using the global [ControllerRegistry.instance]. If there is no
  /// controller registered for this kind of [medium], then an [error] will
  /// be set.
  ///
  /// If [onMediumFinished] is provided, it will be called when the medium
  /// finishes playing (if ever).
  SingleMediumState(
    this.medium, {
    this.isVisualizable = true,
    void Function(BuildContext context) onMediumFinished,
  })  : assert(medium != null),
        assert(isVisualizable != null) {
    final create = ControllerRegistry.instance.getFunction(medium);
    if (create == null) {
      error = 'Unsupported type ${medium.runtimeType} for ${medium.resource}';
      return;
    }
    _controller = create(medium, onMediumFinished: onMediumFinished);
  }

  /// Initializes this medium's [controller].
  ///
  /// Sets [size] on success, and [error] on error. Should be called only once
  /// and before invoking any other method of this class.
  ///
  /// If [startPlaying] is true, then [play()] will be called after the
  /// initialization is done.
  ///
  /// If the underlaying controller couldn't be created, then this
  /// method does nothing.
  Future<void> initialize(BuildContext context,
      {bool startPlaying = false}) async {
    assert(size == null);
    // error should be already set
    if (controller == null) return;
    try {
      size = await controller.initialize(context);
    } catch (e) {
      error = e;
    }
    notifyListeners();
    if (startPlaying) await play(context);
  }

  /// Plays this medium using [controller].
  ///
  /// Sets [error] on error.
  // FIXME: For now we show the error forever, eventually we probably have to
  // show the error only for some time and then move to the next medium in the
  // track.
  Future<void> play(BuildContext context) =>
      controller?.play(context)?.catchError((dynamic error) {
        this.error = error;
        notifyListeners();
      });

  /// Pauses this medium using [controller].
  ///
  /// Sets [error] on error.
  // FIXME: For now we ignore pause() when isErroneous, eventually we probably
  // have to show the error only for some time and then move to the next medium
  // in the track.
  Future<void> pause(BuildContext context) =>
      controller?.pause(context)?.catchError((dynamic error) {
        this.error = error;
        notifyListeners();
      });

  /// Disposes this medium's [controller].
  ///
  /// Sets [error] on error. This state can't be used anymore after this method
  /// is called, except for checking for [error].
  @override
  Future<void> dispose() async {
    await controller
        ?.dispose()
        ?.catchError((dynamic error) => this.error = error);
    super.dispose();
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final sizeStr =
        size == null ? 'uninitialized' : '${size.width}x${size.height}';
    final errorStr = error == null ? '' : 'error: $error';
    return '$runtimeType($sizeStr$errorStr)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('medium', medium))
      ..add(DiagnosticsProperty<dynamic>('error', error, defaultValue: null))
      ..add(DiagnosticsProperty('size',
          size == null ? '<uninitialized>' : '${size.width}x${size.height}'));
  }
}
