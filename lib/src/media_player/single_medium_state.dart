import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext, Widget;

import 'package:lunofono_bundle/lunofono_bundle.dart' show SingleMedium;

import 'single_medium_controller.dart' show SingleMediumController, Size;

/// Factory to construct [SingleMediumState].
///
/// This is used only for testing.
class SingleMediumStateFactory {
  const SingleMediumStateFactory();
  SingleMediumState good(SingleMediumController controller,
          {bool isVisualizable = true}) =>
      SingleMediumState(controller, isVisualizable: isVisualizable);
  SingleMediumState bad(SingleMedium medium, dynamic error) =>
      SingleMediumState.erroneous(medium, error);
}

/// A state of a [SingleMediumPlayer].
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
  final SingleMediumController controller;

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

  /// The Key used by the widget produced by this [controller].
  Key get widgetKey => controller?.widgetKey;

  /// Constructs a new state using a [controller].
  ///
  /// The [controller] must be non-null, [medium] will be set to
  /// [controller.medium]. [isVisualizable] must be non-null too.
  SingleMediumState(this.controller, {this.isVisualizable = true})
      : assert(controller != null),
        assert(isVisualizable != null),
        medium = controller.medium;

  /// Constructs a new erroneous state.
  ///
  /// This is typically used when a [controller] couldn't be created. The
  /// [medium] and [error] must be non-null and [controller] will be set to
  /// null.
  SingleMediumState.erroneous(this.medium, this.error)
      : assert(medium != null),
        assert(error != null),
        controller = null,
        isVisualizable = true;

  /// Initializes this medium's [controller].
  ///
  /// Sets [size] on success, and [error] on error. Should be called only once
  /// and before invoking any other method of this class.
  Future<void> initialize(BuildContext context) {
    assert(size == null);
    return controller.initialize(context).then<void>((size) {
      this.size = size;
      notifyListeners();
    }).catchError((dynamic error) {
      this.error = error;
      notifyListeners();
    });
  }

  /// Plays this medium using [controller].
  ///
  /// Sets [error] on error.
  // FIXME: For now we show the error forever, eventually we probably have to
  // show the error only for some time and then move to the next medium in the
  // track.
  Future<void> play(BuildContext context) => controller
          ?.play(context)
          ?.then<void>((_) => notifyListeners())
          ?.catchError((dynamic error) {
        this.error = error;
        notifyListeners();
      });

  /// Pauses this medium using [controller].
  ///
  /// Sets [error] on error.
  // FIXME: For now we ignore pause() when isErroneous, eventually we probably
  // have to show the error only for some time and then move to the next medium
  // in the track.
  Future<void> pause(BuildContext context) => controller
          ?.pause(context)
          ?.then<void>((_) => notifyListeners())
          ?.catchError((dynamic error) {
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

  /// Builds the widget to display this controller.
  Widget build(BuildContext context) => controller.build(context);

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
