import 'package:flutter/material.dart';

/// Troca abas com uma transição curta e mantém apenas a aba ativa montada.
class AnimatedTabBody extends StatelessWidget {
  const AnimatedTabBody({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final keyedChild = KeyedSubtree(key: ValueKey<int>(index), child: child);
    if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
      return keyedChild;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        fit: StackFit.expand,
        children: currentChild == null
            ? const <Widget>[]
            : <Widget>[currentChild],
      ),
      transitionBuilder: (transitionChild, animation) =>
          FadeTransition(opacity: animation, child: transitionChild),
      child: keyedChild,
    );
  }
}
