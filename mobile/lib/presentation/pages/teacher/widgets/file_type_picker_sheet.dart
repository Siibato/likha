import 'package:flutter/material.dart';
import 'package:likha/core/constants/file_types.dart';

class FileTypePickerSheet extends StatefulWidget {
  final Set<String> initialSelection;

  const FileTypePickerSheet({
    super.key,
    required this.initialSelection,
  });

  @override
  State<FileTypePickerSheet> createState() => _FileTypePickerSheetState();
}

class _FileTypePickerSheetState extends State<FileTypePickerSheet> {
  late Set<String> _tempSelection;

  @override
  void initState() {
    super.initState();
    _tempSelection = Set.from(widget.initialSelection);
  }

  /// Get category selection state based on tempSelection
  int _getCategoryState(FileTypeCategory category) {
    final selectedCount = category.types
        .where((type) => _tempSelection.contains(type))
        .length;
    if (selectedCount == 0) return 0;
    if (selectedCount == category.types.length) return 2;
    return 1;
  }

  /// Toggle category in temp selection
  void _toggleCategory(FileTypeCategory category) {
    final state = _getCategoryState(category);
    if (state == 2) {
      // All selected → deselect all
      for (final type in category.types) {
        _tempSelection.remove(type);
      }
    } else {
      // None or partial → select all
      for (final type in category.types) {
        _tempSelection.add(type);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Allowed File Types',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  for (final category in kFileTypeCategories) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 16, bottom: 12),
                      decoration: BoxDecoration(
                        color: _getCategoryState(category) > 0
                            ? const Color(0xFF2B2B2B).withValues(alpha: 0.05)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getCategoryState(category) > 0
                              ? const Color(0xFF2B2B2B).withValues(alpha: 0.2)
                              : Colors.transparent,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _getCategoryState(category) == 2
                                  ? true
                                  : _getCategoryState(category) == 1
                                      ? null
                                      : false,
                              tristate: true,
                              onChanged: (_) => _toggleCategory(category),
                              activeColor: const Color(0xFF2B2B2B),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                category.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _getCategoryState(category) > 0
                                      ? const Color(0xFF2B2B2B)
                                      : const Color(0xFF666666),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in category.types)
                          FilterChip(
                            label: Text(type),
                            selected: _tempSelection.contains(type),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _tempSelection.add(type);
                                } else {
                                  _tempSelection.remove(type);
                                }
                              });
                            },
                            selectedColor: const Color(0xFF2B2B2B),
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _tempSelection.contains(type)
                                  ? Colors.white
                                  : const Color(0xFF2B2B2B),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: _tempSelection.contains(type)
                                    ? const Color(0xFF2B2B2B)
                                    : const Color(0xFFE0E0E0),
                              ),
                            ),
                            backgroundColor: Colors.white,
                            showCheckmark: false,
                          ),
                      ],
                    ),
                    if (category != kFileTypeCategories.last)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _tempSelection),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B2B2B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
