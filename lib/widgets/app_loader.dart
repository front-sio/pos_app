import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLoader extends StatelessWidget {
  final String? message;
  final double? size;
  final String assetPath;
  final Color? textColor;

  const AppLoader({
    super.key,
    this.message,
    this.size,
    this.assetPath = 'assets/lottie/animations/loader.json',
    this.textColor,
  });

  /// Fullscreen convenience usage:
  /// AppLoader.fullscreen(message: 'Loading...')
  const AppLoader.fullscreen({
    super.key,
    this.message,
    this.assetPath = 'assets/lottie/animations/loader.json',
    this.textColor,
  }) : size = null;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isSmall = media.size.width < 600;
    final resolvedSize = size ?? (isSmall ? 140.0 : 180.0);
    final resolvedText =
        textColor ?? Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;

    final animation = ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: resolvedSize, height: resolvedSize),
      child: LottieBuilder.asset(
        assetPath,
        repeat: true,
        animate: true,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );

    return Semantics(
      label: message ?? 'Loading',
      liveRegion: true,
      container: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            animation,
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: resolvedText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}