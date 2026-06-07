import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/core/errors/error_messages.dart';
import 'package:likha/core/sync/sync_manager.dart';
import 'package:likha/presentation/providers/sync_provider.dart';

class SyncLoadingPage extends ConsumerWidget {
  final VoidCallback onContinueOffline;

  const SyncLoadingPage({super.key, required this.onContinueOffline});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final hasFailed = syncState.phase == SyncPhase.failed;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Text(
                'Likha',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentCharcoal,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasFailed
                    ? 'Initial sync failed. You can continue with limited functionality.'
                    : 'Getting everything ready for you…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (hasFailed && AppErrorMapper.toUserMessage(syncState.lastError) != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[200]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Error: ${AppErrorMapper.toUserMessage(syncState.lastError)!}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 48),
              if (!hasFailed) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: syncState.progress > 0 ? syncState.progress : null,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.accentCharcoal,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  syncState.currentStep ?? 'Connecting…',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              if (hasFailed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onContinueOffline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentCharcoal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continue Anyway',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
