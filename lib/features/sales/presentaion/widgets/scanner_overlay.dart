import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScannerOverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;
      
    final hole = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 250,
        height: 250
      ),
      const Radius.circular(12),
    );

    final outer = Path()..addRect(Offset.zero & size);
    final inner = Path()..addRRect(hole);
    final mask = Path.combine(PathOperation.difference, outer, inner);

    canvas.drawPath(mask, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}