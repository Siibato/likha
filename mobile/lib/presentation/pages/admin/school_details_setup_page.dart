import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likha/core/constants/api_constants.dart';
import 'package:likha/core/network/dio_client.dart';
import 'package:likha/injection_container.dart' as di;
import 'package:likha/presentation/pages/desktop/core/platform_detector.dart';
import 'package:likha/presentation/pages/shared/widgets/auth_desktop_layout.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/form_message.dart';
import 'package:likha/presentation/pages/shared/widgets/forms/styled_text_field.dart';
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
              color: Color(0xFF202020),
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
              color: Color(0xFF999999),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (_error != null)
            FormMessage(message: _error, severity: MessageSeverity.error),
          StyledTextField(
            controller: _schoolNameController,
            label: 'School Name',
            icon: Icons.school_outlined,
            enabled: !_isSaving,
            hintText: 'e.g., Mabini National High School',
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _regionController,
            label: 'Region',
            icon: Icons.map_outlined,
            enabled: !_isSaving,
            hintText: 'e.g., Region IV-A (CALABARZON)',
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _divisionController,
            label: 'Division',
            icon: Icons.location_city_outlined,
            enabled: !_isSaving,
            hintText: 'e.g., Division of Batangas',
          ),
          const SizedBox(height: 16),
          StyledTextField(
            controller: _schoolYearController,
            label: 'School Year',
            icon: Icons.calendar_today_outlined,
            enabled: !_isSaving,
            hintText: 'e.g., 2025-2026',
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: _isSaving ? const Color(0xFFE0E0E0) : const Color(0xFF2B2B2B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSaving ? const Color(0xFFF5F5F5) : const Color(0xFF2B2B2B),
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
                          color: Color(0xFF999999),
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
