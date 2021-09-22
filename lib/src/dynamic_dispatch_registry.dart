/// A registry to enabled dynamic dispatch based on [Type.runtimeType].
///
/// This registry serves as a way to have dynamic dispatch to call functions
/// based on the concrete type of objects with a base class [B]. Types can be
/// registered with an assigned function of type [T] and then the specific
/// function can be obtained via [getFunction()].
class DynamicDispatchRegistry<B, T extends Function> {
  /// The map from a concrete [Type] to a [T] function.
  final _registry = <Type, T>{};

  /// Constructs and empty registry.
  DynamicDispatchRegistry();

  /// True if the registry has no registered functions.
  bool get isEmpty => _registry.isEmpty;

  /// Registers a [function] for [type].
  ///
  /// If [type] was already registered, it is replaced and the old registered
  /// [fucntion] is returned. Otherwise it returns null.
  T? register(Type type, T function) {
    final old = _registry[type];
    _registry[type] = function;
    return old;
  }

  /// Removes the [T] function registered for [type].
  ///
  /// Returns the registered [T] function for [type] or null if there was no
  /// function registered.
  T? unregister(Type type) {
    return _registry.remove(type);
  }

  /// Gets the registered function [T] for [instance.runtimeType].
  ///
  /// If there is no registered function, then null is returned.
  T? getFunction(B instance) => _registry[instance.runtimeType];

  @override
  String toString() {
    return 'DynamicDispatchRegistry<$B, $T>($_registry)';
  }
}
