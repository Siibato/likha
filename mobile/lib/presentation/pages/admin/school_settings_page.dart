import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:likha/core/constants/api_constants.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/setup/entities/school_config.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/presentation/widgets/shared/cards/info_panel.dart';
import 'package:likha/presentation/widgets/shared/forms/school_settings_form.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';

class AdminSchoolSettingsPage extends StatefulWidget {
  const AdminSchoolSettingsPage({super.key});

  @override
  State<AdminSchoolSettingsPage> createState() =>
      _AdminSchoolSettingsPageState();
}

class _AdminSchoolSettingsPageState extends State<AdminSchoolSettingsPage> {
  final _formKey = GlobalKey<FormState>();
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
            builder: (_) => _SchoolQrCodeDialog(
              qrBase64: qrBase64,
              code: code,
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
    if (!_formKey.currentState!.validate()) return;

    final newCode = _schoolCodeController.text.trim().toUpperCase();
    final codeChanged = newCode != _originalSchoolCode;

    // Show confirmation dialog if code changed
    if (codeChanged) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => StyledDialog(
          title: 'Change School Code?',
          content: const Text(
            'Changing the code will affect new student and teacher setups. Existing users will not be impacted. Are you sure?',
          ),
          actions: [
            StyledDialogAction(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context, false),
            ),
            StyledDialogAction(
              label: 'Confirm',
              isPrimary: true,
              onPressed: () => Navigator.pop(context, true),
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
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.accentCharcoal),
        title: const Text(
          'School Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.accentCharcoal,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.accentCharcoal,
                strokeWidth: 2.5,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  Form(
                    key: _formKey,
                    child: SchoolSettingsForm(
                      schoolNameController: _schoolNameController,
                      regionController: _regionController,
                      divisionController: _divisionController,
                      schoolYearController: _schoolYearController,
                      schoolCodeController: _schoolCodeController,
                      enabled: !_isSaving,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCharcoal,
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
    );
  }
}

/// Dialog to display the school QR code.
class _SchoolQrCodeDialog extends StatelessWidget {
  final String qrBase64;
  final String? code;

  const _SchoolQrCodeDialog({
    required this.qrBase64,
    this.code,
  });

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: 'School QR Code',
      subtitle: code != null ? 'Code: $code' : null,
      content: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Image.memory(
            base64Decode(qrBase64),
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
      actions: [
        StyledDialogAction(
          label: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
