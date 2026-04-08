import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:justlens/features/editor/providers/edit_session_provider.dart';
import 'package:justlens/features/scanner/providers/scan_session_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  bool _selectMode = false;
  final Set<int> _selected = {};

  void _enterSelectMode(int index) {
    setState(() {
      _selectMode = true;
      _selected.add(index);
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selectMode = false;
      _selected.clear();
    });
  }

  void _toggleSelect(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
        if (_selected.isEmpty) _exitSelectMode();
      } else {
        _selected.add(index);
      }
    });
  }

  void _deleteSelected() {
    final pages = ref.read(scanSessionProvider);
    // Remove in descending order so indices don't shift during deletion.
    final sorted = _selected.toList()..sort((a, b) => b.compareTo(a));
    for (final index in sorted) {
      ref.read(scanSessionProvider.notifier).removePage(index);
      ref.read(editSessionProvider.notifier).removePage(index, pages.length);
    }
    _exitSelectMode();
  }

  void _deleteSingle(int index) {
    final pages = ref.read(scanSessionProvider);
    ref.read(scanSessionProvider.notifier).removePage(index);
    ref.read(editSessionProvider.notifier).removePage(index, pages.length);
  }

  void _retakePage(int index) {
    context.push('/scanner', extra: {'retake': index});
  }

  void _addMorePages() {
    context.push('/scanner');
  }

  void _onReorder(int oldIndex, int newIndex) {
    final pages = ref.read(scanSessionProvider);
    // ReorderableListView passes newIndex after removal; adjust for insert.
    if (oldIndex < newIndex) newIndex -= 1;
    ref.read(scanSessionProvider.notifier).reorderPages(oldIndex, newIndex);
    ref.read(editSessionProvider.notifier)
        .reorderPages(oldIndex, newIndex, pages.length);
    // Update selection indices to follow the moved item.
    setState(() {
      if (_selected.contains(oldIndex)) {
        _selected.remove(oldIndex);
        _selected.add(newIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = ref.watch(scanSessionProvider);

    return Scaffold(
      appBar: _selectMode
          ? _SelectAppBar(
              count: _selected.length,
              onDelete: _selected.isNotEmpty ? _deleteSelected : null,
              onExit: _exitSelectMode,
            )
          : _NormalAppBar(
              pageCount: pages.length,
              onAddMore: _addMorePages,
            ),
      body: pages.isEmpty
          ? _EmptyState(onAddMore: _addMorePages)
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              itemCount: pages.length,
              buildDefaultDragHandles: false,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final isSelected = _selected.contains(index);
                return _PageCard(
                  key: ValueKey(pages[index]),
                  index: index,
                  path: pages[index],
                  selectMode: _selectMode,
                  isSelected: isSelected,
                  onTap: _selectMode
                      ? () => _toggleSelect(index)
                      : () => context.push('/editor/$index'),
                  onLongPress: _selectMode ? null : () => _enterSelectMode(index),
                  onRetake: () => _retakePage(index),
                  onDelete: () => _deleteSingle(index),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: pages.isEmpty ? null : () {
                  // TODO: Quick save in Phase 5a
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: pages.isEmpty ? null : () {
                  // TODO: Full export in Phase 5b
                },
                icon: const Icon(Icons.upload_outlined),
                label: const Text('Export'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AppBars ───────────────────────────────────────────────────────────────────

class _NormalAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _NormalAppBar({required this.pageCount, required this.onAddMore});
  final int pageCount;
  final VoidCallback onAddMore;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        title: Text('Review ($pageCount page${pageCount == 1 ? '' : 's'})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            tooltip: 'Add more pages',
            onPressed: onAddMore,
          ),
        ],
      );
}

class _SelectAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _SelectAppBar({
    required this.count,
    required this.onDelete,
    required this.onExit,
  });
  final int count;
  final VoidCallback? onDelete;
  final VoidCallback onExit;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel selection',
          onPressed: onExit,
        ),
        title: Text('$count selected'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete selected',
            onPressed: onDelete,
          ),
        ],
      );
}

// ── Page card ─────────────────────────────────────────────────────────────────

class _PageCard extends StatelessWidget {
  const _PageCard({
    required super.key,
    required this.index,
    required this.path,
    required this.selectMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onRetake,
    required this.onDelete,
  });

  final int index;
  final String path;
  final bool selectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onRetake;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          height: 120,
          child: Row(
            children: [
              // Thumbnail
              Stack(
                children: [
                  SizedBox(
                    width: 90,
                    height: 120,
                    child: Image.file(
                      File(path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (selectMode)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.black38,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Page ${index + 1}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: onRetake,
                            icon: const Icon(Icons.camera_alt_outlined,
                                size: 16),
                            label: const Text('Retake',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 18,
                                color: colorScheme.error),
                            tooltip: 'Delete page',
                            onPressed: onDelete,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Drag handle
              if (!selectMode)
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.drag_handle, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddMore});
  final VoidCallback onAddMore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('No pages'),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAddMore,
            icon: const Icon(Icons.add),
            label: const Text('Add pages'),
          ),
        ],
      ),
    );
  }
}
