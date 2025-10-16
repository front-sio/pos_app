import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double elevation;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AnimatedCard({
    Key? key,
    required this.child,
    this.onTap,
    this.elevation = 2,
    this.color,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.color ?? Theme.of(context).cardColor,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.kCardShadow,
              blurRadius: _isHovered ? 8 : 4,
              offset: Offset(0, _isHovered ? 4 : 2),
              spreadRadius: _isHovered ? 2 : 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(16),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}