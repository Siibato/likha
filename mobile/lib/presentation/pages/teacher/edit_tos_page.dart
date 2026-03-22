import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/domain/tos/entities/tos_entity.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/teacher/widgets/classification_mode_toggle.dart';
import 'package:likha/presentation/providers/tos_provider.dart';

class EditTosPage extends ConsumerStatefulWidget {
  final TableOfSpecifications tos;

  const EditTosPage({super.key, required this.tos});

  @override
  ConsumerState<EditTosPage> createState() => _EditTosPageState();
}

class _EditTosPageState extends ConsumerState<EditTosPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _totalItemsController;
  late int _selectedQuarter;
  late String _classificationMode;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.tos.title);
    _totalItemsController =
        TextEditingController(text: '${widget.tos.totalItems}');
    _selectedQuarter = widget.tos.quarter;
    _classificationMode = widget.tos.classificationMode;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _totalItemsController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(tosProvider.notifier).updateTos(
      widget.tos.id,
      {
        'title': _titleController.text.trim(),
        'quarter': _selectedQuarter,
        'classification_mode': _classificationMode,
        'total_items': int.tryParse(_totalItemsController.text.trim()) ?? 50,
      },
    );

    if (mounted) {
      final state = ref.read(tosProvider);
      if (state.successMessage != null) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tosProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const ClassSectionHeader(
              title: 'Edit TOS',
              showBackButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.error != null)
                        FormMessage(
                          message: state.error,
                          severity: MessageSeverity.error,
                        ),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _titleController,
                        label: 'TOS Title',
                        icon: Icons.description_outlined,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: DropdownButtonFormField<int>(
                          value: _selectedQuarter,
                          decoration: const InputDecoration(
                            labelText: 'Quarter',
                            prefixIcon: Icon(Icons.calendar_month_outlined,
                                color: Color(0xFF999999), size: 20),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          items: [1, 2, 3, 4]
                              .map((q) => DropdownMenuItem(
                                    value: q,
                                    child: Text('Quarter $q'),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedQuarter = v);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _totalItemsController,
                        label: 'Total Items',
                        icon: Icons.tag_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (int.tryParse(v.trim()) == null) return 'Enter a number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ClassificationModeToggle(
                        value: _classificationMode,
                        onChanged: (v) =>
                            setState(() => _classificationMode = v),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: state.isLoading ? null : _handleSave,
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
                                  'Save Changes',
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
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF999999), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(fontSize: 15, color: Color(0xFF2B2B2B)),
      ),
    );
  }
}
