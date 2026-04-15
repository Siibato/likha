import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/core/logging/page_logger.dart';
import 'package:likha/presentation/pages/desktop/core/platform_detector.dart';
import 'package:likha/presentation/pages/shared/widgets/auth_desktop_layout.dart';
import 'package:likha/presentation/providers/auth_provider.dart';

class LoginPasswordPage extends ConsumerStatefulWidget {
  const LoginPasswordPage({super.key});

  @override
  ConsumerState<LoginPasswordPage> createState() => _LoginPasswordPageState();
}

class _LoginPasswordPageState extends ConsumerState<LoginPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _errorFormKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleLogin() async {
    final authState = ref.read(authProvider);
    final hasAttempts = authState.attemptsRemaining != null;
    final formKey = hasAttempts ? _errorFormKey : _formKey;
    
    if (!formKey.currentState!.validate()) return;

    final username = authState.loginUsername;
    if (username == null) return;

    await ref.read(authProvider.notifier).login(
          username: username,
          password: _passwordController.text,
        );
  }

  Widget _buildFormBody(
    String username,
    bool isLocked,
    bool isFirstFailedAttempt,
    bool hasAttempts,
    bool isLoading,
    int? lockoutRemainingSeconds,
    int? attemptsRemaining,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // State A: Lockout
          if (isLocked) ...[
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDED),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 56,
                color: Color(0xFFDC3545),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Too many failed attempts',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF202020),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Try again in ${_formatTime(lockoutRemainingSeconds!)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF999999),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            TextButton(
              onPressed: () {
                ref.read(authProvider.notifier).clearLoginUsername();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2B2B2B),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Use a different username',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]
          // State B1: First failed attempt (simple error message without counter)
          else if (isFirstFailedAttempt) ...[
            Form(
              key: _errorFormKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/likha-logo.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202020),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Signing in as $username',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF999999),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Red banner with error message (no counter)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFDC3545),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Password is incorrect',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC3545),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPasswordField(isLoading),
                  const SizedBox(height: 16),
                  _buildLoginButton(isLoading),
                  const SizedBox(height: 16),
                  _buildBackButton(isLoading),
                ],
              ),
            ),
          ]
          // State B2: Retrying with attempts counter (2nd+ failed attempt)
          else if (hasAttempts) ...[
            Form(
              key: _errorFormKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/likha-logo.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202020),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Signing in as $username',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF999999),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Red banner with error message and counter
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFDC3545),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Password is incorrect',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC3545),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$attemptsRemaining attempt(s) remaining before lockout',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFDC3545),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPasswordField(isLoading),
                  const SizedBox(height: 24),
                  _buildLoginButton(isLoading),
                  const SizedBox(height: 16),
                  _buildBackButton(isLoading),
                ],
              ),
            ),
          ]
          // State C: Normal
          else ...[
            Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/likha-logo.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF202020),
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Signing in as $username',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF999999),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  _buildPasswordField(isLoading),
                  const SizedBox(height: 24),
                  _buildLoginButton(isLoading),
                  const SizedBox(height: 16),
                  _buildBackButton(isLoading),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordField(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        child: TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF202020),
          ),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF999999),
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF999999),
              size: 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF999999),
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFF2B2B2B),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your password';
            }
            return null;
          },
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          enabled: !isLoading,
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: isLoading ? const Color(0xFFE0E0E0) : const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(1, 1, 1, 3.5),
        child: ElevatedButton(
          onPressed: isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isLoading ? const Color(0xFFF5F5F5) : const Color(0xFF2B2B2B),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF999999),
                  ),
                )
              : const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBackButton(bool isLoading) {
    return TextButton(
      onPressed: isLoading
          ? null
          : () {
              ref.read(authProvider.notifier).clearLoginUsername();
            },
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF2B2B2B),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text(
        'Use a different username',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final username = authState.loginUsername ?? '';
    final isLocked = authState.lockoutRemainingSeconds != null;
    final isFirstFailedAttempt = authState.attemptsRemaining == 5;
    final hasAttempts = authState.attemptsRemaining != null && authState.attemptsRemaining! < 5;
    PageLogger.instance.log('LoginPasswordPage build - attemptsRemaining: ${authState.attemptsRemaining}, isFirstFailedAttempt: $isFirstFailedAttempt, hasAttempts: $hasAttempts, isLocked: $isLocked');

    final formBody = _buildFormBody(
      username,
      isLocked,
      isFirstFailedAttempt,
      hasAttempts,
      authState.isLoading,
      authState.lockoutRemainingSeconds,
      authState.attemptsRemaining,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: PlatformDetector.isDesktop
          ? AuthDesktopLayout(formContent: formBody)
          : SafeArea(child: Center(child: formBody)),
    );
  }
}
