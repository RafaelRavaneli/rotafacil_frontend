import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key, this.dataUrl, this.radius = 44});

  final String? dataUrl;
  final double radius;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Uint8List? bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dataUrl != widget.dataUrl) {
      _decode();
    }
  }

  void _decode() {
    bytes = null;

    final value = widget.dataUrl?.trim();

    if (value == null || !value.startsWith('data:image')) {
      return;
    }

    final comma = value.indexOf(',');

    if (comma <= 0 || comma >= value.length - 1) {
      return;
    }

    try {
      bytes = base64Decode(value.substring(comma + 1));
    } catch (_) {
      bytes = null;
    }
  }

  bool _isNetworkImage(String value) {
    final uri = Uri.tryParse(value);

    if (uri == null) {
      return false;
    }

    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  Widget _fallback() {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.green100,
      child: Icon(
        Icons.person_rounded,
        size: widget.radius,
        color: AppColors.green700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBytes = bytes;

    if (currentBytes != null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: AppColors.green100,
        backgroundImage: MemoryImage(currentBytes),
      );
    }

    final value = widget.dataUrl?.trim();

    if (value != null && value.isNotEmpty && _isNetworkImage(value)) {
      final size = widget.radius * 2;

      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.network(
            value,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) {
              return Container(
                color: AppColors.green100,
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_rounded,
                  size: widget.radius,
                  color: AppColors.green700,
                ),
              );
            },
          ),
        ),
      );
    }

    return _fallback();
  }
}
