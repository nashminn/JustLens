enum FilterPreset { original, bw, grayscale, sharp }

/// Immutable editing parameters for a single page.
/// All values are stored; originals are never modified.
class EditParams {
  const EditParams({
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.rotation = 0.0,
    this.filter = FilterPreset.original,
  });

  /// −1.0 (darkest) to 1.0 (brightest). 0.0 = no change.
  final double brightness;

  /// −1.0 (flat) to 1.0 (high contrast). 0.0 = no change.
  final double contrast;

  /// Degrees. Any value; normalised to −180..180 by the UI.
  final double rotation;

  final FilterPreset filter;

  bool get isDefault =>
      brightness == 0.0 &&
      contrast == 0.0 &&
      rotation == 0.0 &&
      filter == FilterPreset.original;

  EditParams copyWith({
    double? brightness,
    double? contrast,
    double? rotation,
    FilterPreset? filter,
  }) =>
      EditParams(
        brightness: brightness ?? this.brightness,
        contrast: contrast ?? this.contrast,
        rotation: rotation ?? this.rotation,
        filter: filter ?? this.filter,
      );
}
