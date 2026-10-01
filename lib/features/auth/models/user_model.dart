import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' | 'user'
  final String? phone;
  final String? avatar;
  final String? fcmToken;
  final DateTime? emailVerifiedAt;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.avatar,
    this.fcmToken,
    this.emailVerifiedAt,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      fcmToken: json['fcm_token'] as String?,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'])
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'avatar': avatar,
        'fcm_token': fcmToken,
        'email_verified_at': emailVerifiedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phone,
    String? avatar,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      fcmToken: fcmToken ?? this.fcmToken,
      emailVerifiedAt: emailVerifiedAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, phone, avatar];
}

class AuthState {
  final bool isAuthenticated;
  final UserModel? user;
  final String? token;

  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.token,
  });

  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({
    bool? isAuthenticated,
    UserModel? user,
    String? token,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      token: token ?? this.token,
    );
  }
}
