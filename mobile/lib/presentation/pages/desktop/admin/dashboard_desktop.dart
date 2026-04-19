import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/presentation/pages/desktop/admin/account/create_account_desktop.dart';
import 'package:likha/presentation/pages/desktop/admin/widgets/admin_stats_row.dart';
import 'package:likha/presentation/pages/desktop/core/desktop_page_scaffold.dart';
import 'package:likha/presentation/pages/shared/widgets/cards/navigation_card.dart';
import 'package:likha/presentation/providers/admin_provider.dart';

class AdminDashboardDesktop extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigate;

  const AdminDashboardDesktop({super.key, this.onNavigate});

  @override
  ConsumerState<AdminDashboardDesktop> createState() =>
      _AdminDashboardDesktopState();
}

class _AdminDashboardDesktopState
    extends ConsumerState<AdminDashboardDesktop> {
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
              color: Color(0xFF202020),
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
                      builder: (_) => const CreateAccountDesktop(),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 380,
                child: NavigationCard(
                  icon: Icons.settings_outlined,
                  title: 'School Settings',
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
