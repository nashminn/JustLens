import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:justlens/features/editor/models/edit_params.dart';

/// Arguments passed to the isolate via [compute].
class ProcessImageArgs {
  const ProcessImageArgs({
    required this.sourcePath,
    required this.params,
    required this.maxWidth,
    this.applyRotation = false,
  });

  final String sourcePath;
  final EditParams params;

  /// Downscale so the longest edge ≤ [maxWidth].
  /// Use 0 for full-resolution (export).
  final int maxWidth;

  /// Whether to bake rotation into the output pixels.
  /// For preview this is false (rotation applied via Transform.rotate widget);
  /// for export this is true.
  final bool applyRotation;
}

/// Top-level function — required by [compute] to run in an isolate.
Uint8List processImageIsolate(ProcessImageArgs args) {
  final bytes = File(args.sourcePath).readAsBytesSync();
  img.Image src = img.decodeImage(bytes)!;

  // Downscale for preview
  if (args.maxWidth > 0 && src.width > args.maxWidth) {
    src = img.copyResize(src, width: args.maxWidth);
  }

  // Filter
  src = _applyFilter(src, args.params.filter);

  // Brightness / contrast (skip if neutral to save CPU)
  if (args.params.brightness != 0.0 || args.params.contrast != 0.0) {
    // image v4: brightness/contrast multipliers — 1.0 = no change.
    // Map user range −1..1 → 0.5..1.5 for a natural document feel.
    src = img.adjustColor(
      src,
      brightness: 1.0 + args.params.brightness * 0.5,
      contrast: 1.0 + args.params.contrast * 0.5,
    );
  }

  // Rotation (export only; preview uses Transform.rotate widget)
  if (args.applyRotation && args.params.rotation != 0.0) {
    src = img.copyRotate(src, angle: args.params.rotation);
  }

  return img.encodeJpg(src, quality: 88);
}

img.Image _applyFilter(img.Image src, FilterPreset filter) {
  switch (filter) {
    case FilterPreset.original:
      return src;
    case FilterPreset.grayscale:
      return img.grayscale(src);
    case FilterPreset.bw:
      // Grayscale + extreme contrast → near-binary black and white
      final gray = img.grayscale(src);
      return img.adjustColor(gray, contrast: 3.5);
    case FilterPreset.sharp:
      // 3×3 unsharp / sharpen kernel
      return img.convolution(
        src,
        filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
      );
  }
}

/// Convenience wrapper — runs [processImageIsolate] off the main thread.
Future<Uint8List> processImage(ProcessImageArgs args) =>
    compute(processImageIsolate, args);
