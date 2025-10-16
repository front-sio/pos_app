import 'package:flutter/material.dart';

class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.0),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: CustomPaint(
              painter: CornerPainter(),
              child: Container(
                width: 250,
                height: 250,
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Center barcode in frame to scan',
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const length = 30.0;
    const padding = 0.0;

    // Top left corner
    canvas.drawPath(
      Path()
        ..moveTo(padding, length + padding)
        ..lineTo(padding, padding)
        ..lineTo(length + padding, padding),
      paint,
    );

    // Top right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - length - padding, padding)
        ..lineTo(size.width - padding, padding)
        ..lineTo(size.width - padding, length + padding),
      paint,
    );

    // Bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(padding, size.height - length - padding)
        ..lineTo(padding, size.height - padding)
        ..lineTo(length + padding, size.height - padding),
      paint,
    );

    // Bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - length - padding, size.height - padding)
        ..lineTo(size.width - padding, size.height - padding)
        ..lineTo(size.width - padding, size.height - length - padding),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}