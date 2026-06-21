import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/auth/entities/teacher_details.dart';

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
              if (widget.isLoading)
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
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _field('License ID', _licenseIdCtrl),
              _field('Rank', _rankCtrl),
              _field('Position', _positionCtrl),
              _field('Sex', _sexCtrl),
              _field('Birthdate', _birthdateCtrl),
              _field('Home Address', _homeAddressCtrl),
              _field('Date Hired', _dateHiredCtrl),
              _field('Education Level', _educationLevelCtrl),
              _field('Specialization', _specializationCtrl),
              _field('Contact Number', _contactNumberCtrl),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            enabled: !widget.isLoading,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.foregroundDark),
          ),
        ],
      ),
    );
  }
}
