import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/data/models/tos/melcs_model.dart';
import 'package:likha/domain/tos/usecases/search_melcs.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

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

class MelcsSearchDialog extends ConsumerStatefulWidget {
  final String tosId;

  const MelcsSearchDialog({super.key, required this.tosId});

  static Future<void> show(BuildContext context, String tosId) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => MelcsSearchDialog(tosId: tosId),
    );
  }

  @override
  ConsumerState<MelcsSearchDialog> createState() => _MelcsSearchDialogState();
}

class _MelcsSearchDialogState extends ConsumerState<MelcsSearchDialog> {
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

    final competencies = _selectedItems
        .map((m) => {
              'competency_code': m.competencyCode,
              'competency_text': m.competencyText,
              'days_taught': 1,
              'order_index': 0,
            })
        .toList();

    await ref
        .read(tosProvider.notifier)
        .bulkAddCompetencies(widget.tosId, competencies);

    if (mounted) {
      ref.read(tosProvider.notifier).clearMelcResults();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tosProvider);
    final results = state.melcResults;

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 680,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Import from MELCs',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF202020),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Filter by grade and subject, then select competencies to import',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF999999),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      foregroundColor: const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            // ── Search + filters ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE8E8E8)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search competencies...',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 18,
                          color: Color(0xFF999999),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFCCCCCC),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF202020),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter row
                  Row(
                    children: [
                      Expanded(
                        child: _FilterDropdown<String>(
                          hint: 'All Grades',
                          value: _selectedGrade,
                          items: _kGrades,
                          itemLabel: (g) => 'Grade $g',
                          onChanged: (val) {
                            setState(() => _selectedGrade = val);
                            _triggerSearch();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _FilterDropdown<String>(
                          hint: 'All Subjects',
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
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── Results list (styled content area) ───────────────────
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: state.isMelcSearching
                      ? const SizedBox(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2B2B2B),
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : results.isEmpty
                          ? const SizedBox(
                              height: 200,
                              child: Center(
                                child: Text(
                                  'No competencies found',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF999999),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: _scrollController,
                              shrinkWrap: true,
                              itemCount: results.length + 1,
                              separatorBuilder: (_, index) => index < results.length - 1
                                  ? const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFEEEEEE),
                                      indent: 16,
                                      endIndent: 16,
                                    )
                                  : const SizedBox.shrink(),
                              itemBuilder: (context, index) {
                                if (index == results.length) {
                                  return _MelcListFooter(
                                    isLoadingMore: state.isLoadingMore,
                                    hasMore: state.melcHasMore,
                                  );
                                }
                                final melc = results[index];
                                final isSelected = _selectedItems.contains(melc);
                                return InkWell(
                                  onTap: () => setState(() {
                                    if (isSelected) {
                                      _selectedItems.remove(melc);
                                    } else {
                                      _selectedItems.add(melc);
                                    }
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (checked) => setState(() {
                                              if (checked == true) {
                                                _selectedItems.add(melc);
                                              } else {
                                                _selectedItems.remove(melc);
                                              }
                                            }),
                                            activeColor: const Color(0xFF2B2B2B),
                                            side: const BorderSide(
                                              color: Color(0xFFCCCCCC),
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                melc.competencyCode,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF202020),
                                                  letterSpacing: -0.1,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                melc.competencyText,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF666666),
                                                  height: 1.4,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEEEEEE),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'G${melc.gradeLevel}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF666666),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ── Divider ───────────────────────────────────────────────
            Container(
              height: 1,
              color: const Color(0xFFEEEEEE),
              margin: const EdgeInsets.symmetric(horizontal: 24),
            ),
            // ── Footer ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  if (_selectedItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '${_selectedItems.length} selected',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _selectedItems.isEmpty || state.isLoading
                        ? null
                        : _handleImport,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2B2B2B),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      disabledForegroundColor: const Color(0xFF999999),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _selectedItems.isEmpty
                          ? 'Import'
                          : 'Import ${_selectedItems.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MelcListFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;

  const _MelcListFooter({required this.isLoadingMore, required this.hasMore});

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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
          isExpanded: true,
          iconSize: 16,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF999999)),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF202020),
            fontWeight: FontWeight.w500,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(10),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text(
                hint,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
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
