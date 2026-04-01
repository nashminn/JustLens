# JustLens — Key Technical Decisions & Open Questions

## Decided
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Framework | Flutter | Cross-platform, strong camera/image ecosystem, Dart performance |
| State management | Riverpod | Clean, testable, less boilerplate than Bloc |
| Local DB | Isar | Flutter-native, fast, no SQLite bridging overhead |
| OCR | Google ML Kit Text Recognition | On-device, free, good quality for Latin scripts |
| PDF | `pdf` Dart package | Pure Dart, full control over text layer positioning |
| UI system | Material Design 3 | Modern, adaptive, built into Flutter |
| Navigation | GoRouter | Declarative, supports deep linking for future |
| Min Android | API 24 (Android 7.0) | Balances reach vs modern API availability |

## To Decide During Implementation

### 1. ML Kit Document Scanner vs Custom Camera + OpenCV
**Context:** Google's ML Kit Document Scanner provides a turnkey solution (camera UI + edge detection + crop + perspective correction). But it may limit UI customization.

**Approach:**
- Start Phase 1-2 by prototyping with ML Kit Document Scanner
- Evaluate: Does it allow custom UI overlay? Flash control? Batch mode with our UX?
- If yes → use it (saves significant development time)
- If no → build custom using `camera` plugin + `opencv_dart` for edge detection

**Impact:** If ML Kit scanner works, Phases 1+2 compress significantly. If custom, Phase 2 is the most complex part of the project.

### 2. Image Processing Library
**Options:**
- `image` (pure Dart) — cross-platform, slower on large images
- `opencv_dart` — fast, native, but adds binary size
- Flutter's Canvas API — for simple transforms only

**Approach:** Start with `image` package. If performance is inadequate for real-time preview (editor sliders), introduce OpenCV selectively.

### 3. Scoped Storage Strategy
Android 10+ changed storage access. Need to handle:
- API 24-28: Traditional file access (with permissions)
- API 29: Opt-out of scoped storage via manifest flag
- API 30+: Must use Storage Access Framework or MediaStore

**Approach:** Use `saf_util` or similar package that abstracts this. Test on API 24 and API 34.

### 4. OCR Text Positioning in PDF
For searchable PDFs, OCR text must be positioned to match the visual location in the image. This requires:
- Running OCR to get text + bounding boxes
- Mapping bounding box coordinates from image space to PDF page space
- Rendering invisible text at those positions

**Approach:** ML Kit returns `TextBlock` objects with bounding rectangles. Map these to PDF coordinates and render with transparent fill.
