import 'package:flutter/material.dart' show Text;

import 'package:flutter_test/flutter_test.dart' show find, Finder;

/// Finds a [Text] widget whose content contains the [substring].
Finder findSubString(String? substring) {
  return find.byWidgetPredicate((widget) {
    if (widget is Text) {
      if (widget.data != null) {
        return widget.data!.contains(substring!);
      }
      return widget.textSpan!.toPlainText().contains(substring!);
    }
    return false;
  });
}
