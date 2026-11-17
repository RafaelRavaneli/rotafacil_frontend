import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/app_back_button.dart';

/// Ajuste da foto de perfil: o usuário arrasta e usa o zoom para enquadrar a
/// foto no círculo e confirma. Devolve a imagem recortada (PNG, quadrada) ou
/// `null` se cancelar.
class PhotoCropScreen extends StatefulWidget {
  const PhotoCropScreen({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  static const _outputSize = 400.0;
  static const _maxZoom = 4.0;

  final _controller = TransformationController();
  final _captureKey = GlobalKey();

  Size? _imageSize;
  double _side = 0;
  Size _child = Size.zero;
  double _zoom = 1;
  bool _placed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTransform);
    unawaited(_loadSize());
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransform);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSize() async {
    final image = await decodeImageFromList(widget.imageBytes);
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    if (!mounted) return;
    setState(() => _imageSize = size);
  }

  void _onTransform() {
    final zoom = _controller.value
        .getMaxScaleOnAxis()
        .clamp(1.0, _maxZoom)
        .toDouble();
    if ((zoom - _zoom).abs() > .001) setState(() => _zoom = zoom);
  }

  // Zoom pelo controle deslizante, sempre em torno do centro do círculo.
  void _setZoom(double target) {
    final side = _side;
    if (side <= 0) return;
    final current = _controller.value.getMaxScaleOnAxis();
    final ratio = target.clamp(1.0, _maxZoom).toDouble() / current;
    final center = side / 2;
    final matrix =
        Matrix4.translationValues(center, center, 0) *
        Matrix4.diagonal3Values(ratio, ratio, 1) *
        Matrix4.translationValues(-center, -center, 0) *
        _controller.value;
    final scale = matrix.getMaxScaleOnAxis();
    // Mantém a foto sempre cobrindo todo o círculo.
    final tx = matrix.storage[12]
        .clamp(side - _child.width * scale, 0.0)
        .toDouble();
    final ty = matrix.storage[13]
        .clamp(side - _child.height * scale, 0.0)
        .toDouble();
    _controller.value = Matrix4(
      scale,
      0,
      0,
      0, //
      0,
      scale,
      0,
      0, //
      0,
      0,
      1,
      0, //
      tx,
      ty,
      0,
      1,
    );
  }

  Future<void> _confirm() async {
    final boundary =
        _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null || _side <= 0) return;
    setState(() => _saving = true);
    try {
      final image = await boundary.toImage(pixelRatio: _outputSize / _side);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('Imagem vazia.');
      if (!mounted) return;
      Navigator.pop(context, data.buffer.asUint8List());
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível ajustar a foto. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text(
          'Ajustar foto',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final image = _imageSize;
                  if (image == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final side = (constraints.biggest.shortestSide - 32)
                      .clamp(120.0, 520.0)
                      .toDouble();
                  final shortest = image.width < image.height
                      ? image.width
                      : image.height;
                  final factor = side / shortest;
                  final childSize = Size(
                    image.width * factor,
                    image.height * factor,
                  );
                  _side = side;
                  _child = childSize;
                  if (!_placed) {
                    _placed = true;
                    // Começa com a foto centralizada no círculo.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _controller.value = Matrix4.translationValues(
                        (side - childSize.width) / 2,
                        (side - childSize.height) / 2,
                        0,
                      );
                    });
                  }
                  return Center(
                    child: SizedBox(
                      width: side,
                      height: side,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: RepaintBoundary(
                              key: _captureKey,
                              child: ClipRect(
                                child: InteractiveViewer(
                                  transformationController: _controller,
                                  constrained: false,
                                  minScale: 1,
                                  maxScale: _maxZoom,
                                  boundaryMargin: EdgeInsets.zero,
                                  child: Image.memory(
                                    widget.imageBytes,
                                    width: childSize.width,
                                    height: childSize.height,
                                    fit: BoxFit.fill,
                                    gaplessPlayback: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(painter: _CircleMaskPainter()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Arraste a foto e use o zoom para enquadrar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.zoom_out, color: AppColors.leaf),
                  Expanded(
                    child: Slider(
                      min: 1,
                      max: _maxZoom,
                      value: _zoom.clamp(1.0, _maxZoom).toDouble(),
                      onChanged: _imageSize == null ? null : _setZoom,
                    ),
                  ),
                  const Icon(Icons.zoom_in, color: AppColors.leaf),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving || _imageSize == null
                          ? null
                          : _confirm,
                      child: Text(_saving ? 'Processando...' : 'Usar foto'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Escurece fora do círculo, mostrando a área que ficará na foto de perfil.
class _CircleMaskPainter extends CustomPainter {
  const _CircleMaskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final mask = Path()
      ..addRect(Offset.zero & size)
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(mask, Paint()..color = const Color(0x99000000));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white70,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
