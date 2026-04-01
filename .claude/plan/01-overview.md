# JustLens — Project Overview

## What
A cross-platform mobile document scanning app built with Flutter. Android first, iOS later.

## Core Value Proposition
Simple, elegant, no-bloat document scanner that does one thing well: scan documents, make them look good, and export them as images or searchable PDFs.

## Target
- Android 7.0+ (API 24) initially
- iOS extension planned for later (Flutter makes this straightforward)

## High-Level Workflow
1. User opens app → sees recent scans + prominent "Scan" button
2. Camera opens → user captures single page or multiple pages (batch)
3. Each capture gets auto-edge-detection + manual crop/perspective correction
4. User adjusts lighting/contrast (auto-enhance + manual controls)
5. Flash toggle available during capture
6. Preview all scanned pages → reorder, delete, retake individual pages
7. Export selected pages as individual images or as a single PDF
8. PDF export includes OCR (text-searchable)
9. User picks save location: app storage or device shared storage (Downloads/Documents)
10. No ads (may revisit later)

## Non-Goals (for v1)
- Cloud sync / backup
- Sharing directly to other apps (can add later)
- Annotation / signing
- Multi-language OCR (start with English, extend later)
- iOS build (architecture supports it, just not targeting yet)
