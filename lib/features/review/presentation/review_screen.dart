import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:justlens/features/scanner/providers/scan_session_provider.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = ref.watch(scanSessionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Review (${pages.length} page${pages.length == 1 ? '' : 's'})'),
      ),
      body: pages.isEmpty
          ? const Center(child: Text('No pages captured'))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(pages[index]),
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  // TODO: Quick save in Phase 5a
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
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
