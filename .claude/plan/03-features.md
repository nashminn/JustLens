# JustLens — Feature Breakdown

## F1: Home Screen
**Purpose:** Entry point. Shows recent scans and primary actions.

### Requirements
- List of recent scans (thumbnail, name, date, page count)
- Prominent floating action button → "New Scan"
- Tap a scan → opens review/re-export screen
- Long-press or swipe → delete scan
- Empty state with illustration + "Scan your first document" prompt
- Search/filter scans (stretch goal for v1)

---

## F2: Document Scanning (Camera)
**Purpose:** Capture document pages using the device camera.

### Requirements
- Full-screen camera viewfinder
- **Single mode:** Capture one page, proceed to editor
- **Batch mode:** Capture multiple pages sequentially, counter shows page count
- Real-time edge detection overlay (highlight detected document edges)
- Auto-capture option (captures when document is steady + edges detected)
- Manual capture button (large, thumb-friendly)
- **Flash toggle:** off / on / auto (persists across sessions)
- Switch camera (front/back) — back is default
- Cancel → confirm discard if pages captured
- Import from gallery (for photos already taken)

### Technical Notes
- Use ML Kit Document Scanner if it provides sufficient camera UI control
- If ML Kit scanner is too opaque (limited UI customization), use `camera` plugin + `opencv_dart` for edge detection, giving full control over the UX
- Decision point: prototype with ML Kit scanner first; fall back to custom camera if needed

---

## F3: Document Editor (Per-Page)
**Purpose:** Refine each captured page.

### Requirements
- **Crop:** Drag corners/edges to adjust crop region
- **Perspective correction:** Auto-correct tilt based on detected edges; manual 4-point adjust
- **Rotation:** 90-degree rotation buttons + free rotation
- **Lighting/Filters:**
  - Auto-enhance (one-tap improvement)
  - Brightness slider
  - Contrast slider
  - Preset filters: Original, Black & White, Grayscale, Sharp
- Before/after comparison (tap-hold to see original)
- Apply to all pages option (batch apply filter/enhancement)
- Undo/redo for adjustments

### Technical Notes
- Image processing via `image` package or OpenCV for heavier transforms
- Keep original image; apply adjustments non-destructively (store parameters)
- Generate processed image on export

---

## F4: Review & Page Management
**Purpose:** Overview of all scanned pages before export.

### Requirements
- Grid or horizontal strip of page thumbnails
- **Reorder:** Drag-and-drop to rearrange pages
- **Select/deselect:** Checkbox on each page for selective export
- **Delete:** Remove individual pages
- **Retake:** Replace a specific page (opens camera for that slot)
- **Add more:** Append additional pages to the batch
- Tap a page → opens editor (F3) for that page
- Page count indicator
- "Export" button (prominent, bottom of screen)

---

## F5: Export
**Purpose:** Save scanned documents as images or PDF.

### Requirements
- **Format selection:**
  - Individual images (JPEG or PNG — let user pick, default JPEG)
  - Single PDF (all selected pages combined)
- **PDF options:**
  - OCR enabled by default (text-searchable PDF)
  - Toggle OCR off if user wants image-only PDF (faster export)
  - PDF page size: auto-fit to document dimensions
- **Image options:**
  - Quality slider (for JPEG compression)
  - Resolution: Original or reduced
- **Save location:**
  - App internal storage (default — accessible from home screen)
  - Device shared storage (Documents/Downloads — user picks via system picker)
- **Naming:**
  - Auto-generated name: "Scan_YYYY-MM-DD_HHMMSS"
  - User can rename before saving
- Progress indicator for PDF generation + OCR (can take a few seconds per page)
- Success confirmation with "Open" and "Share" quick actions

### Technical Notes
- OCR runs per-page using ML Kit text recognition
- PDF built with `pdf` package: image layer + invisible text layer positioned to match
- For save-to-shared-storage: use Storage Access Framework on Android (scoped storage compliant)

---

## F6: Settings
**Purpose:** App-level preferences.

### Requirements
- **Default save location:** App storage / Shared storage
- **Default export format:** Images / PDF
- **OCR default:** On / Off
- **Image quality default:** slider
- **Flash default:** Off / On / Auto
- **Auto-capture:** On / Off
- **Theme:** Light / Dark / System
- **About:** App version, open-source licenses
- **Storage usage:** How much space scans are using, option to clear

---

## F7: Scan History / Document Management
**Purpose:** Manage previously saved scans.

### Requirements
- All scans stored in local DB with metadata
- Each scan record: id, name, date, page count, thumbnail path, file paths, export history
- Re-export: open any past scan and export again with different settings
- Delete scan: removes images + DB entry, confirms with dialog
- Rename scan
- Sort by: date (default), name

---

## Future Features (Post-v1, Not In Scope Now)
- iOS release
- Cloud backup (Google Drive, iCloud)
- Share directly to other apps
- Multi-language OCR
- Document annotation / signature
- Folder organization
- Widget for quick scan
- Batch rename
- Ads (if monetization needed)
