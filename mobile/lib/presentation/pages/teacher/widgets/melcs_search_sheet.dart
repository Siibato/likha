import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import 'package:likha/domain/tos/usecases/search_melcs.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

class MelcsSearchSheet extends ConsumerStatefulWidget {
  final String tosId;

  const MelcsSearchSheet({super.key, required this.tosId});

  static Future<void> show(BuildContext context, String tosId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MelcsSearchSheet(tosId: tosId),
    );
  }

  @override
  ConsumerState<MelcsSearchSheet> createState() => _MelcsSearchSheetState();
}

class _MelcsSearchSheetState extends ConsumerState<MelcsSearchSheet> {
  final _searchController = TextEditingController();
  final _selectedItems = <MelcEntryModel>{};
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Initial search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tosProvider.notifier).searchMelcs(SearchMelcsParams());
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(tosProvider.notifier).searchMelcs(
            SearchMelcsParams(query: _searchController.text.trim()),
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _handleImport() async {
    if (_selectedItems.isEmpty) return;

    final competencies = _selectedItems.map((m) => {
          'competency_code': m.competencyCode,
          'competency_text': m.competencyText,
          'days_taught': 1,
          'order_index': 0,
        }).toList();

    await ref.read(tosProvider.notifier).bulkAddCompetencies(
          widget.tosId,
          competencies,
        );

    if (mounted) {
      ref.read(tosProvider.notifier).clearMelcResults();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tosProvider);
    final results = state.melcResults;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Import from MELCs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                ),
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search competencies...',
                    prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF999999)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    hintStyle: TextStyle(fontSize: 14, color: Color(0xFFCCCCCC)),
                  ),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF2B2B2B)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Results
            Expanded(
              child: state.isMelcSearching
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2B2B2B),
                        strokeWidth: 2.5,
                      ),
                    )
                  : results.isEmpty
                      ? const Center(
                          child: Text(
                            'No competencies found',
                            style: TextStyle(color: Color(0xFF999999)),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final melc = results[index];
                            final isSelected = _selectedItems.contains(melc);
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedItems.add(melc);
                                  } else {
                                    _selectedItems.remove(melc);
                                  }
                                });
                              },
                              title: Text(
                                melc.competencyCode,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2B2B2B),
                                ),
                              ),
                              subtitle: Text(
                                melc.competencyText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF666666),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              activeColor: const Color(0xFF2B2B2B),
                              controlAffinity: ListTileControlAffinity.leading,
                              dense: true,
                            );
                          },
                        ),
            ),
            // Import button
            if (_selectedItems.isNotEmpty)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _handleImport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B2B2B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Import ${_selectedItems.length} Competencies',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
