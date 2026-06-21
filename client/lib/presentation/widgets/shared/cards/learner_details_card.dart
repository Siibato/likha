import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/student_records/entities/learner_details.dart';

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
              _field('LRN', _lrnCtrl),
              _field('Age', _ageCtrl),
              _field('Sex', _sexCtrl),
              _field('Track/Strand', _trackStrandCtrl),
              _field('Curriculum', _curriculumCtrl),
              _field('Birthdate', _birthdateCtrl),
              _field('Birthplace', _birthplaceCtrl),
              _field('Home Address', _homeAddressCtrl),
              _field('Father Name', _fatherNameCtrl),
              _field('Father Contact', _fatherContactCtrl),
              _field('Mother Name', _motherNameCtrl),
              _field('Mother Contact', _motherContactCtrl),
              _field('Guardian Name', _guardianNameCtrl),
              _field('Guardian Contact', _guardianContactCtrl),
              _field('Date Admitted', _dateAdmittedCtrl),
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
