import 'package:justlens/features/editor/models/edit_params.dart';

/// Immutable undo/redo history for one page's edit parameters.
///
/// The history is a list of snapshots; [_cursor] points to the
/// currently active one. Pushing a new state truncates any redo
/// states ahead of the cursor.
class EditParamsHistory {
  EditParamsHistory._({
    required List<EditParams> history,
    required int cursor,
  })  : _history = List.unmodifiable(history),
        _cursor = cursor;

  factory EditParamsHistory.initial([EditParams? params]) => EditParamsHistory._(
        history: [params ?? const EditParams()],
        cursor: 0,
      );

  final List<EditParams> _history;
  final int _cursor;

  EditParams get current => _history[_cursor];
  bool get canUndo => _cursor > 0;
  bool get canRedo => _cursor < _history.length - 1;

  EditParamsHistory push(EditParams params) {
    final truncated = _history.sublist(0, _cursor + 1);
    return EditParamsHistory._(
      history: [...truncated, params],
      cursor: _cursor + 1,
    );
  }

  EditParamsHistory undo() {
    if (!canUndo) return this;
    return EditParamsHistory._(history: _history, cursor: _cursor - 1);
  }

  EditParamsHistory redo() {
    if (!canRedo) return this;
    return EditParamsHistory._(history: _history, cursor: _cursor + 1);
  }
}
