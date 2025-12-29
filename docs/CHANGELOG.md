# Changelog

All notable changes to the AanTan project are documented in this file.

## [3.0.0] - 2025-12-29

### Added

#### User Login System
- **Login Page**
  - Two styled buttons: "Login as Tanmay" and "Login as Aanchal"
  - Beautiful gradient design with app branding
  - Seamless navigation to user-specific home page

- **User-Specific Home Page**
  - Personalized greeting ("Hi, Tanmay!" or "Hi, Aanchal!")
  - Shows only the logged-in user's update card
  - Widget preview displays both users' content
  - Logout button to switch between users

- **Named Routes**
  - `/login` - Login page (initial route)
  - `/home` - User home page with userNumber argument

### Changed

- Widget labels changed from "User 1/User 2" to "Tanmay/Aanchal"
- App now starts with login page instead of direct home
- Simplified user experience - each user sees only their controls

### Technical Details

- New files:
  - `login_page.dart` - Login screen with user selection
  - `user_home_page.dart` - User-specific home page
- Updated `main.dart` with route-based navigation
- Updated Android widget XML with proper names

---

## [2.0.0] - 2025-12-29

### Added

#### Image Updates Feature
- **Image Picker Integration**
  - Camera capture support
  - Gallery import support
  - Beautiful bottom sheet for source selection
  - Images saved locally with unique filenames

- **Status-Update Style Widget**
  - Username label at top
  - Large content image in the middle
  - Optional caption text at bottom
  - 4×3 cell size for better image visibility

- **Tap to Open**
  - Widget now opens the app when tapped
  - Uses PendingIntent with FLAG_IMMUTABLE for Android 12+ compatibility

- **UI Improvements**
  - Live image preview in widget preview
  - Larger image selection area in user cards
  - Change/Remove buttons for images
  - Caption field marked as optional

### Changed

- Widget size increased from 4×1 to **4×3** cells
- Widget minimum height increased from 60dp to **180dp**
- Widget layout restructured for image-centric display
- Text field changed from "Message" to "Caption (optional)"

### Technical Details

- Added `image_picker: ^1.0.7` for camera/gallery access
- Added `path_provider: ^2.1.2` for local file storage
- Widget provider now loads bitmaps with memory-efficient sampling
- Images compressed to 800×800 max with 85% JPEG quality

---

## [1.0.0] - 2025-12-29

### Added

#### Initial Release - Dual User Widget

- **Flutter App**
  - Modern Material 3 UI with gradient background
  - Two user configuration cards
  - Text input fields for custom messages
  - Color picker with 8 theme options
  - Live widget preview
  - "Update Widget" button with loading state
  - Persistent storage of user preferences

- **Android Widget**
  - Split layout with User 1 (left) and User 2 (right) sections
  - Dynamic background colors per user
  - Customizable text display
  - 4×1 cell default size (resizable)
  - Rounded corners design

- **Color Themes**
  - Purple (#6366F1)
  - Blue (#3B82F6)
  - Green (#10B981)
  - Orange (#F97316)
  - Pink (#EC4899)
  - Red (#EF4444)
  - Teal (#14B8A6)
  - Yellow (#EAB308)

### Technical Details

- Flutter SDK: ^3.10.4
- Package: home_widget ^0.7.0
- Minimum Android SDK: 21
- Widget update period: 24 hours

---

## [0.1.0] - 2025-12-29

### Added

#### Initial Setup

- Created Flutter project structure
- Renamed project from `widget_app` to `AanTan`
- Updated all platform configurations:
  - Android (manifest, build.gradle)
  - iOS (Info.plist)
  - Windows (main.cpp)
  - Linux (CMakeLists.txt)
  - Web (index.html, manifest.json)

---

## Future Roadmap

### Planned Features

- [x] ~~Widget click to open app~~ ✅ Added in v2.0.0
- [x] ~~Image sharing support~~ ✅ Added in v2.0.0
- [x] ~~Larger widget size (4×3)~~ ✅ Added in v2.0.0
- [ ] Multiple widget sizes (2×2, 4×4)
- [ ] Custom username labels
- [ ] Gradient backgrounds
- [ ] Widget refresh from notification
- [ ] iOS home screen widget support
- [ ] Animated image transitions
