import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_button.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_dropdown.dart';
import 'package:likha/presentation/widgets/shared/forms/styled_text_field.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/providers/admin_provider.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() =>
      _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  final _sexController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _homeAddressController = TextEditingController();

  final _lrnController = TextEditingController();
  final _birthplaceController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherContactController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherContactController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianContactController = TextEditingController();
  final _trackStrandController = TextEditingController();
  final _curriculumController = TextEditingController();
  final _dateAdmittedController = TextEditingController();

  final _licenseIdController = TextEditingController();
  final _rankController = TextEditingController();
  final _positionController = TextEditingController();
  final _dateHiredController = TextEditingController();
  final _educationLevelController = TextEditingController();
  final _specializationController = TextEditingController();
  final _contactNumberController = TextEditingController();

  String _selectedRole = 'student';
  bool _isSubmitting = false;
  String? _formError;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _sexController.dispose();
    _birthdateController.dispose();
    _homeAddressController.dispose();
    _lrnController.dispose();
    _birthplaceController.dispose();
    _fatherNameController.dispose();
    _fatherContactController.dispose();
    _motherNameController.dispose();
    _motherContactController.dispose();
    _guardianNameController.dispose();
    _guardianContactController.dispose();
    _trackStrandController.dispose();
    _curriculumController.dispose();
    _dateAdmittedController.dispose();
    _licenseIdController.dispose();
    _rankController.dispose();
    _positionController.dispose();
    _dateHiredController.dispose();
    _educationLevelController.dispose();
    _specializationController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    Map<String, dynamic>? learnerDetails;
    Map<String, dynamic>? teacherDetails;

    if (_selectedRole == 'student') {
      learnerDetails = {
        if (_lrnController.text.trim().isNotEmpty) 'lrn': _lrnController.text.trim(),
        if (_sexController.text.trim().isNotEmpty) 'sex': _sexController.text.trim(),
        if (_birthdateController.text.trim().isNotEmpty) 'birthdate': _birthdateController.text.trim(),
        if (_birthplaceController.text.trim().isNotEmpty) 'birthplace': _birthplaceController.text.trim(),
        if (_homeAddressController.text.trim().isNotEmpty) 'home_address': _homeAddressController.text.trim(),
        if (_fatherNameController.text.trim().isNotEmpty) 'father_name': _fatherNameController.text.trim(),
        if (_fatherContactController.text.trim().isNotEmpty) 'father_contact': _fatherContactController.text.trim(),
        if (_motherNameController.text.trim().isNotEmpty) 'mother_name': _motherNameController.text.trim(),
        if (_motherContactController.text.trim().isNotEmpty) 'mother_contact': _motherContactController.text.trim(),
        if (_guardianNameController.text.trim().isNotEmpty) 'guardian_name': _guardianNameController.text.trim(),
        if (_guardianContactController.text.trim().isNotEmpty) 'guardian_contact': _guardianContactController.text.trim(),
        if (_trackStrandController.text.trim().isNotEmpty) 'track_strand': _trackStrandController.text.trim(),
        if (_curriculumController.text.trim().isNotEmpty) 'curriculum': _curriculumController.text.trim(),
        if (_dateAdmittedController.text.trim().isNotEmpty) 'date_admitted': _dateAdmittedController.text.trim(),
      };
      if (learnerDetails.isEmpty) learnerDetails = null;
    } else if (_selectedRole == 'teacher') {
      teacherDetails = {
        if (_licenseIdController.text.trim().isNotEmpty) 'license_id': _licenseIdController.text.trim(),
        if (_rankController.text.trim().isNotEmpty) 'rank': _rankController.text.trim(),
        if (_positionController.text.trim().isNotEmpty) 'position': _positionController.text.trim(),
        if (_sexController.text.trim().isNotEmpty) 'sex': _sexController.text.trim(),
        if (_birthdateController.text.trim().isNotEmpty) 'birthdate': _birthdateController.text.trim(),
        if (_homeAddressController.text.trim().isNotEmpty) 'home_address': _homeAddressController.text.trim(),
        if (_dateHiredController.text.trim().isNotEmpty) 'date_hired': _dateHiredController.text.trim(),
        if (_educationLevelController.text.trim().isNotEmpty) 'education_level': _educationLevelController.text.trim(),
        if (_specializationController.text.trim().isNotEmpty) 'specialization': _specializationController.text.trim(),
        if (_contactNumberController.text.trim().isNotEmpty) 'contact_number': _contactNumberController.text.trim(),
      };
      if (teacherDetails.isEmpty) teacherDetails = null;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(adminProvider.notifier).createAccount(
            username: _usernameController.text.trim(),
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            role: _selectedRole,
            learnerDetails: learnerDetails,
            teacherDetails: teacherDetails,
          );

      if (mounted) {
        final state = ref.read(adminProvider);
        if (state.successMessage != null) {
          ref.read(adminProvider.notifier).clearMessages();
          Navigator.pop(context);
        } else if (state.error != null) {
          ref.read(adminProvider.notifier).clearMessages();
          setState(
              () => _formError = AppErrorMapper.toUserMessage(state.error));
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: DesktopPageScaffold(
        title: 'Create Account',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.foregroundPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FormMessage(
                    message: _formError,
                    severity: MessageSeverity.error,
                  ),
                  if (_formError != null) const SizedBox(height: 16),
                  StyledTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.person_outline_rounded,
                    enabled: !adminState.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() => _formError = null),
                  ),
                  const SizedBox(height: 16),
                  StyledTextField(
                    controller: _firstNameController,
                    label: 'First Name',
                    icon: Icons.badge_outlined,
                    enabled: !adminState.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'First name is required';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() => _formError = null),
                  ),
                  const SizedBox(height: 16),
                  StyledTextField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    icon: Icons.badge_outlined,
                    enabled: !adminState.isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Last name is required';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() => _formError = null),
                  ),
                  const SizedBox(height: 16),
                  StyledDropdown(
                    value: _selectedRole,
                    label: 'Role',
                    icon: Icons.work_outline_rounded,
                    enabled: !adminState.isLoading,
                    items: const [
                      DropdownMenuItem(
                          value: 'student', child: Text('Student')),
                      DropdownMenuItem(
                          value: 'teacher', child: Text('Teacher')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                          _formError = null;
                        });
                      }
                    },
                  ),
                  if (_selectedRole == 'student') ...[
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Learner Details (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foregroundPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _lrnController,
                      label: 'LRN',
                      icon: Icons.badge_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _sexController,
                      label: 'Sex',
                      icon: Icons.wc_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _birthdateController,
                      label: 'Birthdate (YYYY-MM-DD)',
                      icon: Icons.cake_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _birthplaceController,
                      label: 'Birthplace',
                      icon: Icons.place_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _homeAddressController,
                      label: 'Home Address',
                      icon: Icons.home_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _fatherNameController,
                      label: "Father's Name",
                      icon: Icons.person_outline_rounded,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _fatherContactController,
                      label: "Father's Contact",
                      icon: Icons.phone_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _motherNameController,
                      label: "Mother's Name",
                      icon: Icons.person_outline_rounded,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _motherContactController,
                      label: "Mother's Contact",
                      icon: Icons.phone_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _guardianNameController,
                      label: "Guardian's Name",
                      icon: Icons.person_outline_rounded,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _guardianContactController,
                      label: "Guardian's Contact",
                      icon: Icons.phone_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _trackStrandController,
                      label: 'Track / Strand',
                      icon: Icons.school_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _curriculumController,
                      label: 'Curriculum',
                      icon: Icons.menu_book_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _dateAdmittedController,
                      label: 'Date Admitted (YYYY-MM-DD)',
                      icon: Icons.event_outlined,
                      enabled: !adminState.isLoading,
                    ),
                  ],
                  if (_selectedRole == 'teacher') ...[
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Teacher Details (Optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foregroundPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _licenseIdController,
                      label: 'License ID (PRC)',
                      icon: Icons.badge_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _rankController,
                      label: 'Rank',
                      icon: Icons.work_outline_rounded,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _positionController,
                      label: 'Position',
                      icon: Icons.work_outline_rounded,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _sexController,
                      label: 'Sex',
                      icon: Icons.wc_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _birthdateController,
                      label: 'Birthdate (YYYY-MM-DD)',
                      icon: Icons.cake_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _homeAddressController,
                      label: 'Home Address',
                      icon: Icons.home_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _dateHiredController,
                      label: 'Date Hired (YYYY-MM-DD)',
                      icon: Icons.event_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _educationLevelController,
                      label: 'Education Level',
                      icon: Icons.school_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _specializationController,
                      label: 'Specialization',
                      icon: Icons.school_outlined,
                      enabled: !adminState.isLoading,
                    ),
                    const SizedBox(height: 16),
                    StyledTextField(
                      controller: _contactNumberController,
                      label: 'Contact Number',
                      icon: Icons.phone_outlined,
                      enabled: !adminState.isLoading,
                    ),
                  ],
                  const SizedBox(height: 32),
                  StyledButton(
                    text: 'Create Account',
                    isLoading: adminState.isLoading,
                    onPressed: _handleCreate,
                  ),
                  const SizedBox(height: 24),
                  const _BulkOperationsCard(),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BulkOperationsCard extends StatelessWidget {
  const _BulkOperationsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundTertiary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 20, color: AppColors.foregroundSecondary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulk Operations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.foregroundDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Need to create multiple accounts? Go to Account Management and use '
                  '"Bulk Import" to upload a CSV. You can also import school history, '
                  'subjects, and attendance from there.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.foregroundSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
