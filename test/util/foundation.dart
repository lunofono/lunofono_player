import 'package:flutter/foundation.dart' show DiagnosticLevel;

abstract class FakeDiagnosticableMixin {
  String toStringFakeImpl() => 'Unimplemented toStringImpl()';
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) =>
      toStringFakeImpl();
}
