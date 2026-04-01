# JustLens — Tech Stack

## Framework
- **Flutter** (latest stable, currently 3.x)
- **Dart** as the programming language
- Min SDK: Android API 24 (Android 7.0)

## Key Dependencies

### Camera & Image Capture
- **`camera`** — Flutter's official camera plugin for viewfinder and capture
- **`image`** — Dart image processing (crop, rotate, filters)

### Document Edge Detection & Perspective Correction
- **`google_mlkit_document_scanner`** — Google ML Kit's on-device document scanner API
  - Handles auto-edge detection, perspective correction, and enhancement
  - Runs fully on-device, no network required
  - Available on Android (iOS support via ML Kit is also available for later)
  - *Alternative if ML Kit scanner doesn't give enough control:* Use `opencv_dart` (OpenCV bindings for Dart) for manual edge detection + perspective transform

### OCR
- **`google_mlkit_text_recognition`** — On-device text recognition
  - Supports Latin scripts out of the box
  - Additional language packs can be added later
  - No network required

### PDF Generation
- **`pdf`** (dart `pdf` package) — Generates PDF files from images
  - Embed OCR text as invisible layer behind images (searchable PDF)
- **`printing`** — For PDF preview if needed

### Local Storage & File Management
- **`path_provider`** — Access to app-specific directories
- **`file_picker`** or **`saf_util`** — Let user pick save location via Storage Access Framework (Android) / document picker
- **`sqflite`** or **`isar`** — Local database for scan metadata (name, date, page count, export history)
  - Leaning **Isar** — fast, Flutter-native, no native dependencies, good for this use case

### State Management
- **`riverpod`** — Clean, testable, scales well without boilerplate
  - Preferred over Provider (more flexible) and Bloc (less boilerplate for this scope)

### UI / UX
- **Material Design 3** (Material You) — modern, clean, adaptive
- **`flex_color_scheme`** — Easy Material 3 theming with dynamic color support
- **`flutter_animate`** — Subtle, polished animations

### Permissions
- **`permission_handler`** — Camera, storage permissions

## Project Structure (Feature-First)

```
lib/
├── main.dart
├── app.dart                    # App widget, theme, routing
├── core/
│   ├── theme/                  # Theme config, colors, typography
│   ├── router/                 # GoRouter config
│   ├── constants/              # App-wide constants
│   └── utils/                  # Shared utilities
├── features/
│   ├── home/                   # Home screen — recent scans, quick actions
│   │   ├── presentation/       # Widgets, screens
│   │   ├── providers/          # Riverpod providers
│   │   └── models/             # View models if needed
│   ├── scanner/                # Camera, capture, edge detection
│   │   ├── presentation/
│   │   ├── providers/
│   │   └── services/           # Camera service, ML Kit integration
│   ├── editor/                 # Crop, perspective, lighting adjustments
│   │   ├── presentation/
│   │   ├── providers/
│   │   └── services/
│   ├── review/                 # Preview pages, reorder, select for export
│   │   ├── presentation/
│   │   └── providers/
│   ├── export/                 # PDF generation, image export, save location
│   │   ├── presentation/
│   │   ├── providers/
│   │   └── services/           # PDF builder, OCR service, file saver
│   └── settings/               # App settings
│       └── presentation/
└── shared/
    ├── widgets/                # Reusable UI components
    ├── models/                 # Shared data models (ScanDocument, ScanPage)
    └── services/               # Database service, permission service
```

## Build & Tooling
- **Flutter 3.x stable**
- **`flutter_lints`** — Strict lint rules
- **`build_runner`** — Code generation (for Isar, Riverpod if using codegen)
- Target: Android APK/AAB initially, iOS IPA later
