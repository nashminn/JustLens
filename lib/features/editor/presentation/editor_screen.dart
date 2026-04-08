import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:justlens/features/editor/models/edit_params.dart';
import 'package:justlens/features/editor/providers/edit_session_provider.dart';
import 'package:justlens/features/editor/services/image_processor.dart';
import 'package:justlens/features/scanner/providers/scan_session_provider.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, required this.pageIndex});

  final int pageIndex;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  Uint8List? _previewBytes;
  Uint8List? _originalBytes; // unprocessed, for before/after
  final Map<FilterPreset, Uint8List?> _filterThumbs = {};

  bool _showOriginal = false;
  bool _processing = false;
  Timer? _debounce;

  // Local copy of params for smooth slider UI (not committed to provider on
  // every frame — only on release or discrete actions).
  late EditParams _localParams;

  @override
  void initState() {
    super.initState();
    _localParams =
        ref.read(editSessionProvider.notifier).paramsFor(widget.pageIndex);
    _loadOriginal();
    _refreshPreview(immediate: true);
    _buildFilterThumbs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  String get _sourcePath =>
      ref.read(scanSessionProvider)[widget.pageIndex];

  // ── Image loading ────────────────────────────────────────────────────────

  Future<void> _loadOriginal() async {
    final bytes = await processImage(ProcessImageArgs(
      sourcePath: _sourcePath,
      params: const EditParams(),
      maxWidth: 900,
    ));
    if (mounted) setState(() => _originalBytes = bytes);
  }

  Future<void> _buildFilterThumbs() async {
    for (final preset in FilterPreset.values) {
      processImage(ProcessImageArgs(
        sourcePath: _sourcePath,
        params: EditParams(filter: preset),
        maxWidth: 130,
      )).then((bytes) {
        if (mounted) setState(() => _filterThumbs[preset] = bytes);
      });
    }
  }

  void _refreshPreview({bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      _doProcess();
    } else {
      _debounce = Timer(const Duration(milliseconds: 150), _doProcess);
    }
  }

  Future<void> _doProcess() async {
    if (!mounted) return;
    setState(() => _processing = true);
    final bytes = await processImage(ProcessImageArgs(
      sourcePath: _sourcePath,
      params: _localParams,
      maxWidth: 900,
      // Rotation handled by Transform.rotate in preview
    ));
    if (mounted) setState(() {
      _previewBytes = bytes;
      _processing = false;
    });
  }

  // ── Edit actions ─────────────────────────────────────────────────────────

  void _onBrightnessChanged(double v) {
    setState(() => _localParams = _localParams.copyWith(brightness: v));
    _refreshPreview();
  }

  void _onContrastChanged(double v) {
    setState(() => _localParams = _localParams.copyWith(contrast: v));
    _refreshPreview();
  }

  void _onRotationChanged(double v) {
    // Transform.rotate handles this instantly — no reprocess needed.
    setState(() => _localParams = _localParams.copyWith(rotation: v));
  }

  void _onSliderEnd(double _) => _commit();

  void _onRotate90(int direction) {
    var r = _localParams.rotation + direction * 90;
    // Normalise to −180..180 so the free-rotation slider stays in range.
    while (r > 180) r -= 360;
    while (r < -180) r += 360;
    setState(() => _localParams = _localParams.copyWith(rotation: r));
    _commit();
  }

  void _onFilterSelected(FilterPreset filter) {
    setState(() => _localParams = _localParams.copyWith(filter: filter));
    _refreshPreview();
    _commit();
  }

  void _onAutoEnhance() {
    setState(() => _localParams = _localParams.copyWith(
          brightness: 0.05,
          contrast: 0.20,
          filter: FilterPreset.sharp,
        ));
    _refreshPreview();
    _commit();
  }

  /// Push current local params to the undo history.
  void _commit() =>
      ref.read(editSessionProvider.notifier).updatePage(widget.pageIndex, _localParams);

  void _undo() {
    ref.read(editSessionProvider.notifier).undoPage(widget.pageIndex);
    _syncFromProvider();
  }

  void _redo() {
    ref.read(editSessionProvider.notifier).redoPage(widget.pageIndex);
    _syncFromProvider();
  }

  void _syncFromProvider() {
    final params =
        ref.read(editSessionProvider.notifier).paramsFor(widget.pageIndex);
    setState(() => _localParams = params);
    _refreshPreview(immediate: true);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pageCount = ref.watch(scanSessionProvider).length;
    final history = ref.watch(editSessionProvider)[widget.pageIndex];
    final canUndo = history?.canUndo ?? false;
    final canRedo = history?.canRedo ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Page ${widget.pageIndex + 1} of $pageCount'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: canUndo ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: canRedo ? _redo : null,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Done',
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _Preview(
            previewBytes: _showOriginal ? _originalBytes : _previewBytes,
            rotation: _localParams.rotation,
            processing: _processing,
            showingOriginal: _showOriginal,
            onLongPressStart: (_) => setState(() => _showOriginal = true),
            onLongPressEnd: (_) => setState(() => _showOriginal = false),
            onLongPressCancel: () => setState(() => _showOriginal = false),
          )),
          _FilterStrip(
            filterThumbs: _filterThumbs,
            selected: _localParams.filter,
            onSelected: _onFilterSelected,
          ),
          _Controls(
            brightness: _localParams.brightness,
            contrast: _localParams.contrast,
            rotation: _localParams.rotation,
            onBrightnessChanged: _onBrightnessChanged,
            onContrastChanged: _onContrastChanged,
            onRotationChanged: _onRotationChanged,
            onSliderEnd: _onSliderEnd,
            onRotate90: _onRotate90,
            onAutoEnhance: _onAutoEnhance,
          ),
        ],
      ),
    );
  }
}

// ── Preview ──────────────────────────────────────────────────────────────────

class _Preview extends StatelessWidget {
  const _Preview({
    required this.previewBytes,
    required this.rotation,
    required this.processing,
    required this.showingOriginal,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.onLongPressCancel,
  });

  final Uint8List? previewBytes;
  final double rotation;
  final bool processing;
  final bool showingOriginal;
  final void Function(LongPressStartDetails) onLongPressStart;
  final void Function(LongPressEndDetails) onLongPressEnd;
  final VoidCallback onLongPressCancel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      onLongPressCancel: onLongPressCancel,
      child: Stack(
        children: [
          if (previewBytes != null)
            Center(
              child: Transform.rotate(
                angle: rotation * pi / 180,
                child: Image.memory(previewBytes!, fit: BoxFit.contain),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          if (processing)
            const Positioned(
              bottom: 10,
              right: 10,
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white38,
                ),
              ),
            ),
          if (showingOriginal)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Original',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Filter strip ─────────────────────────────────────────────────────────────

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.filterThumbs,
    required this.selected,
    required this.onSelected,
  });

  final Map<FilterPreset, Uint8List?> filterThumbs;
  final FilterPreset selected;
  final ValueChanged<FilterPreset> onSelected;

  static const _labels = {
    FilterPreset.original: 'Original',
    FilterPreset.bw: 'B&W',
    FilterPreset.grayscale: 'Gray',
    FilterPreset.sharp: 'Sharp',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: FilterPreset.values.map((preset) {
          final isSelected = preset == selected;
          final thumb = filterThumbs[preset];
          return GestureDetector(
            onTap: () => onSelected(preset),
            child: Container(
              width: 64,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white24,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5)),
                      child: thumb != null
                          ? Image.memory(thumb, fit: BoxFit.cover,
                              width: double.infinity)
                          : const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      _labels[preset]!,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Controls ─────────────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  const _Controls({
    required this.brightness,
    required this.contrast,
    required this.rotation,
    required this.onBrightnessChanged,
    required this.onContrastChanged,
    required this.onRotationChanged,
    required this.onSliderEnd,
    required this.onRotate90,
    required this.onAutoEnhance,
  });

  final double brightness;
  final double contrast;
  final double rotation;
  final ValueChanged<double> onBrightnessChanged;
  final ValueChanged<double> onContrastChanged;
  final ValueChanged<double> onRotationChanged;
  final ValueChanged<double> onSliderEnd;
  final void Function(int direction) onRotate90;
  final VoidCallback onAutoEnhance;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.rotate_left, color: Colors.white),
                tooltip: 'Rotate 90° left',
                onPressed: () => onRotate90(-1),
              ),
              TextButton.icon(
                onPressed: onAutoEnhance,
                icon: const Icon(Icons.auto_fix_high, color: Colors.amber),
                label: const Text('Auto',
                    style: TextStyle(color: Colors.amber)),
              ),
              IconButton(
                icon: const Icon(Icons.rotate_right, color: Colors.white),
                tooltip: 'Rotate 90° right',
                onPressed: () => onRotate90(1),
              ),
            ],
          ),
          _SliderRow(
            label: 'Brightness',
            value: brightness,
            onChanged: onBrightnessChanged,
            onChangeEnd: onSliderEnd,
          ),
          _SliderRow(
            label: 'Contrast',
            value: contrast,
            onChanged: onContrastChanged,
            onChangeEnd: onSliderEnd,
          ),
          _SliderRow(
            label: 'Rotation',
            value: rotation,
            min: -180,
            max: 180,
            showValue: true,
            suffix: '°',
            onChanged: onRotationChanged,
            onChangeEnd: onSliderEnd,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    this.min = -1.0,
    this.max = 1.0,
    this.showValue = false,
    this.suffix = '',
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final double min;
  final double max;
  final bool showValue;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final displayLabel = showValue
        ? '$label: ${value.toStringAsFixed(0)}$suffix'
        : label;
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            displayLabel,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
              overlayColor: Colors.white24,
              trackHeight: 2,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ),
      ],
    );
  }
}
