import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLoader extends StatelessWidget {
  final String? message;
  final double size;
  final EdgeInsets padding;

  const AppLoader({
    super.key,
    this.message,
    this.size = 180,
    this.padding = const EdgeInsets.all(16),
  });

  const AppLoader.fullscreen({super.key, this.message})
      : size = 180,
        padding = const EdgeInsets.all(16);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget visual;
    // Lottie on web can crash inside renderer depending on JSON/codec. Use spinner on web.
    if (kIsWeb) {
      visual = _Spinner(size: size);
    } else {
      // Use Lottie with a hard fallback at runtime if decoding fails.
      visual = _SafeLottie(
        width: size,
        height: size,
        asset: 'assets/lottie/loading.json',
      );
    }

    return Semantics(
      label: message ?? 'Loading',
      container: true,
      child: Center(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: visual,
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  final double size;
  const _Spinner({required this.size});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SizedBox(
          width: size * 0.35,
          height: size * 0.35,
          child: CircularProgressIndicator(color: color, strokeWidth: 4),
        ),
      ),
    );
  }
}

class _SafeLottie extends StatelessWidget {
  final String asset;
  final double width;
  final double height;

  const _SafeLottie({
    required this.asset,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap the builder with try/catch protection; if anything goes wrong, show spinner.
    try {
      return LottieBuilder.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.contain,
        frameRate: FrameRate.max,
        repeat: true,
        animate: true,
        errorBuilder: (context, error, stack) {
          // Any decode/paint failure falls back to a spinner.
          return _Spinner(size: width);
        },
      );
    } catch (_) {
      return _Spinner(size: width);
    }
  }
}