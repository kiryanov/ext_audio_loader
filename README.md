### Description
VLC extension for autoload external audio tracks and subtitles. Audio tracks and subtitles must have the same name prefix as the video:
* show_01.mkv
* Your Dub\show_01_Dub.mka
* Subs\Signs\show_01_Sub.ass

This version is modified from the original, adding support for multiple files of both kinds.

### Usage
* Enable "EASL" in "View" menu.
* Play video file.

### Installation:
Copy the .lua file into appropriate lua extensions folder (Create directory if it does not exist!):
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\extensions
* Windows (current user): %APPDATA%\VLC\lua\extensions
* Linux (all users): /usr/lib/vlc/lua/extensions/
* Linux (current user): ~/.local/share/vlc/lua/extensions/
