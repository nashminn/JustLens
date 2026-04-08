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

  void clear() => state = {};
}

final editSessionProvider =
    NotifierProvider<EditSessionNotifier, Map<int, EditParamsHistory>>(
  EditSessionNotifier.new,
);
