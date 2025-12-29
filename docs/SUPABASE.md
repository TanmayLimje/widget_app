# Supabase Integration Reference

> [!IMPORTANT]
> This document tracks ALL Supabase-related code and dependencies. Use this to **completely remove** Supabase from the project if needed.

---

## Quick Removal Checklist

- [ ] Remove `supabase_flutter` from `pubspec.yaml`
- [ ] Delete `lib/services/supabase_service.dart`
- [ ] Remove Supabase initialization from `lib/main.dart`
- [ ] Remove sync calls from `lib/update_history_service.dart`
- [ ] Run `flutter pub get`
- [ ] Delete Supabase project (optional)

---

## Files Changed

### 1. `pubspec.yaml`

**Added dependency:**
```yaml
dependencies:
  supabase_flutter: ^2.3.0
```

**To remove:** Delete the `supabase_flutter` line from dependencies.

---

### 2. `lib/main.dart`

**Added import:**
```dart
import 'services/supabase_service.dart';
```

**Added initialization in `main()`:**
```dart
await SupabaseService.initialize();
```

**To remove:** Delete the import and the `await SupabaseService.initialize();` line.

---

### 3. `lib/services/supabase_service.dart` [NEW FILE]

**Purpose:** Centralized Supabase client management and sync operations.

**To remove:** Delete the entire file.

---

### 4. `lib/update_history_service.dart`

**Added import:**
```dart
import 'services/supabase_service.dart';
```

**Added sync call in `saveUpdate()` method:**
```dart
// Sync to Supabase (add remove later)
await SupabaseService.syncUpdate(...);
```

**Added listener initialization (if implemented):**
```dart
SupabaseService.streamUpdates().listen(...);
```

**To remove:** Delete the import and any lines containing `SupabaseService`.

---

## Supabase Project Details

**Project URL:** `YOUR_SUPABASE_URL`  
**Anon Key:** `YOUR_ANON_KEY`  

> [!CAUTION]
> Replace placeholders above with actual values after creating your Supabase project.

---

## Database Schema

### Table: `updates`

| Column | Type | Description |
|--------|------|-------------|
| `id` | TEXT (PK) | Unique update ID |
| `user_id` | TEXT | `tanmay` or `aanchal` |
| `user_name` | TEXT | Display name |
| `text` | TEXT | Update message (nullable) |
| `image_url` | TEXT | Supabase Storage URL (nullable) |
| `color_hex` | TEXT | Theme color hex string |
| `created_at` | TIMESTAMPTZ | Timestamp |
| `updated_at` | TIMESTAMPTZ | Last update time |

### Storage Bucket: `update-images`

Public bucket for storing update images.

---

## SQL to Create Table

```sql
-- Create updates table
CREATE TABLE updates (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  user_name TEXT NOT NULL,
  text TEXT,
  image_url TEXT,
  color_hex TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (optional but recommended)
ALTER TABLE updates ENABLE ROW LEVEL SECURITY;

-- Policy: Allow all operations (simple setup)
CREATE POLICY "Allow all" ON updates FOR ALL USING (true);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE updates;
```

---

## How Sync Works

```
┌─────────────┐     saveUpdate()     ┌──────────────────┐
│   App UI    │ ──────────────────► │ UpdateHistory    │
└─────────────┘                      │ Service (local)  │
                                     └────────┬─────────┘
                                              │
                                              ▼
                                     ┌──────────────────┐
                                     │ SupabaseService  │
                                     │ (remote sync)    │
                                     └────────┬─────────┘
                                              │
                                              ▼
                                     ┌──────────────────┐
                                     │ Supabase Cloud   │
                                     │ (Database +      │
                                     │  Storage)        │
                                     └────────┬─────────┘
                                              │
                                    Realtime Stream
                                              │
                                              ▼
                                     ┌──────────────────┐
                                     │ Other Device     │
                                     │ (receives update)│
                                     └──────────────────┘
```

---

## Complete Removal Instructions

### Step 1: Remove Dependency

Edit `pubspec.yaml`:
```diff
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  home_widget: ^0.7.0
  image_picker: ^1.0.7
  path_provider: ^2.1.2
  shared_preferences: ^2.5.4
- supabase_flutter: ^2.3.0
```

### Step 2: Delete Service File

```powershell
Remove-Item "d:\all_flutter-main\widget_app\lib\services\supabase_service.dart"
```

### Step 3: Edit main.dart

Remove:
```dart
import 'services/supabase_service.dart';
```

Remove from `main()`:
```dart
await SupabaseService.initialize();
```

### Step 4: Edit update_history_service.dart

Remove:
```dart
import 'services/supabase_service.dart';
```

Remove any calls to:
```dart
SupabaseService.syncUpdate(...)
SupabaseService.streamUpdates()
```

### Step 5: Clean Up

```powershell
cd d:\all_flutter-main\widget_app
flutter pub get
flutter clean
flutter run
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Supabase not initialized" | Ensure `SupabaseService.initialize()` is called before `runApp()` |
| Images not uploading | Check Storage bucket policies allow public access |
| Realtime not working | Verify table is added to `supabase_realtime` publication |
| Build fails after removal | Run `flutter clean` and `flutter pub get` |

---

*Last updated: 2025-12-29*
