import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/pages/desktop/admin/account/create_account_page.dart';
import 'package:likha/presentation/widgets/desktop/admin/dashboard/admin_stats_row.dart';
import 'package:likha/presentation/layouts/desktop/desktop_page_scaffold.dart';
import 'package:likha/presentation/widgets/shared/cards/navigation_card.dart';
import 'package:likha/presentation/providers/admin_provider.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigate;

  const AdminDashboardPage({super.key, this.onNavigate});

  @override
  ConsumerState<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState
    extends ConsumerState<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return DesktopPageScaffold(
      title: 'Dashboard',
      subtitle: 'Welcome to the admin panel',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          AdminStatsRow(accounts: adminState.accounts),
          const SizedBox(height: 32),

          // Quick actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.foregroundDark,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 380,
                child: NavigationCard(
                  icon: Icons.people_outline_rounded,
                  title: 'Account Management',
                  subtitle: 'View and manage all user accounts',
                  onTap: () => widget.onNavigate?.call(1),
                ),
              ),
              SizedBox(
                width: 380,
                child: NavigationCard(
                  icon: Icons.class_outlined,
                  title: 'Class Management',
                  subtitle: 'Create classes and manage enrollment',
                  onTap: () => widget.onNavigate?.call(2),
                ),
              ),
              SizedBox(
                width: 380,
                child: NavigationCard(
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
              ),
              SizedBox(
                width: 380,
                child: NavigationCard(
                  icon: Icons.settings_outlined,
                  title: 'School Details',
                  subtitle: 'Configure school info for printed reports',
                  onTap: () => widget.onNavigate?.call(3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
