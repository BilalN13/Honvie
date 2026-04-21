import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';

enum ExploreMarkerKind {
  defaultPlace,
  recommendedPlace,
  userPlace,
  topRecommendation,
  event,
}

abstract final class ExploreMarkerFactory {
  static const Size _defaultPlaceLogicalSize = Size(44, 58);
  static const Size _topRecommendationLogicalSize = Size(54, 72);
  static const Size _eventLogicalSize = Size(40, 52);

  static Future<BitmapDescriptor> createMarker({
    required double devicePixelRatio,
    required IconData glyph,
    required ExploreMarkerKind kind,
  }) async {
    final spec = _MarkerVisualSpec.forKind(kind);
    final logicalSize = spec.logicalSize;
    final pixelRatio = devicePixelRatio <= 0 ? 1.0 : devicePixelRatio;
    final canvasSize = Size(
      logicalSize.width * pixelRatio,
      logicalSize.height * pixelRatio,
    );

    final byteData = await _drawMarkerBytes(
      size: canvasSize,
      spec: spec,
      glyph: glyph,
    );

    return BytesMapBitmap(
      byteData.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
      width: logicalSize.width,
      height: logicalSize.height,
      bitmapScaling: MapBitmapScaling.auto,
    );
  }

  static Future<ByteData> _drawMarkerBytes({
    required Size size,
    required _MarkerVisualSpec spec,
    required IconData glyph,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = _ExploreMarkerPainter(spec: spec, glyph: glyph);

    painter.paint(canvas, size);

    final image = await recorder.endRecording().toImage(
      size.width.ceil(),
      size.height.ceil(),
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!;
  }
}

class _MarkerVisualSpec {
  const _MarkerVisualSpec({
    required this.logicalSize,
    required this.fillColor,
    required this.borderColor,
    required this.glyphColor,
    this.haloColor,
  });

  final Size logicalSize;
  final Color fillColor;
  final Color borderColor;
  final Color glyphColor;
  final Color? haloColor;

  static _MarkerVisualSpec forKind(ExploreMarkerKind kind) {
    switch (kind) {
      case ExploreMarkerKind.defaultPlace:
        return const _MarkerVisualSpec(
          logicalSize: ExploreMarkerFactory._defaultPlaceLogicalSize,
          fillColor: AppColors.softPeach,
          borderColor: AppColors.white,
          glyphColor: AppColors.softBlack,
        );
      case ExploreMarkerKind.recommendedPlace:
        return const _MarkerVisualSpec(
          logicalSize: ExploreMarkerFactory._defaultPlaceLogicalSize,
          fillColor: AppColors.primaryOrange,
          borderColor: AppColors.white,
          glyphColor: AppColors.softBlack,
        );
      case ExploreMarkerKind.userPlace:
        return const _MarkerVisualSpec(
          logicalSize: ExploreMarkerFactory._defaultPlaceLogicalSize,
          fillColor: AppColors.primaryPink,
          borderColor: AppColors.white,
          glyphColor: AppColors.softBlack,
        );
      case ExploreMarkerKind.topRecommendation:
        return const _MarkerVisualSpec(
          logicalSize: ExploreMarkerFactory._topRecommendationLogicalSize,
          fillColor: AppColors.primaryOrange,
          borderColor: AppColors.white,
          glyphColor: AppColors.softBlack,
          haloColor: AppColors.powderPink,
        );
      case ExploreMarkerKind.event:
        return const _MarkerVisualSpec(
          logicalSize: ExploreMarkerFactory._eventLogicalSize,
          fillColor: AppColors.info,
          borderColor: AppColors.white,
          glyphColor: AppColors.softBlack,
        );
    }
  }
}

class _ExploreMarkerPainter extends CustomPainter {
  const _ExploreMarkerPainter({required this.spec, required this.glyph});

  final _MarkerVisualSpec spec;
  final IconData glyph;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final center = Offset(width / 2, width * 0.42);
    final radius = width * 0.27;
    final strokeWidth = width * 0.06;
    final tailHalfWidth = width * 0.11;
    final tailTopY = center.dy + radius * 0.72;
    final tailControlY = height - width * 0.20;
    final tip = Offset(width / 2, height - width * 0.06);

    final tailPath = Path()
      ..moveTo(center.dx - tailHalfWidth, tailTopY)
      ..quadraticBezierTo(
        center.dx - tailHalfWidth * 0.35,
        tailControlY,
        tip.dx,
        tip.dy,
      )
      ..quadraticBezierTo(
        center.dx + tailHalfWidth * 0.35,
        tailControlY,
        center.dx + tailHalfWidth,
        tailTopY,
      )
      ..close();

    final circleRect = Rect.fromCircle(center: center, radius: radius);
    final markerPath = Path()
      ..addPath(tailPath, Offset.zero)
      ..addOval(circleRect);

    if (spec.haloColor != null) {
      canvas.drawCircle(
        center,
        radius * 1.34,
        Paint()..color = spec.haloColor!.withValues(alpha: 0.38),
      );
    }

    canvas.drawShadow(
      markerPath,
      Colors.black.withValues(alpha: 0.28),
      width * 0.12,
      true,
    );

    final fillPaint = Paint()..color = spec.fillColor;
    final borderPaint = Paint()
      ..color = spec.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawPath(tailPath, fillPaint);
    canvas.drawPath(tailPath, borderPaint);
    canvas.drawCircle(center, radius, fillPaint);
    canvas.drawCircle(center, radius, borderPaint);

    canvas.drawCircle(
      Offset(center.dx - radius * 0.25, center.dy - radius * 0.28),
      radius * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );

    final glyphTextPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(glyph.codePoint),
        style: TextStyle(
          fontSize: radius * 1.18,
          fontFamily: glyph.fontFamily,
          package: glyph.fontPackage,
          color: spec.glyphColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    glyphTextPainter.paint(
      canvas,
      Offset(
        center.dx - glyphTextPainter.width / 2,
        center.dy - glyphTextPainter.height / 2 - radius * 0.02,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _ExploreMarkerPainter oldDelegate) {
    return oldDelegate.spec != spec || oldDelegate.glyph != glyph;
  }
}
