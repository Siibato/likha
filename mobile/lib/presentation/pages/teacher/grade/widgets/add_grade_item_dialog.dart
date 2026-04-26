import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_button.dart';
import 'package:likha/presentation/providers/grading_provider.dart';

const List<String> _componentKeys = ['ww', 'pt', 'qa'];

void showAddGradeItemDialog({
  required BuildContext context,
  required String classId,
  required int selectedQuarter,
  required WidgetRef ref,
}) {
  final titleCtrl = TextEditingController();
  final pointsCtrl = TextEditingController(text: '100');
  String selectedComponent = 'ww';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Grade Item  •  Q$selectedQuarter',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentCharcoal),
            ),
            const SizedBox(height: 16),
            // Component selector
            Row(
              children: [
                for (int i = 0; i < _componentKeys.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setSheet(() => selectedComponent = _componentKeys[i]),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedComponent == _componentKeys[i]
                              ? AppColors.accentCharcoal
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedComponent == _componentKeys[i]
                                ? AppColors.accentCharcoal
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Text(
                          _componentKeys[i].toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selectedComponent == _componentKeys[i]
                                ? Colors.white
                                : AppColors.foregroundSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Quiz 1, Essay, Lab Activity',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide:
                      const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pointsCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Total Points',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide:
                      const BorderSide(color: AppColors.accentCharcoal, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: StyledButton(
                    text: 'Cancel',
                    isLoading: false,
                    variant: StyledButtonVariant.outlined,
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StyledButton(
                    text: 'Add',
                    isLoading: false,
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      final points = int.tryParse(pointsCtrl.text) ?? 100;
                      if (title.isEmpty) return;
                      ref
                          .read(gradeItemsProvider.notifier)
                          .createItem(classId, {
                        'title': title,
                        'component': selectedComponent,
                        'quarter': selectedQuarter,
                        'total_points': points,
                        'source_type': 'manual',
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
