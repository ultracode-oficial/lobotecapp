import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
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

  const UserEntity({
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

  String get primaryRole => roles.isNotEmpty ? roles.first : '';

  bool hasPermission(String permission) => permissions.contains(permission);
  bool hasRole(String role) => roles.contains(role);

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        cpf,
        phone,
        photo,
        bio,
        mfaEnabled,
        mfaRequired,
        changePasswordRequired,
        isDeveloper,
        roles,
        permissions,
      ];
}
