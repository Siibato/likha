import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/providers/class_provider.dart';
import 'package:likha/presentation/providers/assignment_provider.dart';
import 'package:likha/presentation/providers/assessment_provider.dart';

class TeacherGradeComputationPage extends ConsumerStatefulWidget {
  final String classId;
  final String className;

  const TeacherGradeComputationPage({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  ConsumerState<TeacherGradeComputationPage> createState() =>
      _TeacherGradeComputationPageState();
}

class _TeacherGradeComputationPageState
    extends ConsumerState<TeacherGradeComputationPage> {
  late TextEditingController _assignmentWeightController;
  late TextEditingController _assessmentWeightController;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _assignmentWeightController = TextEditingController();
    _assessmentWeightController = TextEditingController();
    _loadWeights();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classProvider.notifier).loadClassDetail(widget.classId);
      ref.read(assignmentProvider.notifier).loadAssignments(widget.classId);
      ref.read(assessmentProvider.notifier).loadAssessments(widget.classId);
    });
  }

  @override
  void dispose() {
    _assignmentWeightController.dispose();
    _assessmentWeightController.dispose();
    super.dispose();
  }

  Future<void> _loadWeights() async {
    final prefs = await SharedPreferences.getInstance();
    final assignmentWeight =
        prefs.getInt('assignment_weight_${widget.classId}') ?? 50;
    final assessmentWeight =
        prefs.getInt('assessment_weight_${widget.classId}') ?? 50;

    _assignmentWeightController.text = assignmentWeight.toString();
    _assessmentWeightController.text = assessmentWeight.toString();
  }

  Future<void> _saveWeights() async {
    final assignmentWeight = int.tryParse(_assignmentWeightController.text) ?? 50;
    final assessmentWeight = int.tryParse(_assessmentWeightController.text) ?? 50;

    if (assignmentWeight + assessmentWeight != 100) {
      setState(() => _formError = 'Weights must sum to 100%');
      return;
    }

    setState(() => _formError = null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('assignment_weight_${widget.classId}', assignmentWeight);
    await prefs.setInt('assessment_weight_${widget.classId}', assessmentWeight);
  }

  @override
  Widget build(BuildContext context) {
    final classState = ref.watch(classProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClassSectionHeader(
              title: widget.className,
              showBackButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grade Weights Section
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Grading Formula',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF202020),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FormMessage(
                                message: _formError,
                                severity: MessageSeverity.error,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Assignments',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _assignmentWeightController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: InputDecoration(
                                            hintText: '50',
                                            suffixText: '%',
                                            contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE0E0E0),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Assessments',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        TextFormField(
                                          controller: _assessmentWeightController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          decoration: InputDecoration(
                                            hintText: '50',
                                            suffixText: '%',
                                            contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE0E0E0),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveWeights,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2B2B2B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save Weights',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Assessment scores require individual grade submissions from students. Per-student grade computation loads from cached submission data.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF999999),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Student Overview Section
                    const SizedBox(height: 24),
                    const Text(
                      'Student Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2B2B2B),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (classState.currentClassDetail == null)
                      const Text(
                        'Loading class details...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (classState.currentClassDetail?.students ?? []).length,
                        itemBuilder: (context, index) {
                          final student =
                              classState.currentClassDetail!.students[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.student.fullName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF202020),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          student.student.username,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF999999),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'TBD',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
