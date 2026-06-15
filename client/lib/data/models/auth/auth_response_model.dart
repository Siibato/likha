import 'package:likha/data/models/auth/user_model.dart';

class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserModel user;
  
  AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });
  
  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'expires_in': expiresIn,
      'user': user.toJson(),
    };
  }
}