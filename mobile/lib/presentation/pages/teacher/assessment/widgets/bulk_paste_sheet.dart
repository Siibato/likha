import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

class BulkPasteSheet extends ConsumerStatefulWidget {
  final String tosId;

  const BulkPasteSheet({super.key, required this.tosId});

  static Future<void> show(BuildContext context, String tosId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BulkPasteSheet(tosId: tosId),
    );
  }

  @override
  ConsumerState<BulkPasteSheet> createState() => _BulkPasteSheetState();
}

class _BulkPasteSheetState extends ConsumerState<BulkPasteSheet> {
  final _pasteController = TextEditingController();

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _parse() {
    final lines = _pasteController.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    return lines.asMap().entries.map((entry) {
      final line = entry.value;
      final parts = line.split('|').map((p) => p.trim()).toList();

      if (parts.length >= 3) {
        return {
          'competency_code': parts[0],
          'competency_text': parts[1],
          'days_taught': int.tryParse(parts[2]) ?? 1,
          'order_index': entry.key,
        };
      } else if (parts.length == 2) {
        return {
          'competency_code': parts[0],
          'competency_text': parts[1],
          'days_taught': 1,
          'order_index': entry.key,
        };
      }
      return {
        'competency_text': line,
        'days_taught': 1,
        'order_index': entry.key,
      };
    }).toList();
  }

  Future<void> _handleImport() async {
    final parsed = _parse();
    if (parsed.isEmpty) return;

    await ref.read(tosProvider.notifier).bulkAddCompetencies(
          widget.tosId,
          parsed,
        );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tosProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Bulk Paste Competencies',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Paste one competency per line.\nOptional format: CODE | Text | Days',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    controller: _pasteController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Paste competencies here...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFFCCCCCC)),
                    ),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF2B2B2B)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
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
                  child: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Import',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
