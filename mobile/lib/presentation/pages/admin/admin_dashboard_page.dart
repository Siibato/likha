import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/admin/account_management_page.dart';
import 'package:likha/presentation/pages/admin/create_account_page.dart';
import 'package:likha/presentation/pages/admin/widgets/admin_header.dart';
import 'package:likha/presentation/pages/admin/widgets/dashboard_card.dart';
import 'package:likha/presentation/providers/auth_provider.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF202020),
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF404040),
            ),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminHeader(
              fullName: authState.user?.fullName ?? 'Admin',
            ),
            const SizedBox(height: 32),
            DashboardCard(
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
            DashboardCard(
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
          ],
        ),
      ),
    );
  }
}