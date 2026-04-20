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

const _kGrades = ['7', '8', '9', '10', '11', '12'];
const _kSubjects = [
  'Mathematics',
  'Science',
  'English',
  'Araling Panlipunan',
  'Edukasyon sa Pagpapakatao',
  'Filipino',
  'General Mathematics',
  'Statistics and Probability',
  'Earth and Life Science',
  'Physical Science',
  'Oral Communication',
  'Reading and Writing',
  '21st Century Literature',
  'Media and Information Literacy',
];

class _MelcsSearchSheetState extends ConsumerState<MelcsSearchSheet> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _selectedItems = <MelcEntryModel>{};
  Timer? _debounce;
  String? _selectedGrade;
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerSearch();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(tosProvider.notifier).loadMoreMelcs();
    }
  }

  void _triggerSearch() {
    ref.read(tosProvider.notifier).searchMelcs(SearchMelcsParams(
          query: _searchController.text.trim(),
          gradeLevel: _selectedGrade,
          subject: _selectedSubject,
        ));
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _triggerSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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
            // Filter chips row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _FilterDropdown<String>(
                      hint: 'Grade',
                      value: _selectedGrade,
                      items: _kGrades,
                      itemLabel: (g) => 'Grade $g',
                      onChanged: (val) {
                        setState(() => _selectedGrade = val);
                        _triggerSearch();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterDropdown<String>(
                      hint: 'Subject',
                      value: _selectedSubject,
                      items: _kSubjects,
                      itemLabel: (s) => s,
                      onChanged: (val) {
                        setState(() => _selectedSubject = val);
                        _triggerSearch();
                      },
                    ),
                  ),
                ],
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
                          controller: _scrollController,
                          itemCount: results.length + 1,
                          itemBuilder: (context, index) {
                            if (index == results.length) {
                              return _SheetListFooter(
                                isLoadingMore: state.isLoadingMore,
                                hasMore: state.melcHasMore,
                              );
                            }
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

class _SheetListFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;

  const _SheetListFooter({required this.isLoadingMore, required this.hasMore});

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF999999),
            ),
          ),
        ),
      );
    }
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Text(
            'All results loaded',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFCCCCCC),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
          isExpanded: true,
          iconSize: 18,
          style: const TextStyle(fontSize: 13, color: Color(0xFF2B2B2B)),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text('All $hint', style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
            ),
            ...items.map((item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
