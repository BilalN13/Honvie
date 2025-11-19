import 'package:flutter/material.dart';

class HonvieLikeButton extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onToggleLike;

  const HonvieLikeButton({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.onToggleLike,
  });

  @override
  State<HonvieLikeButton> createState() => _HonvieLikeButtonState();
}

class _HonvieLikeButtonState extends State<HonvieLikeButton> {
  bool _isAnimating = false;
  double _scale = 1.0;

  void _animateAndToggle() {
    setState(() {
      _isAnimating = true;
      _scale = 1.15;
    });

    Future.delayed(const Duration(milliseconds: 130), () {
      if (!mounted) return;
      setState(() {
        _scale = 1.0;
      });
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() => _isAnimating = false);
    });

    widget.onToggleLike();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLiked = widget.isLiked;

    return GestureDetector(
      onTap: _animateAndToggle,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: _isAnimating ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.pinkAccent.withValues(alpha: 0.35),
                          Colors.pinkAccent.withValues(alpha: 0.10),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.pinkAccent : Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(width: 4),
            Text(
              widget.likeCount.toString(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isLiked ? Colors.pinkAccent : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
