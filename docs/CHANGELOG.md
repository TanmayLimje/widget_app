# Changelog

All notable changes to the AanTan project are documented in this file.

## [3.6.0] - 2026-01-15

### Added

#### Comprehensive Test Suite
- **73 Unit Tests** - Full coverage of all services and models with mocked database dependencies
- **Model Tests** - CanvasElement, EmojiElement, TextElement, UserUpdate
- **Service Tests** - SupabaseService, UpdateHistoryService
- **Mock Utilities** - Reusable test helpers for file system and Supabase client mocking

### Test Categories

| Category | Tests | Description |
|----------|-------|-------------|
| CanvasElement | 17 | Hit testing, bounds calculation, copyWith |
| UserUpdate | 19 | Serialization, deserialization, backward compatibility |
| SupabaseService | 13 | Configuration, API behavior, error handling |
| UpdateHistoryService | 22 | File formats, change detection, ID generation |
| Widget | 2 | Basic app rendering |

### Technical Details

- Added dev dependencies:
  - `mockito: ^5.4.4` - For generating mock classes
  - `build_runner: ^2.4.12` - For code generation
- New test files:
  - `test/models/canvas_element_test.dart`
  - `test/models/user_update_test.dart`
  - `test/services/supabase_service_test.dart`
  - `test/services/update_history_service_test.dart`
  - `test/mocks/mock_supabase_client.dart`
  - `test/mocks/mock_file_system.dart`

---

## [3.5.0] - 2026-01-15

### Added

#### History Page Caching & Incremental Sync
- **Instant UI** - Past Updates page now shows cached data immediately without waiting for API
- **Delta Fetching** - Only fetches updates newer than the last sync timestamp from Supabase
- **Background Sync** - New updates sync in the background with a subtle "syncing..." indicator
- **Persistent Cache** - Remote updates are cached locally for offline access

### Technical Details

- New methods in `update_history_service.dart`:
  - `loadLastSyncTimestamp()` - Get when we last synced with Supabase
  - `saveLastSyncTimestamp()` - Store sync timestamp for delta fetching
  - `loadCachedRemoteUpdates()` - Load previously synced remote updates
  - `saveCachedRemoteUpdates()` - Cache remote updates locally
- New method in `supabase_service.dart`:
  - `fetchUpdatesSince(DateTime since)` - Fetch only updates newer than a timestamp
- Modified `past_updates_page.dart`:
  - Shows cached data immediately on page load
  - Syncs new updates in background with loading indicator
  - Only makes API call for new updates since last sync

---

## [3.4.0] - 2026-01-15

### Fixed

#### Real-Time Sync Bug Fixes
- **User ID Consistency** - Fixed mismatch between `user_id` values stored in Supabase (`user1`/`user2`) and what the real-time listener was checking for (`tanmay`/`aanchal`)
- **Duplicate Widget Saves** - Prevented updates from being saved twice by:
  - Using `saveUserUpdate()` which saves only the current user's update
  - Calling `saveReceivedUpdate()` to update lastState without creating history entries when receiving remote updates
  - Skipping local save when receiving the current user's own update from Supabase

### Changed

- **Refactored `HomePage`** - Moved `HomePage` class from `main.dart` to its own file `home_page.dart` for better code organization
- **Public `themeModeToString()`** - Made the theme mode helper function public (removed underscore) so it can be accessed from other files

### Added

#### Past Updates Page - Cloud Sync
- **Supabase Data Fetching** - `PastUpdatesPage` now fetches all past updates from Supabase using `SupabaseService.fetchAllUpdates()`
- **Image Download** - Remote images are downloaded and cached locally for display
- **Combined History** - Shows both local history and cloud-synced updates
- **Delete from Cloud** - Deleting an update also removes it from Supabase

### Technical Details

- Modified files:
  - `lib/user_home_page.dart` - Fixed real-time sync user ID checks
  - `lib/update_history_service.dart` - Added `saveUserUpdate()`, `saveReceivedUpdate()`, `_updateUserLastState()`
  - `lib/past_updates_page.dart` - Added Supabase fetch + image download
  - `lib/home_page.dart` - New file (refactored from main.dart)
  - `lib/main.dart` - Made `themeModeToString()` public

---

## [3.3.0] - 2026-01-15

### Added

#### Canvas Elements - Emoji & Text Support
- **Mode Switcher** - Top toolbar with three modes:
  - **Draw** - Freehand drawing (existing)
  - **Emoji** - Place and transform emojis
  - **Text** - Add styled text elements

- **Emoji Elements**
  - Emoji picker with 48 popular emojis (smileys, hearts, gestures)
  - Tap to place emoji at canvas center
  - Select emoji to show transform handles
  - Two-finger pinch to resize
  - Two-finger rotate to spin
  - Drag to move anywhere on canvas

- **Text Elements**
  - Text editor dialog with full customization
  - Font family selection (Roboto, serif, monospace, cursive, sans-serif)
  - Font size slider (12-72)
  - Text color palette (8 colors)
  - Optional background color
  - Optional border
  - Tap text to select, tap again to edit
  - Same transform gestures as emoji

- **Element Management**
  - Delete button (red) appears when element selected
  - Undo removes selected element, or last stroke/element
  - Clear All removes everything with confirmation
  - Elements saved as part of the canvas image

### Technical Details

- New files:
  - `lib/models/canvas_element.dart` - Data models for `CanvasElement`, `EmojiElement`, `TextElement`
- Modified files:
  - `lib/drawing_canvas_page.dart` - Complete rewrite with element support, mode switcher, gesture handling

---

## [3.2.0] - 2026-01-15

### Fixed

#### Image Resolution Consistency
- **Square Canvas** - Drawing canvas now uses `AspectRatio(1.0)` to ensure all drawings are saved as square images
- **Consistent Display** - All image displays now use the same aspect ratio throughout the app:
  - Widget preview (Flutter app)
  - Update Image section
  - Past Updates history page
  - Android home screen widget

- **No More Stretching** - Changed Android widget `scaleType` from `centerCrop` to `fitCenter` so images maintain aspect ratio when widget is resized

### Changed

- Widget preview height increased from 180dp to 240dp to accommodate square images + text
- Image containers now use `BoxFit.cover` with square `AspectRatio(1.0)` wrappers
- History page images use square `AspectRatio(1.0)` instead of fixed height

### Technical Details

- Modified `drawing_canvas_page.dart` - Canvas wrapped in `AspectRatio(1.0)`
- Modified `user_home_page.dart` - Widget preview image containers use `AspectRatio(1.0)`
- Modified `main.dart` - HomePage widget preview image containers use `AspectRatio(1.0)`
- Modified `past_updates_page.dart` - History images use `AspectRatio(1.0)`
- Modified `aantan_widget.xml` - Changed `android:scaleType="fitCenter"`

---

## [3.1.0] - 2026-01-15

### Added

#### Supabase Real-Time Sync (Now Working)
- **Cloud Database**
  - `updates` table with RLS enabled
  - Real-time sync between Tanmay and Aanchal's devices
  - Automatic change detection - only syncs modified user data

- **Cloud Storage**
  - `update-images` bucket for image uploads
  - Public access for image URLs
  - Images uploaded with unique IDs

### Fixed

- **Smart Sync** - Only the user who made changes gets synced to Supabase (no duplicate uploads)
- **UI Overflow** - Fixed brush size selector overflow in drawing canvas on smaller screens

### Technical Details

- Configured `supabase_service.dart` with real credentials
- Created database migration for `updates` table
- Created storage bucket with proper RLS policies
- Moved Supabase sync inside change detection blocks in `update_history_service.dart`
- Wrapped brush size buttons with `Flexible` widget in `drawing_canvas_page.dart`

---

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
- [x] ~~Supabase real-time sync~~ ✅ Added in v3.1.0
- [x] ~~Canvas emoji & text elements~~ ✅ Added in v3.3.0
- [ ] Multiple widget sizes (2×2, 4×4)
- [ ] Custom username labels
- [ ] Gradient backgrounds
- [ ] Widget refresh from notification
- [ ] iOS home screen widget support
- [ ] Animated image transitions

