## dikt / bottom-up dictionary

Off-line dictionary with simplistic UI optimized for one-hand use on mobile phones (Android, Web), cross-platform (macOS, Windows, Linux) and working great on desktop as well:
- UI is inverted to be easily reachable by a thumb alone
  - The search bar is at the bottom
  - The lookup list starts at the bottom
  - Major controls (e.g. navigation) are the the bottom
  - On Android there's a lookup shortcut from text menu (long tap/selection of text)
- The app built to be fast with large dictionaries
  - It take 1.5 seconds to fully load 90 dictionaries with cumulative number of words at over 6 mil (in Galaxy S22)
  - It takes under 15 ms to do a lookup among 6 mil word
  - The lookup is case insensitive
- For smaller storage footprint the dictionaries are partly compressed providing ±30-40% of space savings
- Belarusian and RU speakers can benefit from the feature of substituting "и" for "і", "у" for "ў" and "e" for "ё" for faster typing without the need to change keyboard layout

## Dictionaries

The app comes preloaded with WordNet® 3 (large lexical dictionary of English). Other dictionaries can be imported from JSON files.

Dictionaries in various formats (DSL, StarDict, etc.) can be converted by PyGlossary free tool (available on GitHub) to JSON.

JSON files can be bulky to handle and slow to be added to the app. There's a binary format of dictionaries used internally (IKV or .dikt files), those ones can be generated via a command line tool: https://github.com/maxim-saplin/dikt_converter

## Get the app

- Android
  - Google Play: https://play.google.com/store/apps/details?id=com.saplin.dikt
  - Download APK:  [https://github.com/maxim-saplin/dikt/releases/download/2.3.2%2B35/dikt-android-2.3.2+36.apk](https://github.com/maxim-saplin/dikt/releases/download/2.3.1%2B35/dikt-android-2.3.2+36.apk)
- macOS (Universal app, Intel and Apple Silicon): (https://github.com/maxim-saplin/dikt/releases/download/2.3.2%2B35/dikt-macOS-2.3.2+36.zip)[https://github.com/maxim-saplin/dikt/releases/download/2.3.2%2B35/dikt-macOS-2.3.2+36.zip]
- Linux (x64): [https://github.com/maxim-saplin/dikt/releases/download/2.3.2%2B35/dikt-linux-x64-2.3.2+36.tar](https://github.com/maxim-saplin/dikt/releases/download/2.3.1%2B35/dikt-linux-x64-2.3.2+36.tar)
- Windows: [https://github.com/maxim-saplin/dikt/releases/download/2.3.2%2B35/dikt-windows-x64-2.3.2+36.zip](https://github.com/maxim-saplin/dikt/releases/download/2.3.1%2B35/dikt-windows-x64-2.3.2+36.zip)

[dikt.webm](https://user-images.githubusercontent.com/7947027/223116663-4db81908-a66f-4d6f-b91e-4cae2355f8d8.webm)
