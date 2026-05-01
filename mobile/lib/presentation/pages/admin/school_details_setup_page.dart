import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/constants/api_constants.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/domain/setup/entities/school_config.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/presentation/pages/desktop/core/platform_detector.dart';
import 'package:likha/presentation/pages/shared/widgets/auth_desktop_layout.dart';
import 'package:likha/presentation/widgets/shared/forms/form_message.dart';
import 'package:likha/presentation/widgets/shared/forms/school_settings_form.dart';
import 'package:likha/presentation/widgets/auth_wrapper.dart';

/// Shown after admin's first login when school_name is null.
/// Blocks access to the dashboard until school details are filled in.
class SchoolDetailsSetupPage extends StatefulWidget {
  const SchoolDetailsSetupPage({super.key});

  @override
  State<SchoolDetailsSetupPage> createState() => _SchoolDetailsSetupPageState();
}

class _SchoolDetailsSetupPageState extends State<SchoolDetailsSetupPage> {
  final _schoolNameController = TextEditingController();
  final _regionController = TextEditingController();
  final _divisionController = TextEditingController();
  final _schoolYearController = TextEditingController();
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _schoolNameController.dispose();
    _regionController.dispose();
    _divisionController.dispose();
    _schoolYearController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _schoolNameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'School name is required');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final dioClient = di.sl<DioClient>();
      await dioClient.dio.put(
        '${ApiConstants.baseUrl}/api/v1/admin/setup/school-settings',
        data: {
          'school_name': name,
          'school_region': _regionController.text.trim().isEmpty
              ? null
              : _regionController.text.trim(),
          'school_division': _divisionController.text.trim().isEmpty
              ? null
              : _divisionController.text.trim(),
          'school_year': _schoolYearController.text.trim().isEmpty
              ? null
              : _schoolYearController.text.trim(),
        },
      );

      // Update SharedPreferences so login page shows the correct school name
      final setupService = di.sl<SchoolSetupService>();
      final config = await setupService.getSchoolConfig();
      if (config != null) {
        await setupService.saveSchoolConfig(
          SchoolConfig(serverUrl: config.serverUrl, schoolName: name),
        );
      }

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = 'Failed to save. Please try again.';
        });
      }
    }
  }

  Widget _buildFormContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Set up your school',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Fill in your school details to get started.\nThis information is used in reports.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.foregroundTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_error != null)
            FormMessage(message: _error, severity: MessageSeverity.error),
          SchoolSettingsForm(
            schoolNameController: _schoolNameController,
            regionController: _regionController,
            divisionController: _divisionController,
            schoolYearController: _schoolYearController,
            enabled: !_isSaving,
            onSchoolNameChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: _isSaving ? AppColors.borderLight : AppColors.accentCharcoal,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSaving ? AppColors.backgroundDisabled : AppColors.accentCharcoal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.foregroundTertiary,
                        ),
                      )
                    : const Text(
                        'Save & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PlatformDetector.isDesktop
          ? AuthDesktopLayout(formContent: _buildFormContent())
          : SafeArea(child: Center(child: _buildFormContent())),
    );
  }
}
