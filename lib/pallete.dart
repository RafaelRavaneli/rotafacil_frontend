import 'package:flutter/material.dart';

class Pallete {
  static const Color herb = Color(0xFF6A8042);

  static const Color gleam = Color(0xFFFFE787);

  static const Color pearl = Color(0xFFFFFADD);

  static const Color radiate = Color(0xFFED7A13);

  static const Color moss = Color(0xFF1E3006);

  static const Color white = Color(0xFFFFFFFF);

  static const Color black = Color(0xFF000000);

  static const Color inputBorder = Color(0xFFD4CCB5);

  static const LinearGradient gradient = LinearGradient(
    colors: [
      herb,
      moss,
    ],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
}