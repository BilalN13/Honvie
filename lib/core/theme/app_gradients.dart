import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  static const LinearGradient sunsetWarm = LinearGradient(
    colors: <Color>[AppColors.primaryOrange, AppColors.primaryPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient peachDream = LinearGradient(
    colors: <Color>[AppColors.softPeach, AppColors.powderPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient eveningGlow = LinearGradient(
    colors: <Color>[AppColors.pastelCoral, AppColors.lavender],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient morningLight = LinearGradient(
    colors: <Color>[AppColors.warmCream, AppColors.morningLightEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
