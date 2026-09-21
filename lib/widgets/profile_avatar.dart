import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    super.key,
    this.dataUrl,
    this.radius = 44,
  });

  final String? dataUrl;
  final double radius;

  @override
  State<ProfileAvatar> createState() =>
      _ProfileAvatarState();
}

class _ProfileAvatarState
    extends State<ProfileAvatar> {
  Uint8List? bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(
    ProfileAvatar oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.dataUrl != widget.dataUrl) {
      _decode();
    }
  }

  void _decode() {
    bytes = null;

    final value = widget.dataUrl;

    if (value == null ||
        !value.startsWith('data:image')) {
      return;
    }

    final comma = value.indexOf(',');

    if (comma <= 0 ||
        comma >= value.length - 1) {
      return;
    }

    try {
      bytes = base64Decode(
        value.substring(comma + 1),
      );
    } catch (_) {
      bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBytes = bytes;

    if (currentBytes != null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: AppColors.green100,
        backgroundImage: MemoryImage(
          currentBytes,
        ),
      );
    }

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
}
