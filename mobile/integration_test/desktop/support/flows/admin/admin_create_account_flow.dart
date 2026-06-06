import '../../desktop_pages.dart';

class AdminCreateAccountFlow {
  final DesktopPages pages;

  AdminCreateAccountFlow(this.pages);

  Future<void> createStudentAccount({
    required String username,
    required String fullName,
  }) async {
    await pages.adminShell.tapAccounts();
    await pages.accountManagement.waitUntilVisible();
    await pages.accountManagement.tapCreateAccount();
    await pages.createAccount.waitUntilVisible();
    await pages.createAccount.enterUsername(username);
    await pages.createAccount.enterFullName(fullName);
    await pages.createAccount.selectRole('Student');
    await pages.createAccount.tapCreateAccount();
    await pages.accountManagement.waitUntilVisible();
  }
}
