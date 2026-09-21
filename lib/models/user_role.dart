enum UserRole {
  tourist,
  guide,
  agency,
}

extension UserRoleX on UserRole {
  String get title {
    switch (this) {
      case UserRole.tourist:
        return 'Turista';
      case UserRole.guide:
        return 'Guia';
      case UserRole.agency:
        return 'Agência';
    }
  }

  String get apiValue {
    switch (this) {
      case UserRole.tourist:
        return 'usuario';
      case UserRole.guide:
        return 'guia';
      case UserRole.agency:
        return 'agencia';
    }
  }
}
