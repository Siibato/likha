import '../../desktop_pages.dart';

class AdminLockUnlockFlow {
  final DesktopPages pages;

  AdminLockUnlockFlow(this.pages);

  Future<void> lockAccount(String fullName) async {
    await pages.adminShell.tapAccounts();
    await pages.accountManagement.waitUntilVisible();
    await pages.accountManagement.tapLockAccount(fullName);
  }

  Future<void> unlockAccount(String fullName) async {
    await pages.adminShell.tapAccounts();
    await pages.accountManagement.waitUntilVisible();
    await pages.accountManagement.tapUnlockAccount(fullName);
  }
}
