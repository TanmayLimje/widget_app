# AanTan - Android Home Screen Widget App

A Flutter application that creates a customizable dual-user Android home screen widget for sharing status updates with images and captions.

## Features

- 🎨 **Dual User Support** - Two independent sections for different users
- 📸 **Image Updates** - Share photos via camera or gallery
- 🌈 **8 Color Themes** - Choose from Purple, Blue, Green, Orange, Pink, Red, Teal, or Yellow
- 📝 **Optional Captions** - Add text messages to your updates
- 📱 **Live Preview** - See widget appearance before adding to home screen
- 💾 **Persistent Storage** - Settings and images saved between app launches
- 👆 **Tap to Open** - Tap the widget to launch the app

## Widget Layout

```
┌─────────────────┬─────────────────┐
│     User 1      │     User 2      │
├─────────────────┼─────────────────┤
│                 │                 │
│  [UPDATE IMG]   │  [UPDATE IMG]   │
│                 │                 │
├─────────────────┼─────────────────┤
│   Caption...    │   Caption...    │
└─────────────────┴─────────────────┘
```

## Screenshots

The app displays a clean Material 3 interface with:
- Widget preview at the top showing how the home screen widget will look
- Two user configuration cards with:
  - Image picker (tap to add/change photo)
  - Caption input field (optional)
  - Color theme picker
- Update button to sync changes to the widget

## Getting Started

### Prerequisites

- Flutter SDK (3.10.4 or higher)
- Android Studio / VS Code
- Android device or emulator (API 21+)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Adding the Widget

1. Open the AanTan app
2. Add images for each user (tap the image area)
3. Optionally add captions
4. Choose background colors
5. Tap "Update Widget"
6. Long-press your Android home screen
7. Select "Widgets"
8. Find and drag "AanTan" (4×3 size) to your home screen

## Project Structure

```
widget_app/
├── lib/
│   └── main.dart                    # Flutter app with dual user UI
├── android/
│   └── app/src/main/
│       ├── kotlin/.../
│       │   ├── MainActivity.kt
│       │   └── AanTanWidgetProvider.kt
│       ├── res/
│       │   ├── layout/
│       │   │   └── aantan_widget.xml
│       │   ├── drawable/
│       │   │   ├── widget_background_user1.xml
│       │   │   ├── widget_background_user2.xml
│       │   │   ├── image_placeholder.xml
│       │   │   ├── circle_background.xml
│       │   │   └── default_avatar.xml
│       │   ├── xml/
│       │   │   └── aantan_widget_info.xml
│       │   └── values/
│       │       └── strings.xml
│       └── AndroidManifest.xml
└── docs/
    ├── README.md              # This file
    ├── ARCHITECTURE.md        # Technical architecture
    └── CHANGELOG.md           # Version history
```

## Dependencies

- `home_widget: ^0.7.0` - Flutter-to-native widget communication
- `image_picker: ^1.0.7` - Camera and gallery access
- `path_provider: ^2.1.2` - Local file storage

## License

This project is for educational purposes.
