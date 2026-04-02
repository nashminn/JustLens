import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the list of captured image paths for the current scan session.
class ScanSessionNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void addPage(String path) {
    state = [...state, path];
  }

  void removePage(int index) {
    final updated = [...state];
    updated.removeAt(index);
    state = updated;
  }

  void clear() => state = [];
}

final scanSessionProvider =
    NotifierProvider<ScanSessionNotifier, List<String>>(
  ScanSessionNotifier.new,
);
