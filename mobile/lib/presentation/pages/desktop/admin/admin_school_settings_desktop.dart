import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:likha/core/constants/api_constants.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/setup/entities/school_config.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/school_settings_form.dart';

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
  final _schoolCodeController = TextEditingController();
  late String _originalSchoolCode;
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
    _schoolCodeController.dispose();
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
        final code = data['school_code'] as String? ?? '';
        _schoolCodeController.text = code;
        _originalSchoolCode = code;
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

  Future<void> _showQrCodeDialog() async {
    try {
      final response = await di.sl<DioClient>().dio.get(
        '${ApiConstants.baseUrl}/api/v1/admin/setup/qr',
      );
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data != null && mounted) {
        final qrBase64 = data['qr_png_base64'] as String?;
        final code = data['code'] as String?;
        if (qrBase64 != null) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('School QR Code'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.memory(
                    base64Decode(qrBase64),
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                  if (code != null)
                    Text(
                      'Code: $code',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load QR code')),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    final newCode = _schoolCodeController.text.trim().toUpperCase();
    final codeChanged = newCode != _originalSchoolCode;

    // Show confirmation dialog if code changed
    if (codeChanged) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change School Code?'),
          content: const Text(
            'Changing the code will affect new student and teacher setups. Existing users will not be impacted. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (shouldProceed != true) return;
    }

    setState(() => _isSaving = true);
    try {
      // Update school code if it changed
      if (codeChanged) {
        await di.sl<DioClient>().dio.put(
          '${ApiConstants.baseUrl}/api/v1/admin/setup/code',
          data: {'code': newCode},
        );
        _originalSchoolCode = newCode;
      }

      // Update school settings
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
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.foregroundSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SchoolSettingsForm(
                      schoolNameController: _schoolNameController,
                      regionController: _regionController,
                      divisionController: _divisionController,
                      schoolYearController: _schoolYearController,
                      schoolCodeController: _schoolCodeController,
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
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isSaving ? null : _showQrCodeDialog,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('View QR Code'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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
