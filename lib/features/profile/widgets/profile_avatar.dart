import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.fallbackLabel,
    this.imageUrl,
    this.size = 40,
    this.backgroundColor = AppColors.warmCream,
    this.foregroundColor = AppColors.ink,
    this.borderColor = AppColors.border,
  });

  final String fallbackLabel;
  final String? imageUrl;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  bool get _hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor.withValues(alpha: 0.95)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _hasImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _FallbackAvatarLabel(
                label: fallbackLabel,
                color: foregroundColor,
                size: size,
              ),
            )
          : _FallbackAvatarLabel(
              label: fallbackLabel,
              color: foregroundColor,
              size: size,
            ),
    );
  }
}

class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({
    super.key,
    required this.fallbackLabel,
    required this.onTap,
    this.imageUrl,
    this.tooltip = 'Profil',
    this.size = 38,
  });

  final String fallbackLabel;
  final String? imageUrl;
  final VoidCallback onTap;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: ProfileAvatar(
            fallbackLabel: fallbackLabel,
            imageUrl: imageUrl,
            size: size,
          ),
        ),
      ),
    );
  }
}

class _FallbackAvatarLabel extends StatelessWidget {
  const _FallbackAvatarLabel({
    required this.label,
    required this.color,
    required this.size,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}
