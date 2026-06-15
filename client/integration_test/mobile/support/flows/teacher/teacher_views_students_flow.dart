import '../../mobile_pages.dart';

class TeacherViewsStudentsFlow {
  final MobilePages pages;

  TeacherViewsStudentsFlow(this.pages);

  Future<void> viewClassStudentList({
    required String classTitle,
  }) async {
    await pages.teacherDashboard.waitUntilVisible();
    await pages.teacherDashboard.tapClassByTitle(classTitle);

    await pages.teacherClassDetail.waitUntilVisible(classTitle);
    await pages.teacherClassDetail.tapStudentsCard();

    await pages.teacherClassStudentList.waitUntilVisible();
  }

  Future<void> viewStudentDetail({
    required String studentFullName,
  }) async {
    await pages.teacherClassStudentList.tapStudentByName(studentFullName);
    await pages.teacherStudentDetail.waitUntilVisible(studentFullName);
  }
}
