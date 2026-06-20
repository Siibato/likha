import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/desktop/teacher/shared/empty_state.dart';
import 'package:likha/presentation/providers/student_records_provider.dart';
import 'package:likha/domain/classes/entities/class_detail.dart';
import 'package:likha/presentation/widgets/desktop/teacher/student_records/skeletons/learner_details_skeleton.dart';

class LearnerDetailsSection extends ConsumerStatefulWidget {
  final String classId;
  final List<Participant> students;

  const LearnerDetailsSection({
    super.key,
    required this.classId,
    required this.students,
  });

  @override
  ConsumerState<LearnerDetailsSection> createState() => _LearnerDetailsSectionState();
}

class _LearnerDetailsSectionState extends ConsumerState<LearnerDetailsSection> {
  String? _selectedStudentId;
  String? _selectedStudentName;

  @override
  Widget build(BuildContext context) {
    if (widget.students.isEmpty) {
      return const DesktopPageScaffold(
        title: 'Learner Details',
        subtitle: 'Edit student personal information for SF10',
        body: EmptyState.generic(
          title: 'No students enrolled',
          subtitle: 'Students will appear here once they join the advisory class',
        ),
      );
    }

    final state = ref.watch(learnerDetailsProvider);

    return DesktopPageScaffold(
      title: 'Learner Details',
      subtitle: 'Edit student personal information for SF10',
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student list sidebar
          SizedBox(
            width: 280,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.students.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final s = widget.students[index];
                  final isSelected = s.student.id == _selectedStudentId;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppColors.foregroundPrimary.withValues(alpha: 0.08),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.foregroundPrimary.withValues(alpha: 0.1),
                      child: Text(
                        s.student.fullName.isNotEmpty ? s.student.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.foregroundPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    title: Text(
                      s.student.fullName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.foregroundPrimary : AppColors.foregroundDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      setState(() {
                        _selectedStudentId = s.student.id;
                        _selectedStudentName = s.student.fullName;
                      });
                      ref.read(learnerDetailsProvider.notifier).load(widget.classId, s.student.id);
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Detail form
          Expanded(
            child: _selectedStudentId == null
                ? const EmptyState.generic(
                    title: 'Select a student',
                    subtitle: 'Choose a student from the list to edit their learner details',
                  )
                : state.isLoading && state.details == null
                    ? const LearnerDetailsSkeleton()
                    : _LearnerDetailsForm(
                        key: ValueKey(_selectedStudentId),
                        classId: widget.classId,
                        studentId: _selectedStudentId!,
                        studentName: _selectedStudentName ?? 'Student',
                        state: state,
                        ref: ref,
                      ),
          ),
        ],
      ),
    );
  }
}

class _LearnerDetailsForm extends StatefulWidget {
  final String classId;
  final String studentId;
  final String studentName;
  final LearnerDetailsState state;
  final WidgetRef ref;

  const _LearnerDetailsForm({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.state,
    required this.ref,
  });

  @override
  State<_LearnerDetailsForm> createState() => _LearnerDetailsFormState();
}

class _LearnerDetailsFormState extends State<_LearnerDetailsForm> {
  late TextEditingController _lrnCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _sexCtrl;
  late TextEditingController _trackStrandCtrl;
  late TextEditingController _curriculumCtrl;
  late TextEditingController _birthdateCtrl;
  late TextEditingController _birthplaceCtrl;
  late TextEditingController _homeAddressCtrl;
  late TextEditingController _fatherNameCtrl;
  late TextEditingController _fatherContactCtrl;
  late TextEditingController _motherNameCtrl;
  late TextEditingController _motherContactCtrl;
  late TextEditingController _guardianNameCtrl;
  late TextEditingController _guardianContactCtrl;
  late TextEditingController _dateAdmittedCtrl;
  bool _initialized = false;

  @override
  void didUpdateWidget(_LearnerDetailsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  void _syncControllers() {
    final d = widget.state.details;
    if (!_initialized || widget.state.details != null) {
      _lrnCtrl.text = d?.lrn ?? '';
      _ageCtrl.text = d?.age?.toString() ?? '';
      _sexCtrl.text = d?.sex ?? '';
      _trackStrandCtrl.text = d?.trackStrand ?? '';
      _curriculumCtrl.text = d?.curriculum ?? '';
      _birthdateCtrl.text = d?.birthdate ?? '';
      _birthplaceCtrl.text = d?.birthplace ?? '';
      _homeAddressCtrl.text = d?.homeAddress ?? '';
      _fatherNameCtrl.text = d?.fatherName ?? '';
      _fatherContactCtrl.text = d?.fatherContact ?? '';
      _motherNameCtrl.text = d?.motherName ?? '';
      _motherContactCtrl.text = d?.motherContact ?? '';
      _guardianNameCtrl.text = d?.guardianName ?? '';
      _guardianContactCtrl.text = d?.guardianContact ?? '';
      _dateAdmittedCtrl.text = d?.dateAdmitted ?? '';
      _initialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _lrnCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
    _sexCtrl = TextEditingController();
    _trackStrandCtrl = TextEditingController();
    _curriculumCtrl = TextEditingController();
    _birthdateCtrl = TextEditingController();
    _birthplaceCtrl = TextEditingController();
    _homeAddressCtrl = TextEditingController();
    _fatherNameCtrl = TextEditingController();
    _fatherContactCtrl = TextEditingController();
    _motherNameCtrl = TextEditingController();
    _motherContactCtrl = TextEditingController();
    _guardianNameCtrl = TextEditingController();
    _guardianContactCtrl = TextEditingController();
    _dateAdmittedCtrl = TextEditingController();
    _syncControllers();
  }

  @override
  void dispose() {
    _lrnCtrl.dispose();
    _ageCtrl.dispose();
    _sexCtrl.dispose();
    _trackStrandCtrl.dispose();
    _curriculumCtrl.dispose();
    _birthdateCtrl.dispose();
    _birthplaceCtrl.dispose();
    _homeAddressCtrl.dispose();
    _fatherNameCtrl.dispose();
    _fatherContactCtrl.dispose();
    _motherNameCtrl.dispose();
    _motherContactCtrl.dispose();
    _guardianNameCtrl.dispose();
    _guardianContactCtrl.dispose();
    _dateAdmittedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final data = <String, dynamic>{
      'lrn': _lrnCtrl.text.isEmpty ? null : _lrnCtrl.text,
      'age': int.tryParse(_ageCtrl.text),
      'sex': _sexCtrl.text.isEmpty ? null : _sexCtrl.text,
      'track_strand': _trackStrandCtrl.text.isEmpty ? null : _trackStrandCtrl.text,
      'curriculum': _curriculumCtrl.text.isEmpty ? null : _curriculumCtrl.text,
      'birthdate': _birthdateCtrl.text.isEmpty ? null : _birthdateCtrl.text,
      'birthplace': _birthplaceCtrl.text.isEmpty ? null : _birthplaceCtrl.text,
      'home_address': _homeAddressCtrl.text.isEmpty ? null : _homeAddressCtrl.text,
      'father_name': _fatherNameCtrl.text.isEmpty ? null : _fatherNameCtrl.text,
      'father_contact': _fatherContactCtrl.text.isEmpty ? null : _fatherContactCtrl.text,
      'mother_name': _motherNameCtrl.text.isEmpty ? null : _motherNameCtrl.text,
      'mother_contact': _motherContactCtrl.text.isEmpty ? null : _motherContactCtrl.text,
      'guardian_name': _guardianNameCtrl.text.isEmpty ? null : _guardianNameCtrl.text,
      'guardian_contact': _guardianContactCtrl.text.isEmpty ? null : _guardianContactCtrl.text,
      'date_admitted': _dateAdmittedCtrl.text.isEmpty ? null : _dateAdmittedCtrl.text,
    };

    final success = await widget.ref.read(learnerDetailsProvider.notifier).save(widget.classId, widget.studentId, data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Learner details saved' : 'Failed to save'),
          backgroundColor: success ? AppColors.semanticSuccessAlt : AppColors.semanticError,
        ),
      );
    }
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.foregroundSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.borderLight)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13, color: AppColors.foregroundDark),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.foregroundDark)),
              const Spacer(),
              FilledButton.icon(
                onPressed: widget.state.isSaving ? null : _save,
                icon: widget.state.isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.foregroundPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          if (widget.state.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.semanticError.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(widget.state.error!, style: const TextStyle(fontSize: 13, color: AppColors.semanticError)),
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(width: 220, child: _field('LRN', _lrnCtrl)),
              SizedBox(width: 100, child: _field('Age', _ageCtrl)),
              SizedBox(width: 100, child: _field('Sex', _sexCtrl)),
              SizedBox(width: 200, child: _field('Track / Strand', _trackStrandCtrl)),
              SizedBox(width: 200, child: _field('Curriculum', _curriculumCtrl)),
              SizedBox(width: 180, child: _field('Birthdate (YYYY-MM-DD)', _birthdateCtrl)),
              SizedBox(width: 220, child: _field('Birthplace', _birthplaceCtrl)),
              SizedBox(width: 300, child: _field('Home Address', _homeAddressCtrl, maxLines: 2)),
              SizedBox(width: 220, child: _field('Father\'s Name', _fatherNameCtrl)),
              SizedBox(width: 180, child: _field('Father\'s Contact', _fatherContactCtrl)),
              SizedBox(width: 220, child: _field('Mother\'s Name', _motherNameCtrl)),
              SizedBox(width: 180, child: _field('Mother\'s Contact', _motherContactCtrl)),
              SizedBox(width: 220, child: _field('Guardian Name', _guardianNameCtrl)),
              SizedBox(width: 180, child: _field('Guardian Contact', _guardianContactCtrl)),
              SizedBox(width: 180, child: _field('Date Admitted', _dateAdmittedCtrl)),
            ],
          ),
        ],
      ),
    );
  }
}
