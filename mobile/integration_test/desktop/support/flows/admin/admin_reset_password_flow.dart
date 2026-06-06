import '../../desktop_pages.dart';

class AdminResetPasswordFlow {
  final DesktopPages pages;

  AdminResetPasswordFlow(this.pages);

  Future<void> resetPassword(String fullName) async {
    await pages.adminShell.tapAccounts();
    await pages.accountManagement.waitUntilVisible();
    await pages.accountManagement.tapResetPassword(fullName);
    await pages.accountManagement.waitUntilVisible();
  }
}
