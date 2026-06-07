import '../../mobile_pages.dart';

class ClassReassignTeacherFlow {
  final MobilePages pages;

  ClassReassignTeacherFlow(this.pages);

  Future<void> reassignTeacher({
    required String classTitle,
    required String newTeacherDisplayName,
  }) async {
    await pages.adminDashboard.tapClassManagement();
    await pages.classManagement.waitUntilVisible();
    await pages.classManagement.tapClassByTitle(classTitle);
    await pages.classDetail.waitUntilVisible(classTitle);
    await pages.classDetail.tapEdit();
    await pages.classEdit.waitUntilVisible();
    await pages.classEdit.selectTeacher(newTeacherDisplayName);
    await pages.classEdit.tapSaveChanges();
  }
}
