import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) throw Exception('No cameras found');
    await _initController(_cameras.first);
  }

  Future<void> _initController(CameraDescription camera) async {
    await _controller?.dispose();
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _controller!.initialize();
  }

  Future<void> setFlashMode(FlashMode mode) async {
    await _controller?.setFlashMode(mode);
  }

  Future<XFile?> takePicture() async {
    if (_controller == null || !isInitialized) return null;
    if (_controller!.value.isTakingPicture) return null;
    return await _controller!.takePicture();
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  bool get hasMultipleCameras => _cameras.length > 1;

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    final current = _controller?.description;
    final next = _cameras.firstWhere(
      (c) => c != current,
      orElse: () => _cameras.first,
    );
    await _initController(next);
  }
}

/// Riverpod-friendly wrapper that notifies listeners on state changes.
class CameraNotifier extends ChangeNotifier {
  final CameraService _service = CameraService();

  CameraController? get controller => _service.controller;
  bool get isInitialized => _service.isInitialized;
  bool get hasMultipleCameras => _service.hasMultipleCameras;

  FlashMode _flashMode = FlashMode.off;
  FlashMode get flashMode => _flashMode;

  String? _error;
  String? get error => _error;

  Future<void> initialize() async {
    try {
      await _service.initialize();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<void> cycleFlash() async {
    _flashMode = switch (_flashMode) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    await _service.setFlashMode(_flashMode);
    notifyListeners();
  }

  Future<XFile?> takePicture() => _service.takePicture();

  Future<void> switchCamera() async {
    await _service.switchCamera();
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _service.dispose();
    super.dispose();
  }
}
