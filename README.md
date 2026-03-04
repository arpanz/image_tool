# Pixel Forge ⚡

> Offline-first high-performance image compression and resizing utility
>
> Publisher: **Livinlabs**

## Features

- 📦 Compress images (JPG, PNG, WEBP)
- ↔️ Resize with optional aspect ratio lock
- 🔄 Convert between formats
- 🚀 Background isolate processing — UI never blocks
- 🌑 Dark mode only
- 🔒 100% offline — no data leaves the device

## Architecture

```
lib/
  core/
    constants/     # App-wide constants
    models/        # SelectedImage, CompressionSettings, CompressionResult
    theme/         # AppTheme, AppColors
    utils/         # ImageProcessor (isolate-based)
    widgets/       # Shared UI components
  features/
    picker/        # Image selection screen + Notifier
    editor/        # Compression settings screen + Notifier
    result/        # Results display screen
main.dart
```

## State Management

Riverpod `Notifier` / `AsyncNotifier` patterns throughout.

## Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `flutter_image_compress` | Native compression |
| `image_picker` | Gallery access |
| `path_provider` | File paths |
| `share_plus` | Share output |
| `google_fonts` | Inter typography |
| `gap` | Spacing utility |

## Getting Started

```bash
flutter pub get
flutter run
```

### Android permissions (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
```

### iOS permissions (ios/Runner/Info.plist)
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Pixel Forge needs access to select images for compression.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Pixel Forge needs permission to save compressed images.</string>
```
