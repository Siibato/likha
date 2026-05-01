import 'package:flutter/material.dart';
import 'package:likha/core/theme/app_colors.dart';
import 'package:likha/presentation/widgets/shared/tokens/app_text_styles.dart';

/// Full-abstraction mobile page scaffold for Likha LMS.
///
/// Standardises: background color, AppBar style, scrollability, tab support,
/// FAB slot, and loading / error overlay states.
class MobilePageScaffold extends StatelessWidget {
  /// Page / AppBar title.
  final String title;

  /// Optional subtitle shown below the title inside the AppBar.
  final String? subtitle;

  /// AppBar trailing action widgets.
  final List<Widget>? actions;

  /// Override the default back button / leading widget.
  final Widget? leading;

  /// Main page content.
  final Widget body;

  /// Scaffold background color. Defaults to [AppColors.backgroundSecondary].
  final Color? backgroundColor;

  /// When true, wraps [body] in a [SingleChildScrollView].
  final bool scrollable;

  /// Optional [TabBar] displayed at the bottom of the AppBar.
  final TabBar? tabBar;

  /// Required when [tabBar] is provided.
  final TabController? tabController;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// When true, shows a centered loading indicator over the body.
  final bool isLoading;

  /// When non-null, shows an error message over the body.
  final String? error;

  /// Called when the user taps retry on the error state.
  final VoidCallback? onRetry;

  const MobilePageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    required this.body,
    this.backgroundColor,
    this.scrollable = true,
    this.tabBar,
    this.tabController,
    this.floatingActionButton,
    this.isLoading = false,
    this.error,
    this.onRetry,
  }) : assert(
          tabBar == null || tabController != null,
          'tabController is required when tabBar is provided',
        );

  Widget _buildAppBarTitle() {
    if (subtitle == null) {
      return Text(title, style: AppTextStyles.mobilePageTitle);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: AppTextStyles.mobilePageTitle),
        Text(subtitle!, style: AppTextStyles.mobilePageSubtitle),
      ],
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.accentCharcoal,
          strokeWidth: 2.5,
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.foregroundTertiary,
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                style: AppTextStyles.cardSubtitleMd,
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (scrollable) {
      return SingleChildScrollView(child: body);
    }

    return body;
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: leading,
      title: _buildAppBarTitle(),
      actions: actions,
      bottom: tabBar,
    );

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.backgroundSecondary,
      appBar: appBar,
      body: _buildBody(),
      floatingActionButton: floatingActionButton,
    );
  }
}
