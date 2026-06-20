import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/config/api_config.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/core/services/school_setup_service.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/domain/setup/entities/school_config.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/presentation/providers/school_details_provider.dart';
import 'package:likha/presentation/widgets/shared/cards/info_panel.dart';
import 'package:likha/presentation/widgets/shared/forms/school_details_form.dart';
import 'package:likha/presentation/widgets/shared/dialogs/styled_dialog.dart';

class AdminSchoolDetailsPage extends ConsumerStatefulWidget {
  const AdminSchoolDetailsPage({super.key});

  @override
  ConsumerState<AdminSchoolDetailsPage> createState() =>
      _AdminSchoolDetailsPageState();
}

class _AdminSchoolDetailsPageState
    extends ConsumerState<AdminSchoolDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _regionController = TextEditingController();
  final _divisionController = TextEditingController();
  final _districtController = TextEditingController();
  final _schoolHeadNameController = TextEditingController();
  final _schoolHeadPositionController = TextEditingController();
  final _schoolYearController = TextEditingController();
  final _schoolCodeController = TextEditingController();
  late String _originalSchoolCode;
  bool _hasSyncedControllers = false;

  @override
  void initState() {
    super.initState();
    _originalSchoolCode = '';
    Future.microtask(() {
      ref.read(schoolDetailsProvider.notifier).loadSchoolDetails();
    });
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _regionController.dispose();
    _divisionController.dispose();
    _districtController.dispose();
    _schoolHeadNameController.dispose();
    _schoolHeadPositionController.dispose();
    _schoolYearController.dispose();
    _schoolCodeController.dispose();
    super.dispose();
  }

  void _syncControllersWithState(SchoolDetailsState state) {
    final settings = state.settings;
    if (settings == null) return;
    _schoolNameController.text = settings.schoolName;
    _regionController.text = settings.schoolRegion;
    _divisionController.text = settings.schoolDivision;
    _districtController.text = settings.schoolDistrict ?? '';
    _schoolHeadNameController.text = settings.schoolHeadName ?? '';
    _schoolHeadPositionController.text = settings.schoolHeadPosition ?? '';
    _schoolYearController.text = settings.schoolYear;
    _schoolCodeController.text = settings.schoolCode;
    _originalSchoolCode = settings.schoolCode;
    _hasSyncedControllers = true;
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

    final notifier = ref.read(schoolDetailsProvider.notifier);

    // Update code first if changed
    if (codeChanged) {
      final codeOk = await notifier.updateSchoolCode(schoolCode: newCode);
      if (!codeOk) {
        if (mounted) {
          final state = ref.read(schoolDetailsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? 'Failed to update code')),
          );
        }
        return;
      }
      _originalSchoolCode = newCode;
    }

    // Update settings
    final name = _schoolNameController.text.trim();
    final ok = await notifier.updateSchoolDetails(
      schoolName: name,
      schoolRegion: _regionController.text.trim(),
      schoolDivision: _divisionController.text.trim(),
      schoolYear: _schoolYearController.text.trim(),
      schoolCode: _schoolCodeController.text.trim(),
      schoolDistrict: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
      schoolHeadName: _schoolHeadNameController.text.trim().isEmpty ? null : _schoolHeadNameController.text.trim(),
      schoolHeadPosition: _schoolHeadPositionController.text.trim().isEmpty ? null : _schoolHeadPositionController.text.trim(),
    );

    if (ok) {
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
    } else if (mounted) {
      final state = ref.read(schoolDetailsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? 'Failed to save settings')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerState = ref.watch(schoolDetailsProvider);

    // Ensure controllers are synced when the widget builds and the provider
    // already holds cached data (e.g., revisiting the page).
    if (!_hasSyncedControllers && providerState.settings != null) {
      _syncControllersWithState(providerState);
    }

    // Sync controllers whenever settings change from external events
    ref.listen(schoolDetailsProvider, (previous, next) {
      if (previous?.settings != next.settings) {
        _syncControllersWithState(next);
      }
    });

    final isLoading = providerState.isLoading;
    final isSaving = providerState.isSaving;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.accentCharcoal),
        title: const Text(
          'School Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.accentCharcoal,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: isLoading
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
                  const InfoPanel(
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
                    child: SchoolDetailsForm(
                      schoolNameController: _schoolNameController,
                      regionController: _regionController,
                      divisionController: _divisionController,
                      districtController: _districtController,
                      schoolHeadNameController: _schoolHeadNameController,
                      schoolHeadPositionController: _schoolHeadPositionController,
                      schoolYearController: _schoolYearController,
                      schoolCodeController: _schoolCodeController,
                      enabled: !isSaving,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentCharcoal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isSaving
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
                    onPressed: isSaving ? null : _showQrCodeDialog,
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
