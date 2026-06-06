import '../../mobile_pages.dart';

class SchoolSettingsFlow {
  final MobilePages pages;

  SchoolSettingsFlow(this.pages);

  Future<void> updateSchoolSettings({
    required String schoolName,
    String? region,
    String? division,
    String? schoolYear,
    String? schoolCode,
  }) async {
    await pages.adminDashboard.tapSchoolSettings();
    await pages.schoolSettings.waitUntilVisible();
    await pages.schoolSettings.enterSchoolName(schoolName);
    if (region != null) await pages.schoolSettings.enterRegion(region);
    if (division != null) await pages.schoolSettings.enterDivision(division);
    if (schoolYear != null) await pages.schoolSettings.enterSchoolYear(schoolYear);
    if (schoolCode != null) {
      await pages.schoolSettings.enterSchoolCode(schoolCode);
    }
    await pages.schoolSettings.tapSaveSettings();
    if (schoolCode != null) {
      await pages.schoolSettings.confirmCodeChangeDialog();
    }
    pages.schoolSettings.expectPageVisible();
  }
}
