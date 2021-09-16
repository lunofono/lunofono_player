import 'dart:io' show File, Directory;
import 'dart:typed_data' show ByteData, Uint8List;
import 'package:flutter/services.dart' show CachingAssetBundle;

/// An AssetBundle that gets assets synchronously for testing.
///
/// This class assumes an assets directory exists and has a valid
/// `AssetManifest.json` file and all other resources present in a final app
/// bundle. An easy way to get this is to just copy the `build/flutter_assets`
/// directory (or `build/unit_test_assets` directory) as a starting point and
/// adapt it to your testing needs.
class TestAssetBundle extends CachingAssetBundle {
  /// The directory where the assets should be looked for.
  final String assetsDirectory;

  /// Creates a new test bundle.
  ///
  /// If [assetsDirectory] is not provided or null, `test/asset_bundle` will be
  /// used by default, so assets will be looked for in `test/asset_bundle`. This
  /// directory should always be relative to the top-level directory of the
  /// project. `flutter test` will change the working directory to `test` but
  /// `flutter test file.dart` will not. This class accounts for this difference
  /// and makes the assets always load from the top-level directory of the
  /// project so you don't have to worry about it.
  TestAssetBundle([String? assetsDirectory])
      : assetsDirectory = assetsDirectory ?? 'test/asset_bundle';

  @override
  Future<ByteData> load(String key) {
    final cwd = Directory.current;
    // Makes up for `flutter test` vs `flutter run <file.dart>` differences, see
    // the constructor documentation for details.
    final dir = cwd.path.split('/').last == 'test' ? '..' : '.';
    final file = File('$dir/$assetsDirectory/$key');
    final fileContents = Uint8List.fromList(file.readAsBytesSync());
    return Future<ByteData>.value(ByteData.view(fileContents.buffer));
  }
}
