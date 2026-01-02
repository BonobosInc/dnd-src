# BonoDND

A comprehensive D&D (Dungeons & Dragons) companion application built with Flutter. This multi-platform app helps manage characters, campaigns, spells, weapons, and more for your tabletop gaming sessions.

## Features

- **Character Management**: Create and manage D&D characters with detailed profiles
- **Wiki Integration**: Built-in wiki parser for D&D content and reference materials
- **Spell Management**: Browse, search, and manage spells with a dedicated spell editing view
- **Inventory System**: Track character equipment, weapons, and items
- **Session Tracking**: Manage game sessions and campaign notes
- **Cross-Platform**: Supports Android, iOS, Windows, Linux, macOS, and Web
- **Localization**: Multi-language support (including German)
- **Dark/Light Mode**: Theme switching with persistent preferences
- **Auto-Updates**: Automatic update checking and installation
- **PDF Export**: Generate and share character sheets in PDF format

## Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Windows (MSIX package available)
- ✅ Linux
- ✅ macOS
- ✅ Web

## Getting Started

### Prerequisites

- Flutter SDK ^3.38.3
- For desktop platforms: Platform-specific build tools
- For Android: Android Studio and SDK
- For iOS/macOS: Xcode

### Installation

1. Clone the repository:
```bash
git clone https://github.com/BonobosInc/dnd-src.git
cd dnd
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For desktop
flutter run -d windows
flutter run -d linux
flutter run -d macos

# For mobile
flutter run -d android
flutter run -d ios

# For web
flutter run -d chrome
```

### Building for Production

#### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### Windows
```bash
flutter build windows --release
# or create MSIX package
flutter pub run msix:create
```

#### iOS
```bash
flutter build ios --release
```

#### Linux
```bash
flutter build linux --release
```

#### Web
```bash
flutter build web --release
```

## Project Structure

```
lib/
├── main.dart                 # Application entry point
├── classes/                  # Core data models and business logic
│   ├── profile_manager.dart
│   └── wiki_parser.dart
├── configs/                  # Configuration files
│   ├── colours.dart
│   └── auto_updater.dart
├── views/                    # UI screens and views
│   ├── character/           # Character-related views
│   ├── session/             # Session management
│   ├── wiki/                # Wiki browser
│   ├── spell_view.dart
│   ├── weapon_view.dart
│   └── settings_view.dart
└── l10n/                    # Localization files
```

## Key Dependencies

- **sqflite**: Local database management
- **file_picker**: File selection and import
- **xml**: XML parsing for wiki content
- **shared_preferences**: Persistent app settings
- **syncfusion_flutter_pdf**: PDF generation
- **share_plus**: Content sharing functionality
- **image_picker**: Character image management
- **material_design_icons_flutter**: Extended icon set

## Configuration

### App Icons
The app uses `flutter_launcher_icons` for icon generation. Update `flutter_launcher_icons.yaml` to customize app icons.

### Localization
The app supports multiple languages. Translation files are located in `lib/l10n/`. To add a new language, create a new ARB file and rebuild.

## Database

The app uses SQLite for local data storage, managing:
- Character profiles
- Campaign data
- Custom spells and items
- Session notes

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

See the [LICENSE](LICENSE) file for details.

## Version

Current version: 2.0.0

## Acknowledgments

Built with Flutter and the amazing Flutter community packages.
