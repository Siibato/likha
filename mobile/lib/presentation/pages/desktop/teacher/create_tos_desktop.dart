import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/desktop/teacher/tos_detail_desktop.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/teacher/widgets/classification_mode_toggle.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

class CreateTosDesktop extends ConsumerStatefulWidget {
  final String classId;

  const CreateTosDesktop({super.key, required this.classId});

  @override
  ConsumerState<CreateTosDesktop> createState() => _CreateTosDesktopState();
}

class _CreateTosDesktopState extends ConsumerState<CreateTosDesktop> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _totalItemsController = TextEditingController(text: '50');
  int? _selectedQuarter;
  String _classificationMode = 'blooms';

  @override
  void dispose() {
    _titleController.dispose();
    _totalItemsController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedQuarter == null) return;

    final tos = await ref.read(tosProvider.notifier).createTos(
      widget.classId,
      {
        'title': _titleController.text.trim(),
        'quarter': _selectedQuarter!,
        'classification_mode': _classificationMode,
        'total_items': int.tryParse(_totalItemsController.text.trim()) ?? 50,
      },
    );

    if (mounted && tos != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TosDetailDesktop(
            tosId: tos.id,
            classId: widget.classId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tosProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Create TOS',
        maxWidth: 600,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        body: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.error != null)
                  FormMessage(
                    message: state.error,
                    severity: MessageSeverity.error,
                  ),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'TOS Title',
                    hintText: 'e.g., Q1 Periodical Exam',
                    prefixIcon: Icon(Icons.description_outlined,
                        color: AppColors.foregroundSecondary, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Title is required' : null,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: _selectedQuarter,
                  decoration: const InputDecoration(
                    labelText: 'Quarter',
                    prefixIcon: Icon(Icons.calendar_month_outlined,
                        color: AppColors.foregroundSecondary, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  items: [1, 2, 3, 4]
                      .map((q) => DropdownMenuItem(
                            value: q,
                            child: Text('Quarter $q'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedQuarter = v),
                  validator: (v) => v == null ? 'Select a quarter' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _totalItemsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Items',
                    hintText: '50',
                    prefixIcon: Icon(Icons.tag_outlined,
                        color: AppColors.foregroundSecondary, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (int.tryParse(v.trim()) == null) return 'Enter a number';
                    return null;
                  },
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.foregroundPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                ClassificationModeToggle(
                  value: _classificationMode,
                  onChanged: (v) =>
                      setState(() => _classificationMode = v),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: state.isLoading ? null : _handleCreate,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.foregroundPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                            'Create TOS',
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
      ),
    );
  }
}
