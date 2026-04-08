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

  void replacePage(int index, String path) {
    final updated = [...state];
    updated[index] = path;
    state = updated;
  }

  void reorderPages(int oldIndex, int newIndex) {
    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = list;
  }

  void clear() => state = [];
}

final scanSessionProvider =
    NotifierProvider<ScanSessionNotifier, List<String>>(
  ScanSessionNotifier.new,
);
