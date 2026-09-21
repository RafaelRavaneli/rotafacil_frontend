import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NetworkImageBox extends StatefulWidget {
  const NetworkImageBox({
    super.key,
    required this.url,
    this.borderRadius = 18,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double borderRadius;
  final BoxFit fit;

  @override
  State<NetworkImageBox> createState() =>
      _NetworkImageBoxState();
}

class _NetworkImageBoxState
    extends State<NetworkImageBox> {
  Uint8List? bytes;

  @override
  void initState() {
    super.initState();
    _decodeIfNeeded();
  }

  @override
  void didUpdateWidget(
    NetworkImageBox oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      _decodeIfNeeded();
    }
  }

  void _decodeIfNeeded() {
    bytes = null;

    if (!widget.url.startsWith('data:image')) {
      return;
    }

    final comma = widget.url.indexOf(',');

    if (comma < 0 ||
        comma >= widget.url.length - 1) {
      return;
    }

    try {
      bytes = base64Decode(
        widget.url.substring(comma + 1),
      );
    } catch (_) {
      bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localBytes = bytes;

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(
        widget.borderRadius,
      ),
      child: localBytes != null
          ? Image.memory(
              localBytes,
              fit: widget.fit,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              filterQuality:
                  FilterQuality.medium,
            )
          : Image.network(
              widget.url,
              fit: widget.fit,
              width: double.infinity,
              height: double.infinity,
              filterQuality:
                  FilterQuality.medium,
              errorBuilder:
                  (context, error, stackTrace) {
                return Container(
                  color: AppColors.green100,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.landscape_rounded,
                    color: AppColors.green700,
                    size: 42,
                  ),
                );
              },
            ),
    );
  }
}
