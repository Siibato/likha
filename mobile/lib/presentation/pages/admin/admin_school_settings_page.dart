import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/info_panel.dart';
import 'package:likha/presentation/pages/shared/widgets/tokens/app_text_styles.dart';

class AdminSchoolSettingsPage extends StatefulWidget {
  const AdminSchoolSettingsPage({super.key});

  @override
  State<AdminSchoolSettingsPage> createState() =>
      _AdminSchoolSettingsPageState();
}

class _AdminSchoolSettingsPageState extends State<AdminSchoolSettingsPage> {
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
    final prefs = await SharedPreferences.getInstance();
    _schoolNameController.text = prefs.getString('school_name') ?? '';
    _regionController.text = prefs.getString('school_region') ?? '';
    _divisionController.text = prefs.getString('school_division') ?? '';
    _schoolYearController.text = prefs.getString('school_year') ?? '';
    setState(() => _isLoading = false);
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('school_name', _schoolNameController.text.trim());
    await prefs.setString('school_region', _regionController.text.trim());
    await prefs.setString('school_division', _divisionController.text.trim());
    await prefs.setString('school_year', _schoolYearController.text.trim());
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2B2B2B)),
        title: const Text(
          'School Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2B2B2B),
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2B2B2B),
                strokeWidth: 2.5,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InfoPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'These settings are used in printed reports (TOS, Item Analysis) for DepEd-formatted headers.',
                          style: AppTextStyles.cardSubtitleMd,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildField(
                    controller: _schoolNameController,
                    label: 'School Name',
                    hint: 'e.g., Mabini National High School',
                    icon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _regionController,
                    label: 'Region',
                    hint: 'e.g., Region IV-A (CALABARZON)',
                    icon: Icons.map_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _divisionController,
                    label: 'Division',
                    hint: 'e.g., Division of Batangas',
                    icon: Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _schoolYearController,
                    label: 'School Year',
                    hint: 'e.g., 2025-2026',
                    icon: Icons.calendar_today_outlined,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B2B2B),
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
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF999999), size: 20),
          labelStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF999999),
          ),
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFFCCCCCC),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(
          fontSize: 15,
          color: Color(0xFF2B2B2B),
        ),
      ),
    );
  }
}
