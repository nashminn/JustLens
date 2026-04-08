import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:justlens/features/editor/models/edit_params.dart';
import 'package:justlens/features/editor/models/edit_params_history.dart';

class EditSessionNotifier extends Notifier<Map<int, EditParamsHistory>> {
  @override
  Map<int, EditParamsHistory> build() => {};

  EditParams paramsFor(int index) =>
      state[index]?.current ?? const EditParams();

  EditParamsHistory _historyFor(int index) =>
      state[index] ?? EditParamsHistory.initial();

  void updatePage(int index, EditParams params) {
    state = {
      ...state,
      index: _historyFor(index).push(params),
    };
  }

  void undoPage(int index) {
    final h = state[index];
    if (h == null || !h.canUndo) return;
    state = {...state, index: h.undo()};
  }

  void redoPage(int index) {
    final h = state[index];
    if (h == null || !h.canRedo) return;
    state = {...state, index: h.redo()};
  }

  /// Remove edit history for [index] and shift all higher indices down.
  void removePage(int index, int pageCount) {
    final list = List<EditParamsHistory?>.generate(pageCount, (i) => state[i]);
    list.removeAt(index);
    state = _listToMap(list);
  }

  /// Clears the edit history for [index] (used after retake).
  void replacePage(int index) {
    final newState = Map<int, EditParamsHistory>.from(state)..remove(index);
    state = newState;
  }

  /// Reorder edit histories to match a page reorder operation.
  void reorderPages(int oldIndex, int newIndex, int pageCount) {
    final list = List<EditParamsHistory?>.generate(pageCount, (i) => state[i]);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = _listToMap(list);
  }

  /// Propagate [sourceIndex]'s filter and/or adjustments to all other pages.
  void applyToAll(
    int sourceIndex,
    int pageCount, {
    bool applyFilter = false,
    bool applyAdjustments = false,
  }) {
    final source = paramsFor(sourceIndex);
    final newState = Map<int, EditParamsHistory>.from(state);
    for (var i = 0; i < pageCount; i++) {
      if (i == sourceIndex) continue;
      final current = paramsFor(i);
      final updated = current.copyWith(
        filter: applyFilter ? source.filter : null,
        brightness: applyAdjustments ? source.brightness : null,
        contrast: applyAdjustments ? source.contrast : null,
      );
      newState[i] = _historyFor(i).push(updated);
    }
    state = newState;
  }

  void clear() => state = {};

  static Map<int, EditParamsHistory> _listToMap(
      List<EditParamsHistory?> list) {
    final map = <int, EditParamsHistory>{};
    for (var i = 0; i < list.length; i++) {
      if (list[i] != null) map[i] = list[i]!;
    }
    return map;
  }
}

final editSessionProvider =
    NotifierProvider<EditSessionNotifier, Map<int, EditParamsHistory>>(
  EditSessionNotifier.new,
);
