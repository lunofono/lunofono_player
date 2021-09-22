import 'package:mockito/annotations.dart' show GenerateMocks;

import 'package:lunofono_bundle/lunofono_bundle.dart'
    show Playlist, SingleMedium;

import 'package:lunofono_player/src/media_player/multi_medium_state.dart'
    show MultiMediumState;
import 'package:lunofono_player/src/media_player/playable_state.dart'
    show PlayableState;
import 'package:lunofono_player/src/media_player/playlist_state.dart'
    show PlaylistState;
import 'package:lunofono_player/src/media_player/single_medium_controller.dart'
    show SingleMediumController;
import 'package:lunofono_player/src/media_player/single_medium_state.dart'
    show SingleMediumState;

@GenerateMocks([
  MultiMediumState,
  PlayableState,
  Playlist,
  PlaylistState,
  SingleMedium,
  SingleMediumController,
  SingleMediumState,
])
void dummy() {}
