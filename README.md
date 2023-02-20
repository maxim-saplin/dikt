## dikt / bottom-up dictionary

Off-line dictionary with simplistic UI optimized for one-hand use with mobiles, cross-platform and working great on desktop as well:
- UI is inverted to be easily reachable by a thumb alone
 - The search bar is at the bottom
 - The lookup list starts at the bottom
 - Major controls (e.g. navigation) are the the bottom
- The app built to be fast with large dictionaries
 - It take 1.5 seconds to fully load 90 dictionaries with cummulative nubmer of words at over 6 mil (in Galaxy S22)
 - It takes under 15 ms to do a lookup among 6 mil word
 - The lookup is case insensitive
- For smaller storage footprint the dictionaries are partly compressed providing ±30-40% of space savings
- Bonus for Belarusian and RU speakers, teh app can substitue "и" for "і", "у" for "ў" and "e" for "ё" for faster typing withoud the need to change keyboard layout

## Dictionaries

The app comes preloaded with WordNet® 3 (large lexical dictionary of English). Other dictionaries can be imported from JSON files.

Dictionaries in various formats (DSL, StarDict, etc.) can be converted by PyGlossary free tool (available on GitHub) to JSON.

JSON files can be bulky to handle and slow to be added to the app. There's a binary format of ditionaries used internally (IKV or .dikt files), those ones can be generated via a command line tool: https://github.com/maxim-saplin/dikt_converter

## Try/Download

<p float="left">
   <a href="https://maxim-saplin.github.io/dikt/" target="_blank">
      <img src="https://raw.githubusercontent.com/maxim-saplin/dikt/master/_misc/web.svg" height="80"/>
   </a>
   <a href="https://play.google.com/store/apps/details?id=com.saplin.dikt" target="_blank">
      <img src="https://raw.githubusercontent.com/maxim-saplin/dikt/master/_misc/gplay.svg" height="80"/>
   </a>
   <a href="https://github.com/maxim-saplin/dikt/releases/download/1.1.0/dikt.apk" target="_blank">
      <img src="https://raw.githubusercontent.com/maxim-saplin/dikt/master/_misc/apk.svg" height="80"/>
   </a>
   <a href="https://github.com/maxim-saplin/dikt/releases/download/1.1.0/dikt.app.zip" target="_blank">
      <img src="https://raw.githubusercontent.com/maxim-saplin/dikt/master/_misc/macos.svg" height="80"/>
   </a>
   <a href="https://github.com/maxim-saplin/dikt/releases/download/1.1.0/dikt-win-x64.zip" target="_blank">
      <img src="https://raw.githubusercontent.com/maxim-saplin/dikt/master/_misc/windows.svg" height="80"/>
   </a>
 </p>

<br/>

<img align="left" src="https://raw.githubusercontent.com/maxim-saplin/dikt/master/_misc/1.gif" width="360"/>
<img align="left" src="https://raw.githubusercontent.com/maxim-saplin/dikt/master/_misc/2.gif" width="360"/>
