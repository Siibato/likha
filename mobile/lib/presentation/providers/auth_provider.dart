import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likha/injection_container.dart';
import 'package:likha/domain/auth/usecases/activate_account.dart';
import 'package:likha/domain/auth/usecases/check_username.dart';
import 'package:likha/domain/auth/usecases/get_current_user.dart';
import 'package:likha/domain/auth/usecases/login.dart';
import 'package:likha/domain/auth/usecases/logout.dart';
import 'auth_notifier.dart';

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    sl<Login>(),
    sl<Logout>(),
    sl<GetCurrentUser>(),
    sl<CheckUsername>(),
    sl<ActivateAccount>(),
  );
});
