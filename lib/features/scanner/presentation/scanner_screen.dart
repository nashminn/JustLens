import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:justlens/features/scanner/providers/scan_session_provider.dart';
import 'package:justlens/features/scanner/services/camera_service.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
  final _camera = CameraNotifier();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _camera.addListener(() {
      if (mounted) setState(() {});
    });
    _camera.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanSessionProvider.notifier).clear();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_camera.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _camera.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _camera.initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _camera.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    final file = await _camera.takePicture();
    if (file != null && mounted) {
      ref.read(scanSessionProvider.notifier).addPage(file.path);
    }

    if (mounted) setState(() => _isCapturing = false);
  }

  Future<void> _importFromGallery() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 90);
    if (files.isEmpty || !mounted) return;
    for (final file in files) {
      ref.read(scanSessionProvider.notifier).addPage(file.path);
    }
    if (mounted) context.push('/review');
  }

  void _onDone() => context.push('/review');

  void _onClose() {
    final pages = ref.read(scanSessionProvider);
    if (pages.isEmpty) {
      context.pop();
      return;
    }
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard scan?'),
        content: const Text('All captured pages will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        ref.read(scanSessionProvider.notifier).clear();
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(scanSessionProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera viewfinder
            if (_camera.isInitialized)
              Positioned.fill(
                child: CameraPreview(_camera.controller!),
              )
            else if (_camera.error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Camera unavailable:\n${_camera.error}',
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                flashMode: _camera.flashMode,
                hasMultipleCameras: _camera.hasMultipleCameras,
                onClose: _onClose,
                onCycleFlash: () => _camera.cycleFlash(),
                onSwitchCamera: () => _camera.switchCamera(),
              ),
            ),

            // Bottom bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomBar(
                pageCount: pages.length,
                isCapturing: _isCapturing,
                onCapture: _capture,
                onGallery: _importFromGallery,
                onDone: _onDone,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.flashMode,
    required this.hasMultipleCameras,
    required this.onClose,
    required this.onCycleFlash,
    required this.onSwitchCamera,
  });

  final FlashMode flashMode;
  final bool hasMultipleCameras;
  final VoidCallback onClose;
  final VoidCallback onCycleFlash;
  final VoidCallback onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close',
            onPressed: onClose,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(_flashIcon(flashMode), color: Colors.white),
            tooltip: 'Flash: ${flashMode.name}',
            onPressed: onCycleFlash,
          ),
          if (hasMultipleCameras)
            IconButton(
              icon: const Icon(Icons.flip_camera_android, color: Colors.white),
              tooltip: 'Switch camera',
              onPressed: onSwitchCamera,
            ),
        ],
      ),
    );
  }

  IconData _flashIcon(FlashMode mode) => switch (mode) {
        FlashMode.off => Icons.flash_off,
        FlashMode.auto => Icons.flash_auto,
        FlashMode.always => Icons.flash_on,
        _ => Icons.flash_off,
      };
}

// ── Bottom bar ─────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.pageCount,
    required this.isCapturing,
    required this.onCapture,
    required this.onGallery,
    required this.onDone,
  });

  final int pageCount;
  final bool isCapturing;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black54, Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Gallery import
          _CircleButton(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            onTap: onGallery,
          ),

          // Capture button
          GestureDetector(
            onTap: isCapturing ? null : onCapture,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCapturing ? Colors.white54 : Colors.white,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: isCapturing
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : null,
            ),
          ),

          // Done — visible once at least one page captured
          if (pageCount > 0)
            _CircleButton(
              icon: Icons.check,
              label: '$pageCount',
              onTap: onDone,
              highlighted: true,
            )
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlighted
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
