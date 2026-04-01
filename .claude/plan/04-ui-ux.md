# JustLens — UI/UX Plan

## Design Principles
1. **Minimal:** Only show what's needed for the current task
2. **Fast:** Fewest taps from open → scanned → saved
3. **Forgiving:** Easy undo, easy retake, nothing destructive without confirmation
4. **Accessible:** Large touch targets, good contrast, readable text

## Visual Style
- **Material Design 3** (Material You)
- Dynamic color theming (adapts to device wallpaper on Android 12+, falls back to brand palette on older)
- Brand palette: Clean blue-gray primary, white surfaces, subtle shadows
- Dark mode: True dark (AMOLED-friendly dark surfaces)
- Typography: System default (Roboto on Android) with clear hierarchy
- Rounded corners, soft elevation, no harsh borders
- Minimal iconography — outlined Material icons

## Navigation Structure

```
App Launch
    │
    ├── Home Screen (default)
    │     │
    │     ├── [FAB: New Scan] → Scanner Screen
    │     │                        │
    │     │                        ├── [Capture] → Editor Screen (per page)
    │     │                        │                    │
    │     │                        │                    └── [Done] → back to Scanner (batch)
    │     │                        │                                  or Review (single)
    │     │                        │
    │     │                        └── [Done / Review] → Review Screen
    │     │                                                  │
    │     │                                                  └── [Export] → Export Sheet
    │     │                                                                    │
    │     │                                                                    └── [Save] → Home
    │     │
    │     ├── [Tap scan] → Review Screen (for existing scan)
    │     │
    │     └── [Settings icon] → Settings Screen
    │
    └── (no bottom nav — single-purpose app, keep it simple)
```

## Screen Layouts

### Home Screen
```
┌──────────────────────────┐
│  JustLens          [⚙]   │  ← App bar: title + settings
│──────────────────────────│
│                          │
│  ┌──────┐  ┌──────┐     │  ← Grid of recent scans
│  │thumb │  │thumb │     │    (2 columns, cards with
│  │      │  │      │     │     thumbnail, name, date)
│  │ Name │  │ Name │     │
│  │ Date │  │ Date │     │
│  └──────┘  └──────┘     │
│                          │
│  ┌──────┐  ┌──────┐     │
│  │      │  │      │     │
│  │      │  │      │     │
│  └──────┘  └──────┘     │
│                          │
│                    [FAB] │  ← Floating action button: camera icon
│                    Scan  │
└──────────────────────────┘
```

**Empty state:** Centered illustration + "Scan your first document" text + large Scan button

### Scanner Screen
```
┌──────────────────────────┐
│  [✕]  Single | Batch  [⚡]│  ← Close, mode toggle, flash toggle
│──────────────────────────│
│                          │
│                          │
│     ┌──────────────┐    │  ← Camera viewfinder
│     │              │    │    with edge detection
│     │   Document   │    │    overlay (blue border
│     │   detected   │    │    on detected edges)
│     │              │    │
│     └──────────────┘    │
│                          │
│──────────────────────────│
│  [Gallery]    (●)   3📄  │  ← Import, capture button, page count (batch)
└──────────────────────────┘
```

- Capture button: Large circle, center bottom
- Page counter: Shows in batch mode, tapping it opens review
- Auto-capture indicator: Subtle animation on edges when about to auto-fire

### Editor Screen
```
┌──────────────────────────┐
│  [✕]              [✓]    │  ← Cancel, apply
│──────────────────────────│
│                          │
│  ┌──────────────────┐   │  ← Document image
│  │ ●              ● │   │    with draggable corner
│  │                  │   │    handles for crop
│  │                  │   │
│  │ ●              ● │   │
│  └──────────────────┘   │
│                          │
│──────────────────────────│
│  [↻] [↺]  [Auto]        │  ← Rotate, auto-enhance
│──────────────────────────│
│  ☀ Brightness  ──●────  │  ← Adjustment sliders
│  ◐ Contrast    ────●──  │
│──────────────────────────│
│  [Orig] [B&W] [Gray]    │  ← Filter presets
└──────────────────────────┘
```

### Review Screen
```
┌──────────────────────────┐
│  [←]  Scan Review  [+]   │  ← Back, add more pages
│──────────────────────────│
│                          │
│  ┌────┐ ┌────┐ ┌────┐  │  ← Draggable page thumbnails
│  │ ☑1 │ │ ☑2 │ │ ☑3 │  │    with checkboxes
│  │    │ │    │ │    │  │    (drag to reorder)
│  └────┘ └────┘ └────┘  │
│                          │
│  ┌──────────────────┐   │  ← Selected page preview (large)
│  │                  │   │
│  │   Page 1 of 3   │   │
│  │                  │   │
│  │                  │   │
│  └──────────────────┘   │
│                          │
│  [🗑 Delete] [✏ Edit]    │  ← Actions for selected page
│                          │
│  ┌──────────────────────┐│
│  │      Export          ││  ← Primary action button (full width)
│  └──────────────────────┘│
└──────────────────────────┘
```

### Export Bottom Sheet
```
┌──────────────────────────┐
│  Export (3 pages)         │
│──────────────────────────│
│                          │
│  Format                  │
│  ○ PDF (searchable)      │  ← Radio buttons
│  ○ Images (JPEG)         │
│                          │
│  ☑ Enable OCR            │  ← Toggle (PDF only)
│                          │
│  Save to                 │
│  ○ App storage           │
│  ○ Choose location...    │  ← Opens system file picker
│                          │
│  Name: Scan_2026-04-01   │  ← Editable text field
│                          │
│  ┌──────────────────────┐│
│  │       Save           ││
│  └──────────────────────┘│
└──────────────────────────┘
```

## Interaction Details

### Gestures
- **Pinch-to-zoom** on editor and review screens
- **Drag corners** for crop adjustment
- **Long-press + drag** to reorder pages in review
- **Swipe left** on home screen cards to delete (with undo snackbar)

### Feedback
- Haptic feedback on capture
- Brief success animation on save
- Progress bar for PDF/OCR processing
- Snackbar with "Undo" for destructive actions (delete)

### Loading States
- Skeleton cards on home screen while loading
- Shimmer on thumbnails while processing
- Circular progress on export with "Processing page X of Y"

## Accessibility
- All icons have semantic labels
- Minimum touch target: 48x48dp
- Contrast ratios meet WCAG AA
- Screen reader support for all interactive elements
