import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../theme/app_colors.dart';
import 'auth_scaffold.dart';

/// Cartão de perfil do cadastro. Estado de seleção conforme o Figma:
/// borda lima, nome em lima e check à direita.
class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.role,
    required this.onTap,
    this.selected = false,
    this.dimmed = false,
  });

  final UserRole role;
  final VoidCallback onTap;
  final bool selected;

  /// Outro perfil já está selecionado: este fica com menos destaque.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final data = switch (role) {
      UserRole.tourist => (
        Icons.hiking_rounded,
        'Quero descobrir roteiros e viver novas aventuras.',
      ),
      UserRole.guide => (
        Icons.flag_rounded,
        'Quero compartilhar meu conhecimento e guiar aventureiros.',
      ),
      UserRole.agency => (
        Icons.apartment_rounded,
        'Represento uma agência e organizo experiências para grupos.',
      ),
    };

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF3A3A38).withValues(
                alpha: selected ? .72 : (dimmed ? .35 : .5),
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? AuthScaffold.accent : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAEFDD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(data.$1, color: AppColors.green800, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.title,
                        style: TextStyle(
                          color: selected
                              ? AuthScaffold.accent
                              : (dimmed
                                    ? const Color(0xFF3F5B22)
                                    : const Color(0xFF8DB85A)),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.$2,
                        style: TextStyle(
                          color: AppColors.paper.withValues(alpha: dimmed ? .5 : .82),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check_rounded,
                    color: AuthScaffold.accent,
                    size: 26,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
