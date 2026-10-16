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
  final bool hasIssues;
  final int issuesCount;
  final int bookingCount;
  final List<Map<String, dynamic>>? issues;

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
    this.hasIssues = false,
    this.issuesCount = 0,
    this.bookingCount = 0,
    this.issues,
  });

  static const String _masterAdminEmail = 'erickkelwa9@gmail.com';

  bool get isAdmin => role == 'admin' || email.toLowerCase() == _masterAdminEmail;
  bool get isUser => role == 'user';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final issuesList = json['issues'] as List?;
    return UserModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
      fcmToken: json['fcm_token'] as String?,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'])
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      hasIssues: json['has_issues'] as bool? ?? (issuesList != null && issuesList.isNotEmpty),
      issuesCount: issuesList?.length ?? (json['has_issues'] == true ? 1 : 0),
      bookingCount: json['bookings_count'] as int? ?? 0,
      issues: issuesList?.map((i) => Map<String, dynamic>.from(i)).toList(),
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
    int? bookingCount,
    bool? hasIssues,
    int? issuesCount,
    List<Map<String, dynamic>>? issues,
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
      bookingCount: bookingCount ?? this.bookingCount,
      hasIssues: hasIssues ?? this.hasIssues,
      issuesCount: issuesCount ?? this.issuesCount,
      issues: issues ?? this.issues,
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
