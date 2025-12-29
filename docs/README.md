# AanTan - Android Home Screen Widget App

A Flutter application that creates a customizable dual-user Android home screen widget for sharing status updates with images and captions between Tanmay and Aanchal.

## Features

- 🔐 **User Login** - Login as Tanmay or Aanchal with dedicated screens
- 🎨 **Dual User Support** - Two independent sections for Tanmay and Aanchal
- 📸 **Image Updates** - Share photos via camera, gallery, or draw doodles
- 🎨 **Drawing Canvas** - Create and share hand-drawn doodles
- 🌈 **8 Color Themes** - Choose from Purple, Blue, Green, Orange, Pink, Red, Teal, or Yellow
- 📝 **Optional Captions** - Add text messages to your updates
- 📱 **Live Preview** - See widget appearance before adding to home screen
- 💾 **Persistent Storage** - Settings and images saved between app launches
- 👆 **Tap to Open** - Tap the widget to launch the app
- 📜 **Update History** - View past updates from both users
- 🌙 **Theme Mode** - Switch between Light, Dark, and System themes

## Widget Layout

```
┌─────────────────┬─────────────────┐
│     Tanmay      │     Aanchal     │
├─────────────────┼─────────────────┤
│                 │                 │
│  [UPDATE IMG]   │  [UPDATE IMG]   │
│                 │                 │
├─────────────────┼─────────────────┤
│   Caption...    │   Caption...    │
└─────────────────┴─────────────────┘
```

## App Flow

1. **Login Screen** - Choose to login as Tanmay or Aanchal
2. **User Home** - Personalized screen showing:
   - Widget preview (both users' content)
   - Your own update card (photo/draw/text)
   - Save & Update Widget button
   - View Past Updates button
   - Theme switcher
   - Logout to switch users

## Screenshots

The app displays a clean Material 3 interface with:
- Login page with two user buttons
- User-specific home screen with:
  - Widget preview at the top
  - Single user configuration card with image picker and caption
  - Color theme picker
  - Update and history buttons
  - Theme mode toggle

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
2. Login as Tanmay or Aanchal
3. Add an image (camera, gallery, or draw)
4. Optionally add a caption
5. Choose a background color
6. Tap "Save & Update Widget"
7. Long-press your Android home screen
8. Select "Widgets"
9. Find and drag "AanTan" (4×3 size) to your home screen

## Project Structure

```
widget_app/
├── lib/
│   ├── main.dart                    # App entry, theme, routes
│   ├── login_page.dart              # User login screen
│   ├── user_home_page.dart          # User-specific home page
│   ├── past_updates_page.dart       # Update history viewer
│   ├── drawing_canvas_page.dart     # Doodle drawing canvas
│   └── update_history_service.dart  # History persistence
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
- `shared_preferences` - Theme and settings persistence

## User Mapping

| User | Name    | Default Color |
|------|---------|---------------|
| 1    | Tanmay  | Purple        |
| 2    | Aanchal | Blue          |

## License

This project is for educational purposes.
