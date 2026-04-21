import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primaryOrange = Color(0xFFFFA57D);
  static const Color primaryPink = Color(0xFFFFB4C6);
  static const Color white = Color(0xFFFFFFFF);
  static const Color warmCream = Color(0xFFFFF9F5);
  static const Color paleGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFFA3A3A3);
  static const Color darkGray = Color(0xFF404040);
  static const Color softBlack = Color(0xFF0F0F0F);
  static const Color softPeach = Color(0xFFFFD4B8);
  static const Color pastelCoral = Color(0xFFFFB8A0);
  static const Color powderPink = Color(0xFFFFC9D9);
  static const Color lavender = Color(0xFFE8D4F8);
  static const Color morningLightEnd = Color(0xFFFFE5DD);
  static const Color success = Color(0xFF7FD4A8);
  static const Color warning = Color(0xFFFFD88A);
  static const Color error = Color(0xFFFF9B9B);
  static const Color info = Color(0xFFA8D4FF);

  static const Color transparent = Color(0x00000000);
  static const Color shadow = Color(0x14000000);

  // Legacy aliases kept to avoid breaking the existing codebase structure.
  static const Color blush = warmCream;
  static const Color mist = paleGray;
  static const Color ivory = warmCream;
  static const Color surface = white;
  static const Color surfaceSoft = warmCream;
  static const Color peach = softPeach;
  static const Color rose = primaryPink;
  static const Color sage = success;
  static const Color ink = darkGray;
  static const Color mutedInk = mediumGray;
  static const Color border = paleGray;
}
