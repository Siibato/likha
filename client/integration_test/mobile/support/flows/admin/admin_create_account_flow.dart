import '../../mobile_pages.dart';

class AdminCreateAccountFlow {
  final MobilePages pages;

  AdminCreateAccountFlow(this.pages);

  Future<void> createStudentAccount({
    required String username,
    required String fullName,
  }) async {
    await pages.adminDashboard.tapCreateAccount();
    await pages.createAccount.waitUntilVisible();
    await pages.createAccount.enterUsername(username);
    await pages.createAccount.enterFullName(fullName);
    await pages.createAccount.selectRole('Student');
    await pages.createAccount.tapCreateAccount();
    await pages.adminDashboard.waitUntilVisible();
  }
}
