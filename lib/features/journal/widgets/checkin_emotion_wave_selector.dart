import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';

class CheckinEmotionWaveOption {
  const CheckinEmotionWaveOption({
    required this.label,
    required this.assetPath,
  });

  final String label;
  final String assetPath;
}

class CheckinEmotionWaveSelector extends StatelessWidget {
  const CheckinEmotionWaveSelector({
    super.key,
    required this.options,
    required this.selectedLabel,
    required this.onSelected,
  });

  final List<CheckinEmotionWaveOption> options;
  final String? selectedLabel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedOption = options.where(
      (option) => option.label == selectedLabel,
    );
    final selectedText = selectedOption.isEmpty
        ? 'Choisis une émotion'
        : _capitalize(selectedOption.first.label);

    return Column(
      children: <Widget>[
        const SizedBox(height: 24),
        SizedBox(
          height: 176,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                bottom: 32,
                child: CustomPaint(painter: _WavePainter()),
              ),
              ...List<Widget>.generate(options.length, (int index) {
                final option = options[index];
                final isSelected = selectedLabel == option.label;
                final topOffsets = <double>[72, 56, 34, 56, 72];
                final top = topOffsets[index.clamp(0, topOffsets.length - 1)];

                return Align(
                  alignment: Alignment(
                    -1 + (2 / (options.length - 1)) * index,
                    -1,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: top),
                    child: _EmotionBubble(
                      option: option,
                      isSelected: isSelected,
                      onTap: () => onSelected(option.label),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            selectedText,
            key: ValueKey<String>(selectedText),
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }
}

class _EmotionBubble extends StatelessWidget {
  const _EmotionBubble({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final CheckinEmotionWaveOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 74.0 : 54.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: size,
        width: size,
        padding: EdgeInsets.all(isSelected ? 6 : 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected ? AppGradients.sunsetWarm : null,
          color: isSelected ? null : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.transparent : AppColors.border,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: isSelected ? 24 : 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? AppColors.white.withValues(alpha: 0.18) : null,
          ),
          alignment: Alignment.center,
          child: Image.asset(
            option.assetPath,
            width: isSelected ? 58 : 42,
            height: isSelected ? 58 : 42,
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final warmPaint = Paint()
      ..color = AppColors.warning
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final pinkPaint = Paint()
      ..color = AppColors.lavender
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final warmPath = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.52,
        size.width * 0.24,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.72,
        size.width * 0.5,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.44,
        size.width * 0.76,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.72,
        size.width,
        size.height * 0.6,
      );

    final pinkPath = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.6,
        size.width * 0.24,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.36,
        size.height * 0.8,
        size.width * 0.5,
        size.height * 0.66,
      )
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.52,
        size.width * 0.76,
        size.height * 0.66,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.8,
        size.width,
        size.height * 0.68,
      );

    canvas.drawPath(warmPath, warmPaint);
    canvas.drawPath(pinkPath, pinkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
