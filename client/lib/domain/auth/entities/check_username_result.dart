import 'package:equatable/equatable.dart';

class CheckUsernameResult extends Equatable {
  final String username;
  final String accountStatus;
  final String? fullName;

  const CheckUsernameResult({
    required this.username,
    required this.accountStatus,
    this.fullName,
  });

  bool get isPendingActivation => accountStatus == 'pending_activation';
  bool get isActivated => accountStatus == 'activated';
  bool get isLocked => accountStatus == 'locked';

  @override
  List<Object?> get props => [username, accountStatus, fullName];
}
