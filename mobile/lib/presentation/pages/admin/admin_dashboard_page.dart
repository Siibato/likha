import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/admin/account_management_page.dart';
import 'package:likha/presentation/pages/admin/admin_classes_page.dart';
import 'package:likha/presentation/pages/admin/create_account_page.dart';
import 'package:likha/presentation/pages/shared/class_section_header.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/navigation_card.dart';
import 'package:likha/presentation/providers/auth_provider.dart';
import 'package:likha/presentation/utils/logout_helper.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassSectionHeader(
                title: 'Admin Dashboard',
                fontSize: 28,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NavigationCard(
                      icon: Icons.class_outlined,
                      title: 'Class Management',
                      subtitle: 'Create classes and manage student enrollment',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminClassesPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    NavigationCard(
                      icon: Icons.people_outline_rounded,
                      title: 'Account Management',
                      subtitle: 'View and manage all user accounts',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountManagementPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    NavigationCard(
                      icon: Icons.person_add_outlined,
                      title: 'Create Account',
                      subtitle: 'Create a new teacher or student account',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateAccountPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () => handleLogoutTap(context, ref),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.logout_rounded, color: Color(0xFF404040), size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      'Log out',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF202020),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}