import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_dropdown.dart';

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
  String? _selectedSex;
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
    _selectedSex = widget.details?.sex;
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
      _selectedSex = widget.details?.sex;
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

  String _computeAgeDisplay(String birthdateStr) {
    if (birthdateStr.isEmpty) return '';
    final birthdate = DateTime.tryParse(birthdateStr);
    if (birthdate == null) return '';
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age.toString();
  }

  Future<void> _pickDate(TextEditingController controller, {DateTime? initialDate, DateTime? firstDate, DateTime? lastDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accentCharcoal,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.accentCharcoal,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  void _handleSave() {
    widget.onSave({
      'lrn': _lrnCtrl.text.isEmpty ? null : _lrnCtrl.text,
      'sex': _selectedSex,
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
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16, color: AppColors.semanticSuccess),
                    SizedBox(width: 6),
                    Text(
                      'Saved',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.semanticSuccess,
                      ),
                    ),
                    SizedBox(width: 8),
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
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
            ],
          ),
          const SizedBox(height: 16),
          StyledDropdown<String>(
            value: _selectedSex,
            label: 'Sex',
            icon: Icons.wc_outlined,
            enabled: !widget.isLoading,
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
            ],
            onChanged: (value) => setState(() => _selectedSex = value),
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
            label: 'Birthdate',
            icon: Icons.cake_outlined,
            enabled: !widget.isLoading,
            readOnly: true,
            onTap: () => _pickDate(_birthdateCtrl),
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: TextEditingController(
              text: _computeAgeDisplay(_birthdateCtrl.text),
            ),
            label: 'Age (computed)',
            icon: Icons.calendar_today_outlined,
            enabled: false,
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
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]'))],
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
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]'))],
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
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]'))],
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _dateAdmittedCtrl,
            label: 'Date Admitted',
            icon: Icons.event_outlined,
            enabled: !widget.isLoading,
            readOnly: true,
            onTap: () => _pickDate(_dateAdmittedCtrl),
          ),
        ],
      ),
    );
  }

}
