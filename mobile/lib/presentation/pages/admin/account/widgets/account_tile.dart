import 'package:flutter/material.dart';
import 'package:likha/domain/auth/entities/user.dart';

class AccountTile extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const AccountTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'activated':
        return const Color(0xFF28A745);
      case 'pending_activation':
        return const Color(0xFFFFC107);
      case 'locked':
        return const Color(0xFFDC3545);
      default:
        return const Color(0xFF999999);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'activated':
        return 'Active';
      case 'pending_activation':
        return 'Pending';
      case 'locked':
        return 'Locked';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.fullName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF404040),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202020),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.username} • ${user.role}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(user.accountStatus).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusLabel(user.accountStatus),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(user.accountStatus),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}