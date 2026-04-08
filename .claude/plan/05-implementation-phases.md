# JustLens — Implementation Phases

## Phase 0: Project Setup ✅
- [x] Initialize Flutter project (`flutter create --org com.justlens --platforms android .`)
- [x] Configure min SDK (Android API 24)
- [x] Add core dependencies (flutter_riverpod, go_router, flex_color_scheme, camera, image, permission_handler, flutter_animate)
  - Note: Isar removed — 3.x is abandoned and incompatible with current AGP (namespace error). Will use `drift` + `sqflite` in Phase 6 instead.
- [x] Set up project structure (feature-first folders under lib/)
- [x] Configure linting rules (analysis_options.yaml)
- [x] Basic app shell: MaterialApp.router with Material 3 theme (flex_color_scheme), GoRouter, empty home screen, settings screen stub
- [x] Android permissions setup (camera, storage r/w for API 24-32, READ_MEDIA_IMAGES for API 33+)

**Milestone:** App builds and runs with empty home screen + routing skeleton ✅

---

## Phase 1: Camera & Basic Capture ✅
- [x] Camera screen with viewfinder using `camera` plugin
- [x] Capture button — take a photo, save to temp directory (XFile temp path)
- [x] Flash toggle (off / auto / on — cycles on tap)
- [x] Single vs batch mode toggle
- [x] Batch mode: capture multiple, show page count, "Done" to proceed
- [x] Import from gallery option (`image_picker`)
- [x] Basic navigation: Home → Scanner → Review screen (stub)

**Milestone:** Can open camera, take one or more photos, see them in a list ✅

---

## Phase 2: Edge Detection & Perspective Correction ✅
- [x] Evaluate ML Kit Document Scanner API vs custom OpenCV approach
  - **Decision: ML Kit Document Scanner chosen.** Superior quality, handles all Phase 2
    features (real-time edge overlay, perspective correction, 4-corner adjust, auto-capture)
    with minimal code. Custom OpenCV would add ~30MB and significant complexity.
- [x] Real-time edge detection overlay on camera viewfinder (ML Kit built-in)
- [x] Auto-crop on capture based on detected edges (ML Kit built-in)
- [x] Manual 4-corner crop adjustment with draggable handles (ScannerMode.full)
- [x] Perspective correction / de-skew (ML Kit built-in)
- [x] Auto-capture when document is steady + edges stable (ML Kit built-in)
- [x] Gallery import upgraded: ML Kit also applies edge detection + correction to gallery photos

**Milestone:** Camera detects document edges, auto-crops and corrects perspective ✅

**Implementation notes:**
- `scanner_screen.dart` is now a transparent ML Kit launcher (shows spinner while ML Kit Activity is active)
- `camera_service.dart` removed — ML Kit owns the camera
- `galleryMode` param on `ScannerScreen` routes to ML Kit's gallery picker mode
- Home screen AppBar has an "Import" icon that triggers gallery mode
- Graceful fallback message shown if Google Play Services unavailable

---

## Phase 3: Image Editor
- [ ] Editor screen with processed image
- [ ] Rotation (90-degree steps + free rotation)
- [ ] Brightness adjustment slider
- [ ] Contrast adjustment slider
- [ ] Filter presets (Original, B&W, Grayscale, Sharp)
- [ ] Auto-enhance (one-tap brightness + contrast + sharpness optimization)
- [ ] Before/after comparison (hold to see original)
- [ ] Non-destructive editing: store parameters, keep original
- [ ] Undo/redo

**Milestone:** Scanned pages can be refined with lighting, rotation, and filters

---

## Phase 4: Review & Page Management
- [ ] Review screen showing all captured pages as thumbnail strip
- [ ] Tap thumbnail → large preview
- [ ] Drag-and-drop reorder
- [ ] Select/deselect pages (checkboxes)
- [ ] Delete individual pages
- [ ] Retake a page (replace with new capture)
- [ ] Add more pages to batch
- [ ] Tap page → opens editor

**Milestone:** Full page management before export

---

## Phase 5: Save & Export — Images & PDF with OCR

### 5a: Save to Library
- [ ] Rename prompt on Save: dialog with pre-filled timestamp name, user can edit
- [ ] Write pages as JPEG images to `<app_documents>/scans/<scan_id>/page_XX.jpg`
- [ ] Generate thumbnail (first page, scaled down)
- [ ] Create scan record in local DB (id, name, date, page count, image paths, thumbnail path)
- [ ] Progress indicator while writing
- [ ] Success snackbar with "Open" action
- [ ] Scan appears immediately in home screen library with thumbnail + name

### 5b: Export to PDF / Images
- [ ] Export bottom sheet UI (format, OCR toggle, save location, name)
- [ ] Always reads from internally saved images (triggers implicit save if not yet saved)
- [ ] PDF export: combine pages into single PDF, one photo per page
- [ ] OCR integration using ML Kit text recognition
- [ ] Searchable PDF: invisible text layer overlaid at matched bounding box positions
- [ ] Image export: write selected pages as JPEG/PNG to chosen location
- [ ] Save to device shared storage via Storage Access Framework
- [ ] Progress indicator during PDF generation + OCR
- [ ] Success confirmation with "Open" / "Share" actions
- [ ] Re-export available from home screen on any saved scan

**Milestone:** Scans saved as images in app library; can be exported as searchable PDF or image files

---

## Phase 6: Home Screen & Scan History
- [ ] Local database setup (Isar) for scan metadata
- [ ] Home screen: grid of saved scans with thumbnails
- [ ] Scan card: thumbnail, name, date, page count
- [ ] Tap scan → review/re-export
- [ ] Swipe to delete with undo
- [ ] Rename scan
- [ ] Sort by date/name
- [ ] Empty state
- [ ] Storage usage display

**Milestone:** Full document management on home screen

---

## Phase 7: Settings & Polish
- [ ] Settings screen with all preferences
- [ ] Dark mode / light mode / system toggle
- [ ] Default export preferences
- [ ] Persist settings (shared preferences)
- [ ] Animations and transitions (page transitions, capture animation)
- [ ] Haptic feedback
- [ ] Loading states and skeletons
- [ ] Error handling (camera unavailable, storage full, etc.)
- [ ] Edge cases (permissions denied, low memory)

**Milestone:** Polished, production-ready app

---

## Phase 8: Pre-Release
- [ ] App icon and splash screen
- [ ] Test on multiple Android devices/emulators (API 24 through latest)
- [ ] Performance profiling (image processing, PDF generation)
- [ ] Optimize image memory usage (large documents can be heavy)
- [ ] Accessibility audit
- [ ] Build release APK/AAB
- [ ] Play Store listing prep (if publishing)

**Milestone:** Ready for release

---

## Dependency Map

```
Phase 0 (Setup)
    │
    ▼
Phase 1 (Camera) ──────────┐
    │                       │
    ▼                       │
Phase 2 (Edge Detection)    │
    │                       │
    ▼                       │
Phase 3 (Editor)            │
    │                       │
    ▼                       │
Phase 4 (Review)            │
    │                       │
    ▼                       ▼
Phase 5 (Export) ◄── Phase 6 (Home/History)
    │                       │
    ▼                       ▼
Phase 7 (Settings & Polish)
    │
    ▼
Phase 8 (Pre-Release)
```

Phases 1-5 are sequential (each builds on the previous).
Phase 6 can start in parallel with Phase 3+ (DB and home screen are independent of editor).
Phase 7-8 are final polish.

## Estimated Complexity
- **Phase 0:** Low — boilerplate setup
- **Phase 1:** Low-Medium — standard camera integration
- **Phase 2:** **High** — edge detection + perspective correction is the hardest part
- **Phase 3:** Medium — image processing with sliders
- **Phase 4:** Low-Medium — mostly UI/state management
- **Phase 5:** Medium-High — PDF generation with OCR text overlay
- **Phase 6:** Low-Medium — CRUD with local DB
- **Phase 7:** Low — settings and polish
- **Phase 8:** Low — testing and optimization
