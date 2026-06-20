import '../../mobile_pages.dart';

class SchoolDetailsFlow {
  final MobilePages pages;

  SchoolDetailsFlow(this.pages);

  Future<void> updateSchoolDetails({
    required String schoolName,
    String? region,
    String? division,
    String? schoolYear,
    String? schoolCode,
  }) async {
    await pages.adminDashboard.tapSchoolDetails();
    await pages.schoolDetails.waitUntilVisible();
    await pages.schoolDetails.enterSchoolName(schoolName);
    if (region != null) await pages.schoolDetails.enterRegion(region);
    if (division != null) await pages.schoolDetails.enterDivision(division);
    if (schoolYear != null) await pages.schoolDetails.enterSchoolYear(schoolYear);
    if (schoolCode != null) {
      await pages.schoolDetails.enterSchoolCode(schoolCode);
    }
    await pages.schoolDetails.tapSaveSettings();
    if (schoolCode != null) {
      await pages.schoolDetails.confirmCodeChangeDialog();
    }
    pages.schoolDetails.expectPageVisible();
  }
}
