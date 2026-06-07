import '../../mobile_pages.dart';

class ClassCreateAddStudentsFlow {
  final MobilePages pages;

  ClassCreateAddStudentsFlow(this.pages);

  Future<void> createClass({
    required String title,
    required String description,
    required String teacherDisplayName,
  }) async {
    await pages.adminDashboard.tapClassManagement();
    await pages.classManagement.waitUntilVisible();
    await pages.classManagement.tapCreateClass();
    await pages.classCreate.waitUntilVisible();
    await pages.classCreate.enterTitle(title);
    await pages.classCreate.enterDescription(description);
    await pages.classCreate.selectTeacher(teacherDisplayName);
    await pages.classCreate.tapCreateClass();
    await pages.classManagement.waitUntilVisible();
  }

  Future<void> addStudentToClass({
    required String classTitle,
    required String studentFullName,
  }) async {
    await pages.classManagement.tapClassByTitle(classTitle);
    await pages.classDetail.waitUntilVisible(classTitle);
    await pages.classDetail.enterStudentSearch(studentFullName);
    await pages.classDetail.tapAddStudent(studentFullName);
    pages.classDetail.expectStudentEnrolled(studentFullName);
    await pages.classDetail.tapBack();
  }
}
