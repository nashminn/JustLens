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
- Two bottom actions:
  - **Save** — prompts user to name the scan (default = timestamp), then saves pages as images to app storage and adds to home library
  - **Export** — full sheet for format (PDF/images), location, OCR, and name options

---

## F5a: Save
**Purpose:** Save the scan to the app's internal library as images.

### Requirements
- Tapping Save shows a rename prompt with a pre-filled default name ("Scan_YYYY-MM-DD_HHMMSS")
- User can accept the default or type a custom name
- On confirm: pages are saved as JPEG images to app internal storage
- A scan record is created in the local DB (name, date, page count, image paths, first-page thumbnail)
- Scan immediately appears in home screen library with thumbnail + name
- Progress indicator while writing images
- Success snackbar with "Open" quick action

### Technical Notes
- Internal storage path: `<app_documents>/scans/<scan_id>/page_01.jpg`, `page_02.jpg`, etc.
- Thumbnail = first page image (scaled down, stored alongside pages)
- This is the canonical representation — Export always works from these saved images

---

## F5b: Export
**Purpose:** Export the scan as a PDF or image files to a chosen location, with full control over format and quality.

### Requirements
- Can be triggered from the review screen (after scanning) or from the home screen (re-export any saved scan)
- **Format selection:**
  - Single PDF — all selected pages combined, one photo per page
  - Individual images (JPEG or PNG — let user pick, default JPEG)
- **PDF options:**
  - OCR enabled by default (text-searchable PDF)
  - Toggle OCR off for image-only PDF (faster)
  - PDF page size: auto-fit to document dimensions
- **Image options:**
  - Quality slider (for JPEG compression)
- **Save location:**
  - Device shared storage (Downloads/Documents — user picks via system file picker)
- **Naming:**
  - Pre-filled with scan name, user can change before exporting
- Progress indicator during PDF generation + OCR
- Success confirmation with "Open" and "Share" quick actions

### Technical Notes
- Always reads from internally saved images (F5a must have run first, or export triggers an implicit save)
- OCR runs per-page using ML Kit text recognition
- PDF built with `pdf` package: image layer + invisible text layer at matched positions
- Storage Access Framework for writing to shared storage on Android

---

## F6: Settings
**Purpose:** App-level preferences.

### Requirements
- **Default export format:** PDF / Images (pre-fills Export sheet)
- **OCR default:** On / Off (applies to Export)
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
- Each scan record: id, name, date, page count, image paths, thumbnail path (first page)
- Home screen thumbnail = first page image of the scan
- Tap scan → opens review showing all pages of that scan
- Re-export: tap Export from any saved scan's review screen
- Delete scan: removes images from storage + DB entry, confirms with dialog
- Rename scan: from home screen (long-press) or review screen app bar
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
