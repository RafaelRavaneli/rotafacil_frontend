import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';

/// Identidade visual compartilhada por todo o fluxo anterior à home.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.body, required this.title});
  final Widget body;
  final String title;
  static const accent = Color(0xFFD2FA87);
  static const olive = Color(0xFF4F682B);

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/auth_background.png',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          excludeFromSemantics: true,
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 26, 32, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          const Align(
                            alignment: Alignment.center,
                            child: AppLogo(iconOnly: true),
                          ),
                          if (Navigator.canPop(context))
                            Align(
                              alignment: Alignment.centerLeft,
                              child: BackButton(color: olive),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: olive,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF343A2E,
                              ).withValues(alpha: .48),
                              border: Border.all(color: accent, width: 1.5),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Theme(
                              data: base.copyWith(
                                textTheme: base.textTheme.apply(
                                  bodyColor: AppColors.paper,
                                  displayColor: AppColors.paper,
                                ),
                                inputDecorationTheme: base.inputDecorationTheme
                                    .copyWith(
                                      fillColor: const Color(0xFFFFFEF7),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(9),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCFD5C4),
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(9),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFCFD5C4),
                                        ),
                                      ),
                                    ),
                                filledButtonTheme: FilledButtonThemeData(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: olive,
                                    foregroundColor: AppColors.paper,
                                  ),
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: accent,
                                  ),
                                ),
                              ),
                              child: Material(
                                type: MaterialType.transparency,
                                child: _AuthEntrance(child: body),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthEntrance extends StatelessWidget {
  const _AuthEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations == true) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: animatedChild,
        ),
      ),
      child: child,
    );
  }
}

class AuthLabeledField extends StatelessWidget {
  const AuthLabeledField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AuthScaffold.accent, fontSize: 13),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}
