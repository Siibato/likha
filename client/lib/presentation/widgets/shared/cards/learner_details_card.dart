import 'dart:async';

import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';

class LearnerDetailsCard extends StatefulWidget {
  final LearnerDetails? details;
  final bool isLoading;
  final ValueChanged<Map<String, dynamic>> onSave;

  const LearnerDetailsCard({
    super.key,
    this.details,
    required this.isLoading,
    required this.onSave,
  });

  @override
  State<LearnerDetailsCard> createState() => _LearnerDetailsCardState();
}

class _LearnerDetailsCardState extends State<LearnerDetailsCard> {
  bool _showSaved = false;
  Timer? _savedTimer;

  late final TextEditingController _lrnCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _sexCtrl;
  late final TextEditingController _trackStrandCtrl;
  late final TextEditingController _curriculumCtrl;
  late final TextEditingController _birthdateCtrl;
  late final TextEditingController _birthplaceCtrl;
  late final TextEditingController _homeAddressCtrl;
  late final TextEditingController _fatherNameCtrl;
  late final TextEditingController _fatherContactCtrl;
  late final TextEditingController _motherNameCtrl;
  late final TextEditingController _motherContactCtrl;
  late final TextEditingController _guardianNameCtrl;
  late final TextEditingController _guardianContactCtrl;
  late final TextEditingController _dateAdmittedCtrl;

  @override
  void initState() {
    super.initState();
    _lrnCtrl = TextEditingController(text: widget.details?.lrn ?? '');
    _ageCtrl = TextEditingController(text: widget.details?.age?.toString() ?? '');
    _sexCtrl = TextEditingController(text: widget.details?.sex ?? '');
    _trackStrandCtrl = TextEditingController(text: widget.details?.trackStrand ?? '');
    _curriculumCtrl = TextEditingController(text: widget.details?.curriculum ?? '');
    _birthdateCtrl = TextEditingController(text: widget.details?.birthdate ?? '');
    _birthplaceCtrl = TextEditingController(text: widget.details?.birthplace ?? '');
    _homeAddressCtrl = TextEditingController(text: widget.details?.homeAddress ?? '');
    _fatherNameCtrl = TextEditingController(text: widget.details?.fatherName ?? '');
    _fatherContactCtrl = TextEditingController(text: widget.details?.fatherContact ?? '');
    _motherNameCtrl = TextEditingController(text: widget.details?.motherName ?? '');
    _motherContactCtrl = TextEditingController(text: widget.details?.motherContact ?? '');
    _guardianNameCtrl = TextEditingController(text: widget.details?.guardianName ?? '');
    _guardianContactCtrl = TextEditingController(text: widget.details?.guardianContact ?? '');
    _dateAdmittedCtrl = TextEditingController(text: widget.details?.dateAdmitted ?? '');
  }

  @override
  void didUpdateWidget(LearnerDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.details?.id != oldWidget.details?.id) {
      _lrnCtrl.text = widget.details?.lrn ?? '';
      _ageCtrl.text = widget.details?.age?.toString() ?? '';
      _sexCtrl.text = widget.details?.sex ?? '';
      _trackStrandCtrl.text = widget.details?.trackStrand ?? '';
      _curriculumCtrl.text = widget.details?.curriculum ?? '';
      _birthdateCtrl.text = widget.details?.birthdate ?? '';
      _birthplaceCtrl.text = widget.details?.birthplace ?? '';
      _homeAddressCtrl.text = widget.details?.homeAddress ?? '';
      _fatherNameCtrl.text = widget.details?.fatherName ?? '';
      _fatherContactCtrl.text = widget.details?.fatherContact ?? '';
      _motherNameCtrl.text = widget.details?.motherName ?? '';
      _motherContactCtrl.text = widget.details?.motherContact ?? '';
      _guardianNameCtrl.text = widget.details?.guardianName ?? '';
      _guardianContactCtrl.text = widget.details?.guardianContact ?? '';
      _dateAdmittedCtrl.text = widget.details?.dateAdmitted ?? '';
    }
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
    _savedTimer?.cancel();
    super.dispose();
  }

  void _handleSave() {
    widget.onSave({
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
    });
    setState(() => _showSaved = true);
    _savedTimer?.cancel();
    _savedTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSaved = false);
    });
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
              const Text(
                'Learner Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.foregroundDark,
                ),
              ),
              const Spacer(),
              if (_showSaved)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: AppColors.semanticSuccess),
                    const SizedBox(width: 6),
                    Text(
                      'Saved',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.semanticSuccess,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                )
              else if (widget.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                ElevatedButton.icon(
                  onPressed: _handleSave,
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.foregroundPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          StyledTextField(
            controller: _lrnCtrl,
            label: 'LRN',
            icon: Icons.badge_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _ageCtrl,
            label: 'Age',
            icon: Icons.calendar_today_outlined,
            enabled: !widget.isLoading,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _sexCtrl,
            label: 'Sex',
            icon: Icons.wc_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _trackStrandCtrl,
            label: 'Track / Strand',
            icon: Icons.school_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _curriculumCtrl,
            label: 'Curriculum',
            icon: Icons.menu_book_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _birthdateCtrl,
            label: 'Birthdate (YYYY-MM-DD)',
            icon: Icons.cake_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _birthplaceCtrl,
            label: 'Birthplace',
            icon: Icons.place_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _homeAddressCtrl,
            label: 'Home Address',
            icon: Icons.home_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _fatherNameCtrl,
            label: "Father's Name",
            icon: Icons.person_outline_rounded,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _fatherContactCtrl,
            label: "Father's Contact",
            icon: Icons.phone_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _motherNameCtrl,
            label: "Mother's Name",
            icon: Icons.person_outline_rounded,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _motherContactCtrl,
            label: "Mother's Contact",
            icon: Icons.phone_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _guardianNameCtrl,
            label: "Guardian's Name",
            icon: Icons.person_outline_rounded,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _guardianContactCtrl,
            label: "Guardian's Contact",
            icon: Icons.phone_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _dateAdmittedCtrl,
            label: 'Date Admitted (YYYY-MM-DD)',
            icon: Icons.event_outlined,
            enabled: !widget.isLoading,
          ),
        ],
      ),
    );
  }

}
