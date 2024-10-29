# MPV Auto-Subtitle Loader Addon

The **MPV Auto-Subtitle Loader** addon is designed to automatically load matching subtitle files when a video is played in [MPV media player](https://mpv.io). This can save time and effort, especially when dealing with multiple subtitle files in a directory or when subtitle names differ slightly from the video file name.

## Features

- **Automatic Subtitle Loading**: Searches for subtitle files in the same directory as the video and loads those that best match the video file name.
- **Flexible Matching**: Uses customizable similarity checks to find subtitles with names close to the video file name.
- **Load All Subtitles**: If no subtitles closely match the video name, the addon can load all subtitle files in the directory.
- **Customizable Logging**: Includes detailed logs for different levels (info, debug, verbose) to help track the matching process and troubleshoot issues.


## Installation

1. **Move to MPV Scripts Folder**: Copy the script file to your MPV `scripts` directory:
    - On Linux/Mac: `~/.config/mpv/scripts/`
    - On Windows: `%APPDATA%\mpv\scripts\`

## License

This script is open-source and can be modified and redistributed freely. Contributions are welcome!
