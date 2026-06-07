import '../../desktop_pages.dart';

class ClassCreateAddStudentsFlow {
  final DesktopPages pages;

  ClassCreateAddStudentsFlow(this.pages);

  Future<void> createClass({
    required String title,
    required String description,
    required String teacherDisplayName,
  }) async {
    await pages.adminShell.tapClasses();
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
    await pages.classDetail.tapManageEnrollment();
    await pages.manageEnrollment.waitUntilVisible();
    await pages.manageEnrollment.searchStudent(studentFullName);
    await pages.manageEnrollment.tapEnrollStudent(studentFullName);
    pages.manageEnrollment.expectStudentEnrolled(studentFullName);
    await pages.manageEnrollment.tapBack();
    await pages.classDetail.waitUntilVisible(classTitle);
    await pages.classDetail.tapBack();
    await pages.classManagement.waitUntilVisible();
  }
}
