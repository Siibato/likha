import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/admin/widgets/styled_button.dart';
import 'package:likha/presentation/pages/admin/widgets/styled_dropdown.dart';
import 'package:likha/presentation/pages/admin/widgets/styled_text_field.dart';
import 'package:likha/presentation/providers/admin_provider.dart';
import 'package:likha/presentation/providers/class_provider.dart';

class AdminCreateClassPage extends ConsumerStatefulWidget {
  const AdminCreateClassPage({super.key});

  @override
  ConsumerState<AdminCreateClassPage> createState() => _AdminCreateClassPageState();
}

class _AdminCreateClassPageState extends ConsumerState<AdminCreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedTeacherId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadAccounts();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacherId == null || _selectedTeacherId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a teacher'),
          backgroundColor: Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final adminState = ref.read(adminProvider);
    final teachers = adminState.accounts.where((u) => u.isTeacher).toList();
    final selectedTeacher = teachers.firstWhere((t) => t.id == _selectedTeacherId!);

    await ref.read(classProvider.notifier).createClass(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          teacherId: _selectedTeacherId,
          teacherUsername: selectedTeacher.username,
          teacherFullName: selectedTeacher.fullName,
        );

    if (mounted) {
      final state = ref.read(classProvider);
      if (state.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.pop(context);
      } else if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: const Color(0xFFEF5350),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final classState = ref.watch(classProvider);

    // Filter teachers (include pending activation status)
    final teachers = adminState.accounts.where((u) => u.isTeacher).toList();

    // If no teachers, show empty state
    if (teachers.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Create Class',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2B2B2B),
              letterSpacing: -0.4,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_outline_rounded, size: 64, color: Color(0xFFCCCCCC)),
                SizedBox(height: 16),
                Text(
                  'No teachers available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2B2B2B),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create teacher accounts before creating classes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF999999),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Class',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StyledTextField(
                  controller: _titleController,
                  label: 'Class Title',
                  icon: Icons.class_outlined,
                  enabled: !classState.isLoading,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Class title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                StyledTextField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  icon: Icons.description_outlined,
                  enabled: !classState.isLoading,
                  validator: null,
                ),
                const SizedBox(height: 16),
                StyledDropdown<String?>(
                  value: _selectedTeacherId,
                  label: 'Assign Teacher',
                  icon: Icons.person_outline_rounded,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Select a teacher'),
                      enabled: false,
                    ),
                    ...teachers
                        .map(
                          (teacher) => DropdownMenuItem<String?>(
                            value: teacher.id,
                            child: Text(
                              '${teacher.fullName} (@${teacher.username})',
                            ),
                          ),
                        )
                        .toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTeacherId = value;
                    });
                  },
                  enabled: !classState.isLoading,
                ),
                const SizedBox(height: 32),
                StyledButton(
                  text: 'Create Class',
                  isLoading: classState.isLoading,
                  onPressed: _handleCreate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
