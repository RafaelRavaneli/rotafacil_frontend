import 'package:flutter/material.dart';

/// Bloco que pulsa suavemente enquanto o conteúdo real carrega. Dá a forma da
/// tela antes dos dados chegarem, em vez de um espaço vazio ou um indicador
/// girando. Respeita "reduzir movimento" do sistema (fica parado).
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 10,
    this.color = const Color(0xFFE3E8D6),
  });

  final double? width;
  final double height;
  final double radius;
  final Color color;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) {
      _controller
        ..stop()
        ..value = .5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            Opacity(opacity: .45 + .5 * _controller.value, child: child),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

/// Forma de um cartão de roteiro (imagem, título, local e preço).
class TrailCardSkeleton extends StatelessWidget {
  const TrailCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(height: 190, radius: 20),
        SizedBox(height: 14),
        SkeletonBox(width: 200, height: 18),
        SizedBox(height: 10),
        SkeletonBox(width: 130, height: 14),
        SizedBox(height: 10),
        SkeletonBox(width: 90, height: 14),
      ],
    );
  }
}
