import '../../domain/entities/user_entity.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? cpf;
  final String? phone;
  final String? photo;
  final String? bio;
  final bool mfaEnabled;
  final bool mfaRequired;
  final bool changePasswordRequired;
  final bool isDeveloper;
  final List<String> roles;
  final List<String> permissions;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.cpf,
    this.phone,
    this.photo,
    this.bio,
    this.mfaEnabled = false,
    this.mfaRequired = false,
    this.changePasswordRequired = false,
    this.isDeveloper = false,
    this.roles = const [],
    this.permissions = const [],
  });

  /// Converte valores do backend (bool, int 0/1, String "0"/"1") para bool.
  static bool _toBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return fallback;
  }

  factory UserModel.fromLoginJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return UserModel(
      id: user['id'] as int,
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
      cpf: user['cpf'] as String?,
      phone: user['phone'] as String?,
      photo: user['photo'] as String?,
      bio: user['bio'] as String?,
      mfaEnabled: _toBool(user['mfa_enabled']),
      mfaRequired: _toBool(user['mfa_required']),
      changePasswordRequired: _toBool(user['change_password_required']),
      isDeveloper: _toBool(user['is_developer']),
      roles: const [],
      permissions: const [],
    );
  }

  factory UserModel.fromMeJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;

    List<String> parseStringList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return UserModel(
      id: user['id'] as int,
      name: user['name'] as String? ?? '',
      email: user['email'] as String? ?? '',
      cpf: user['cpf'] as String?,
      phone: user['phone'] as String?,
      photo: user['photo'] as String?,
      bio: user['bio'] as String?,
      mfaEnabled: _toBool(user['mfa_enabled']),
      mfaRequired: _toBool(user['mfa_required']),
      changePasswordRequired: _toBool(user['change_password_required']),
      isDeveloper: _toBool(user['is_developer']),
      roles: parseStringList(json['roles']),
      permissions: parseStringList(json['permissions']),
    );
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        name: name,
        email: email,
        cpf: cpf,
        phone: phone,
        photo: photo,
        bio: bio,
        mfaEnabled: mfaEnabled,
        mfaRequired: mfaRequired,
        changePasswordRequired: changePasswordRequired,
        isDeveloper: isDeveloper,
        roles: roles,
        permissions: permissions,
      );
}
