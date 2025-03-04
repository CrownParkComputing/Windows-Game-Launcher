# Windows Game Launcher

A modern, user-friendly game launcher for Windows that displays game artwork and provides a seamless gaming experience.

## Features

- Borderless window mode
- Game artwork display
- Easy game management
- Customizable game settings
- Clean, modern interface

## Installation

1. Download the latest release from the [Releases](https://github.com/CrownParkComputing/Windows-Game-Launcher/releases) page
2. Extract the ZIP file to your desired location
3. Run `game_launcher.exe`

## Required Folder Structure

When setting up games in the launcher, follow this folder structure:

```
Games/
├── Game1/
│   ├── artwork/
│   │   ├── background.jpg    (or .png)
│   │   └── cover.jpg        (or .png)
│   ├── game.exe
│   └── other game files...
├── Game2/
│   ├── artwork/
│   │   ├── background.jpg    (or .png)
│   │   └── cover.jpg        (or .png)
│   ├── game.exe
│   └── other game files...
```

### Important Notes:
- Each game must be in its own folder
- The `artwork` folder is required for each game and must contain:
  - `background.jpg` (or .png) - Used for the game's background image
  - `cover.jpg` (or .png) - Used for the game's cover art
- The game executable must be accessible within the game's folder

## Setting Up Games

1. Launch the application
2. Click the Settings icon in the top-right corner
3. Click "Add Game"
4. Browse to select the game's executable file
5. The launcher will automatically look for artwork in the `artwork` folder
6. If artwork is not found, you'll be prompted to add it manually

## Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)

## Recommended Image Sizes

- Background Image: 1920x1080 pixels (16:9 ratio)
- Cover Art: 600x900 pixels (2:3 ratio)

## Dependencies

The launcher requires the following to be installed on your system:

- Windows 10 or later
- DirectX 11 or later
- Visual C++ Redistributable 2015-2022

## Troubleshooting

### Missing Artwork
- Ensure your artwork files are named correctly (`background.jpg/png` and `cover.jpg/png`)
- Verify the `artwork` folder exists in the game's directory
- Check that image files are in a supported format (JPG or PNG)

### Game Won't Launch
- Verify the game executable path is correct
- Ensure all game dependencies are installed
- Check if the game requires administrator privileges

## Building from Source

### Prerequisites
- Flutter SDK 3.19.0 or later
- Windows 10 or later
- Visual Studio 2019 or later with Desktop development with C++
- Git

### Build Steps
1. Clone the repository
```bash
git clone https://github.com/CrownParkComputing/Windows-Game-Launcher.git
```

2. Install dependencies
```bash
flutter pub get
```

3. Build the application
```bash
flutter build windows --release
```

The built executable will be in `build/windows/x64/runner/Release/`

## Support

If you encounter any issues or need assistance:
1. Check the [Issues](https://github.com/CrownParkComputing/Windows-Game-Launcher/issues) page
2. Create a new issue if your problem isn't already reported

## License

This project is licensed under the MIT License - see the LICENSE file for details