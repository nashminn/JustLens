import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:justlens/features/editor/providers/edit_session_provider.dart';
import 'package:justlens/features/scanner/providers/scan_session_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key, this.galleryMode = false});

  final bool galleryMode;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  DocumentScanner? _scanner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scanSessionProvider.notifier).clear();
      ref.read(editSessionProvider.notifier).clear();
      _startScan();
    });
  }

  @override
  void dispose() {
    _scanner?.close();
    super.dispose();
  }

  Future<void> _startScan() async {
    _scanner = DocumentScanner(
      options: DocumentScannerOptions(
        documentFormat: DocumentFormat.jpeg,
        mode: ScannerMode.full,
        isGalleryImport: widget.galleryMode,
        pageLimit: 100, // effectively uncapped
      ),
    );

    try {
      final result = await _scanner!.scanDocument();
      if (!mounted) return;

      for (final path in result.images) {
        ref.read(scanSessionProvider.notifier).addPage(path);
      }

      if (result.images.isNotEmpty) {
        context.pushReplacement('/review');
      } else {
        // User cancelled without accepting any pages
        context.pop();
      }
    } on PlatformException catch (e) {
      if (!mounted) return;

      // Code 'canceled' means the user dismissed the ML Kit Activity
      if (e.code == 'canceled') {
        context.pop();
        return;
      }

      // Play Services unavailable or other hard failure
      final message = e.code == 'google-play-services-not-available'
          ? 'Google Play Services is required for document scanning but is not available on this device.'
          : 'Scanning failed: ${e.message ?? 'unknown error'}';

      _showError(message);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      _showError('Scanning failed. Please try again.');
      context.pop();
    } finally {
      await _scanner?.close();
      _scanner = null;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Transparent launcher — visible only briefly while ML Kit Activity opens.
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
