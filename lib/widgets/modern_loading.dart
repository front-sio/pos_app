import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

enum ModernLoadingType {
  shimmer,
  pulse,
  wave,
  skeleton,
  dots,
  circular,
}

class ModernLoading extends StatefulWidget {
  final ModernLoadingType type;
  final double? width;
  final double? height;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration? duration;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final String? text;

  const ModernLoading({
    Key? key,
    this.type = ModernLoadingType.shimmer,
    this.width,
    this.height,
    this.baseColor,
    this.highlightColor,
    this.duration,
    this.margin,
    this.borderRadius,
    this.text,
  }) : super(key: key);

  @override
  State<ModernLoading> createState() => _ModernLoadingState();
}

class _ModernLoadingState extends State<ModernLoading>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    switch (widget.type) {
      case ModernLoadingType.shimmer:
      case ModernLoadingType.wave:
        _animation = Tween<double>(
          begin: -2.0,
          end: 2.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
        break;
      case ModernLoadingType.pulse:
        _animation = Tween<double>(
          begin: 0.3,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
        break;
      case ModernLoadingType.dots:
      case ModernLoadingType.circular:
        _animation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.linear,
        ));
        break;
      case ModernLoadingType.skeleton:
        _animation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ));
        break;
    }
    
    _controller.repeat(
      reverse: widget.type == ModernLoadingType.pulse ||
              widget.type == ModernLoadingType.skeleton,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case ModernLoadingType.shimmer:
        return _buildShimmer();
      case ModernLoadingType.pulse:
        return _buildPulse();
      case ModernLoadingType.wave:
        return _buildWave();
      case ModernLoadingType.skeleton:
        return _buildSkeleton();
      case ModernLoadingType.dots:
        return _buildDots();
      case ModernLoadingType.circular:
        return _buildCircular();
    }
  }

  Widget _buildShimmer() {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 20,
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: [
                    (_animation.value - 1).clamp(0.0, 1.0),
                    _animation.value.clamp(0.0, 1.0),
                    (_animation.value + 1).clamp(0.0, 1.0),
                  ],
                  colors: [
                    widget.baseColor ?? AppColors.kShimmerBase,
                    widget.highlightColor ?? AppColors.kShimmerHighlight,
                    widget.baseColor ?? AppColors.kShimmerBase,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPulse() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: (widget.baseColor ?? AppColors.kShimmerBase)
                .withOpacity(_animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
          ),
        );
      },
    );
  }

  Widget _buildWave() {
    return Container(
      width: widget.width ?? 200,
      height: widget.height ?? 4,
      margin: widget.margin,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: WavePainter(
              animation: _animation,
              color: widget.baseColor ?? AppColors.kPrimary,
            ),
            size: Size(widget.width ?? 200, widget.height ?? 4),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title line
        _buildShimmerLine(width: widget.width ?? 150, height: 16),
        const SizedBox(height: 8),
        // Subtitle line
        _buildShimmerLine(width: (widget.width ?? 150) * 0.7, height: 12),
        const SizedBox(height: 8),
        // Content lines
        _buildShimmerLine(width: widget.width ?? 150, height: 12),
        const SizedBox(height: 4),
        _buildShimmerLine(width: (widget.width ?? 150) * 0.9, height: 12),
        const SizedBox(height: 4),
        _buildShimmerLine(width: (widget.width ?? 150) * 0.6, height: 12),
      ],
    );
  }

  Widget _buildShimmerLine({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              colors: [
                widget.baseColor ?? AppColors.kShimmerBase,
                widget.highlightColor ?? AppColors.kShimmerHighlight,
                widget.baseColor ?? AppColors.kShimmerBase,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final delay = index * 0.2;
            final adjustedAnimation = (_animation.value + delay) % 1.0;
            final opacity = (0.3 + 0.7 * (1.0 - (adjustedAnimation - 0.5).abs() * 2))
                .clamp(0.0, 1.0);
            
            return Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: (widget.baseColor ?? AppColors.kPrimary)
                    .withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildCircular() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _animation.value * 2 * 3.14159,
              child: SizedBox(
                width: widget.width ?? 32,
                height: widget.height ?? 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.baseColor ?? AppColors.kPrimary,
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.text != null) ...[
          const SizedBox(height: AppSizes.smallPadding),
          Text(
            widget.text!,
            style: TextStyle(
              color: AppColors.kTextSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  WavePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height / 2;
    final waveLength = size.width / 2;
    final offset = animation.value * waveLength;

    path.moveTo(0, waveHeight);
    
    for (double x = 0; x <= size.width; x += 1) {
      final y = waveHeight + 
          waveHeight * 0.5 * Math.sin((x + offset) / waveLength * 2 * Math.pi);
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) {
    return oldDelegate.animation.value != animation.value;
  }
}

// Helper class for math operations
class Math {
  static double sin(double x) => math.sin(x);
  static double pi = math.pi;
}