# iOS port status

This document compares the main features described by the supplied ArchiveTune Android source with the native iOS rewrite in this folder. "Implemented" means the feature is present in this source tree; it does not mean it has been compiled and device-tested in Xcode in this environment.

## Implemented in this iOS source

| Area | iOS implementation |
|---|---|
| Native interface | SwiftUI tabs and native navigation, lists, menus, and sheets |
| Local music | Import and copy MP3, M4A, AAC, FLAC, WAV, AIFF, and CAF files; read common audio metadata and cover art |
| Playback | AVPlayer playback, queue, previous/next, shuffle, repeat, seek, and playback speed |
| Background controls | Playback audio session, Lock Screen / Control Center metadata and remote commands |
| Lyrics | Synced/plain LRCLIB lookup and timed lyric highlighting |
| Library | Local songs and playlists, create/rename/delete playlists, add tracks to playlists |
| Listening stats | Local play history, listening time, and most-played summary |
| Backup | Export and restore a JSON backup including the app's imported audio files |
| Appearance | Dark, light, and system theme selection |

## Partial or external handoff

| Original Android feature | Current iOS status |
|---|---|
| YouTube Music browse/search | Opens official YouTube Music in the browser; no native catalog or account sync |
| YouTube Music playback | Not implemented in the native player; protected media streams are not extracted |
| Multiple YT Music accounts | Not implemented |
| Lyrics providers | LRCLIB only; other Android providers and module-provided sources are not ported |
| Offline music | Local files work offline; no online-track caching or download service |
| Share/import from other apps | Local Files picker is implemented; app-wide URL/share ingestion is not wired yet |

## Not yet ported

- YouTube Music authentication, playlists, liked songs, subscriptions, recommendations, online playback, and account switching.
- SponsorBlock integration.
- Spotify playlist/liked-song import and Spotify account integration.
- Last.fm, Libre.fm, ListenBrainz, and custom scrobbling.
- Lyrics translation, AI translation, romanization, and non-LRCLIB lyric providers.
- Music recognition / ShazamKit.
- EBU R128 loudness normalization, crossfade, equalizer, independent pitch control, system EQ, spatial-audio integration, USB bit-perfect output, and third-party hi-res audio modules.
- CarPlay, Android Auto, Android widgets, Android notification customization, and the Android module runtime.
- Discord Rich Presence, animated artwork playback, and the original Android theme/player-style collection.

## Why it is not a one-to-one port

The supplied Android project contains hundreds of Kotlin files and relies on Android-specific services and libraries such as Jetpack Compose, Media3/ExoPlayer, Room, Android account/session flows, Android USB APIs, and Android Auto. The provided ZIP also references Git submodules for core and lyric-provider code. Those components cannot be linked into an iOS target. The app needs native Swift replacements and, for some online integrations, provider credentials or a backend.

The attached APK is an Android package and cannot be converted into a working iOS app. This project is a native source rewrite for the core local-music workflow, not a repackaged APK.
