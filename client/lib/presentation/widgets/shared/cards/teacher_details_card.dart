import 'dart:async';

import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/teacher_details.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';

class TeacherDetailsCard extends StatefulWidget {
  final TeacherDetails? details;
  final bool isLoading;
  final ValueChanged<Map<String, dynamic>> onSave;

  const TeacherDetailsCard({
    super.key,
    this.details,
    required this.isLoading,
    required this.onSave,
  });

  @override
  State<TeacherDetailsCard> createState() => _TeacherDetailsCardState();
}

class _TeacherDetailsCardState extends State<TeacherDetailsCard> {
  bool _showSaved = false;
  Timer? _savedTimer;

  late final TextEditingController _licenseIdCtrl;
  late final TextEditingController _rankCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _sexCtrl;
  late final TextEditingController _birthdateCtrl;
  late final TextEditingController _homeAddressCtrl;
  late final TextEditingController _dateHiredCtrl;
  late final TextEditingController _educationLevelCtrl;
  late final TextEditingController _specializationCtrl;
  late final TextEditingController _contactNumberCtrl;

  @override
  void initState() {
    super.initState();
    _licenseIdCtrl = TextEditingController(text: widget.details?.licenseId ?? '');
    _rankCtrl = TextEditingController(text: widget.details?.rank ?? '');
    _positionCtrl = TextEditingController(text: widget.details?.position ?? '');
    _sexCtrl = TextEditingController(text: widget.details?.sex ?? '');
    _birthdateCtrl = TextEditingController(text: widget.details?.birthdate ?? '');
    _homeAddressCtrl = TextEditingController(text: widget.details?.homeAddress ?? '');
    _dateHiredCtrl = TextEditingController(text: widget.details?.dateHired ?? '');
    _educationLevelCtrl = TextEditingController(text: widget.details?.educationLevel ?? '');
    _specializationCtrl = TextEditingController(text: widget.details?.specialization ?? '');
    _contactNumberCtrl = TextEditingController(text: widget.details?.contactNumber ?? '');
  }

  @override
  void didUpdateWidget(TeacherDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.details?.id != oldWidget.details?.id) {
      _licenseIdCtrl.text = widget.details?.licenseId ?? '';
      _rankCtrl.text = widget.details?.rank ?? '';
      _positionCtrl.text = widget.details?.position ?? '';
      _sexCtrl.text = widget.details?.sex ?? '';
      _birthdateCtrl.text = widget.details?.birthdate ?? '';
      _homeAddressCtrl.text = widget.details?.homeAddress ?? '';
      _dateHiredCtrl.text = widget.details?.dateHired ?? '';
      _educationLevelCtrl.text = widget.details?.educationLevel ?? '';
      _specializationCtrl.text = widget.details?.specialization ?? '';
      _contactNumberCtrl.text = widget.details?.contactNumber ?? '';
    }
  }

  @override
  void dispose() {
    _licenseIdCtrl.dispose();
    _rankCtrl.dispose();
    _positionCtrl.dispose();
    _sexCtrl.dispose();
    _birthdateCtrl.dispose();
    _homeAddressCtrl.dispose();
    _dateHiredCtrl.dispose();
    _educationLevelCtrl.dispose();
    _specializationCtrl.dispose();
    _contactNumberCtrl.dispose();
    _savedTimer?.cancel();
    super.dispose();
  }

  void _handleSave() {
    widget.onSave({
      'license_id': _licenseIdCtrl.text.isEmpty ? null : _licenseIdCtrl.text,
      'rank': _rankCtrl.text.isEmpty ? null : _rankCtrl.text,
      'position': _positionCtrl.text.isEmpty ? null : _positionCtrl.text,
      'sex': _sexCtrl.text.isEmpty ? null : _sexCtrl.text,
      'birthdate': _birthdateCtrl.text.isEmpty ? null : _birthdateCtrl.text,
      'home_address': _homeAddressCtrl.text.isEmpty ? null : _homeAddressCtrl.text,
      'date_hired': _dateHiredCtrl.text.isEmpty ? null : _dateHiredCtrl.text,
      'education_level': _educationLevelCtrl.text.isEmpty ? null : _educationLevelCtrl.text,
      'specialization': _specializationCtrl.text.isEmpty ? null : _specializationCtrl.text,
      'contact_number': _contactNumberCtrl.text.isEmpty ? null : _contactNumberCtrl.text,
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
                'Teacher Details',
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
            controller: _licenseIdCtrl,
            label: 'License ID (PRC)',
            icon: Icons.badge_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _rankCtrl,
            label: 'Rank',
            icon: Icons.work_outline_rounded,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _positionCtrl,
            label: 'Position',
            icon: Icons.work_outline_rounded,
            enabled: !widget.isLoading,
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
            controller: _birthdateCtrl,
            label: 'Birthdate (YYYY-MM-DD)',
            icon: Icons.cake_outlined,
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
            controller: _dateHiredCtrl,
            label: 'Date Hired (YYYY-MM-DD)',
            icon: Icons.event_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _educationLevelCtrl,
            label: 'Education Level',
            icon: Icons.school_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _specializationCtrl,
            label: 'Specialization',
            icon: Icons.school_outlined,
            enabled: !widget.isLoading,
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _contactNumberCtrl,
            label: 'Contact Number',
            icon: Icons.phone_outlined,
            enabled: !widget.isLoading,
          ),
        ],
      ),
    );
  }

}
