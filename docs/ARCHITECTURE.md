# AanTan Architecture

## Overview

AanTan is a Flutter application that demonstrates how to create Android home screen widgets with Flutter. It uses the `home_widget` package to bridge Flutter and native Android widget functionality, with support for images and dynamic content.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                               │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                      main.dart                               │ │
│  │  • User Interface (Material 3)                               │ │
│  │  • Image picker (camera/gallery)                             │ │
│  │  • Text input fields for captions                            │ │
│  │  • Color picker with 8 theme options                         │ │
│  │  • Widget preview with live updates                          │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              │                                    │
│                              ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    home_widget package                       │ │
│  │  • HomeWidget.saveWidgetData() - Store text, colors, images  │ │
│  │  • HomeWidget.updateWidget() - Trigger widget refresh        │ │
│  │  • HomeWidget.getWidgetData() - Load persisted data          │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              │                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │               image_picker + path_provider                   │ │
│  │  • Capture photos from camera                                │ │
│  │  • Pick images from gallery                                  │ │
│  │  • Save images to app documents directory                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                               │
                               │ SharedPreferences + File System
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Android Native Layer                         │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │              AanTanWidgetProvider.kt                         │ │
│  │  • Extends AppWidgetProvider                                 │ │
│  │  • Reads SharedPreferences for user data                     │ │
│  │  • Loads bitmap images from file paths                       │ │
│  │  • Updates RemoteViews with images, text & colors            │ │
│  │  • Handles tap-to-open via PendingIntent                     │ │
│  └─────────────────────────────────────────────────────────────┘ │
│                              │                                    │
│                              ▼                                    │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                  aantan_widget.xml                           │ │
│  │  • Split LinearLayout (horizontal)                           │ │
│  │  • User 1 section: Label → Image → Caption                   │ │
│  │  • User 2 section: Label → Image → Caption                   │ │
│  │  • Images take most vertical space                           │ │
│  └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Android Home Screen                           │
│  ┌──────────────────────┬──────────────────────┐                 │
│  │      User 1          │       User 2         │                 │
│  │   ┌──────────────┐   │   ┌──────────────┐   │                 │
│  │   │              │   │   │              │   │                 │
│  │   │   [IMAGE]    │   │   │   [IMAGE]    │   │                 │
│  │   │              │   │   │              │   │                 │
│  │   └──────────────┘   │   └──────────────┘   │                 │
│  │    Caption text      │    Caption text      │                 │
│  └──────────────────────┴──────────────────────┘                 │
│           ↓ TAP OPENS APP ↓                                      │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### Saving Widget Data

1. User selects/captures image in Flutter app
2. Image is saved to app documents directory
3. App calls `HomeWidget.saveWidgetData()` with keys:
   - `user1_text`, `user2_text` - Caption messages (optional)
   - `user1_color`, `user2_color` - Color hex codes
   - `user1_image`, `user2_image` - Absolute file paths
4. Data is stored in Android SharedPreferences
5. App calls `HomeWidget.updateWidget()` to trigger refresh

### Widget Update

1. Android system calls `AanTanWidgetProvider.onUpdate()`
2. Provider reads SharedPreferences for stored data
3. Loads bitmap images from file paths (with memory-efficient sampling)
4. Creates RemoteViews with updated content
5. Sets images, text and background colors
6. Sets up PendingIntent for tap-to-open functionality
7. Calls `appWidgetManager.updateAppWidget()` to refresh display

### Widget Interaction

1. User taps anywhere on the widget
2. PendingIntent triggers, launching MainActivity
3. App opens with previously saved data loaded

## Key Components

### Flutter Layer

| Component | Purpose |
|-----------|---------|
| `AanTanApp` | Root widget with Material 3 theming |
| `HomePage` | Main UI with user cards and preview |
| `UserTheme` | Data class for color options |
| `_buildUserCard()` | Reusable widget for user configuration |
| `_pickImage()` | Image picker with camera/gallery options |
| `_saveImageLocally()` | Saves captured images to documents dir |
| `_buildImageSourceSheet()` | Bottom sheet for image source selection |

### Android Layer

| Component | Purpose |
|-----------|---------|
| `AanTanWidgetProvider` | Handles widget lifecycle, updates, and click handling |
| `aantan_widget.xml` | Widget layout definition (vertical: label → image → caption) |
| `aantan_widget_info.xml` | Widget metadata (4×3 size, category) |
| `image_placeholder.xml` | Drawable for empty image state |
| `AndroidManifest.xml` | Widget receiver registration |

## Color System

The app supports 8 predefined color themes:

| Color | Hex Code | Key |
|-------|----------|-----|
| Purple | #6366F1 | FF6366F1 |
| Blue | #3B82F6 | FF3B82F6 |
| Green | #10B981 | FF10B981 |
| Orange | #F97316 | FFF97316 |
| Pink | #EC4899 | FFEC4899 |
| Red | #EF4444 | FFEF4444 |
| Teal | #14B8A6 | FF14B8A6 |
| Yellow | #EAB308 | FFEAB308 |

## Widget Specifications

- **Minimum Size**: 250dp × 180dp
- **Target Size**: 4 × 3 cells
- **Update Period**: 24 hours (86400000ms)
- **Resize Mode**: Horizontal and Vertical
- **Category**: Home Screen
- **Interaction**: Tap to open app

## Image Handling

### Flutter Side
- Images captured at max 800×800 pixels
- Quality set to 85% for JPEG compression
- Saved to app's documents directory with unique timestamps
- File paths stored in SharedPreferences

### Android Side
- Bitmaps loaded with `inSampleSize = 2` to reduce memory usage
- Graceful fallback to placeholder if image file is missing
- Images displayed with `centerCrop` scaling
