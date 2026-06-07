import '../../mobile_pages.dart';

class ClassDeleteFlow {
  final MobilePages pages;

  ClassDeleteFlow(this.pages);

  Future<void> deleteClass(String classTitle) async {
    await pages.adminDashboard.tapClassManagement();
    await pages.classManagement.waitUntilVisible();
    await pages.classManagement.tapClassByTitle(classTitle);
    await pages.classDetail.waitUntilVisible(classTitle);
    await pages.classDetail.tapDelete();
    await pages.classDetail.confirmDeleteDialog();
    await pages.classManagement.waitUntilVisible();
    pages.classManagement.expectClassNotVisible(classTitle);
  }
}
