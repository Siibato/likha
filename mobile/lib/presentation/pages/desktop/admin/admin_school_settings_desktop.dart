import 'package:flutter/material.dart';
import 'package:likha/core/constants/api_constants.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/setup/entities/school_config.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/school_settings_form.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_text_styles.dart';

class AdminSchoolSettingsDesktop extends StatefulWidget {
  const AdminSchoolSettingsDesktop({super.key});

  @override
  State<AdminSchoolSettingsDesktop> createState() =>
      _AdminSchoolSettingsDesktopState();
}

class _AdminSchoolSettingsDesktopState
    extends State<AdminSchoolSettingsDesktop> {
  final _schoolNameController = TextEditingController();
  final _regionController = TextEditingController();
  final _divisionController = TextEditingController();
  final _schoolYearController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _regionController.dispose();
    _divisionController.dispose();
    _schoolYearController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await di.sl<DioClient>().dio.get(
        '${ApiConstants.baseUrl}/api/v1/admin/setup/school-settings',
      );
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        _schoolNameController.text = data['school_name'] as String? ?? '';
        _regionController.text = data['school_region'] as String? ?? '';
        _divisionController.text = data['school_division'] as String? ?? '';
        _schoolYearController.text = data['school_year'] as String? ?? '';
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load settings')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final name = _schoolNameController.text.trim();
      await di.sl<DioClient>().dio.put(
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
      if (name.isNotEmpty) {
        final setupService = di.sl<SchoolSetupService>();
        final config = await setupService.getSchoolConfig();
        if (config != null) {
          await setupService.saveSchoolConfig(
            SchoolConfig(serverUrl: config.serverUrl, schoolName: name),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save settings')),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return DesktopPageScaffold(
      title: 'School Settings',
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.foregroundPrimary,
                strokeWidth: 2.5,
              ),
            )
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InfoPanel(
                      child: Text(
                        'These settings are used in printed reports (TOS, Item Analysis) for DepEd-formatted headers.',
                        style: AppTextStyles.cardSubtitleMd,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SchoolSettingsForm(
                      schoolNameController: _schoolNameController,
                      regionController: _regionController,
                      divisionController: _divisionController,
                      schoolYearController: _schoolYearController,
                      enabled: !_isSaving,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.foregroundPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save Settings',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
