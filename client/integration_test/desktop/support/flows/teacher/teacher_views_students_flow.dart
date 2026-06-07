import '../../desktop_pages.dart';

class TeacherViewsStudentsFlow {
  final DesktopPages pages;

  TeacherViewsStudentsFlow(this.pages);

  Future<void> viewClassStudentList({
    required String classTitle,
  }) async {
    await pages.teacherDashboard.waitUntilVisible();
    await pages.teacherDashboard.tapClassByTitle(classTitle);

    await pages.teacherClassDetail.waitUntilVisible(classTitle);
    await pages.teacherClassDetail.tapStudentsTab();

    await pages.teacherClassStudentList.waitUntilVisible();
  }
}
