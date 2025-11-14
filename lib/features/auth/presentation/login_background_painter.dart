import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';

class LoginBackgroundPainter extends CustomPainter {
  final Animation<double>? animation;

  LoginBackgroundPainter({this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final animValue = animation?.value ?? 0.0;

    // Full background gradient
    var bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.kPrimary.withOpacity(0.15),
          AppColors.kBackground,
          AppColors.kPrimary.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw sales-themed patterns
    _drawCashRegisterPattern(canvas, size, animValue);
    _drawMoneySymbols(canvas, size, animValue);
    _drawReceiptPattern(canvas, size, animValue);
    _drawChartPattern(canvas, size, animValue);
    _drawShoppingCartPattern(canvas, size, animValue);
  }

  void _drawCashRegisterPattern(Canvas canvas, Size size, double animValue) {
    final paint = Paint()
      ..color = AppColors.kPrimary.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Cash register icon (simplified)
    canvas.save();
    canvas.translate(size.width * 0.1, size.height * 0.25 + sin(animValue * 2 * pi) * 15);
    
    // Register body
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, 40, 30),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, paint);
    
    // Display
    canvas.drawLine(const Offset(8, 10), const Offset(32, 10), paint);
    canvas.drawLine(const Offset(8, 15), const Offset(25, 15), paint);
    
    canvas.restore();
  }

  void _drawMoneySymbols(Canvas canvas, Size size, double animValue) {
    final paint = Paint()
      ..color = AppColors.kPrimary.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    // Dollar/currency symbols
    final positions = [
      {'x': 0.85, 'y': 0.2, 'offset': 0.0},
      {'x': 0.15, 'y': 0.7, 'offset': pi},
      {'x': 0.9, 'y': 0.65, 'offset': pi / 2},
    ];

    for (var pos in positions) {
      canvas.save();
      canvas.translate(
        size.width * (pos['x'] as double),
        size.height * (pos['y'] as double) + cos(animValue * 2 * pi + (pos['offset'] as double)) * 12,
      );

      // Draw $ symbol
      canvas.drawCircle(Offset.zero, 15, paint);
      final textPainter = TextPainter(
        text: TextSpan(
          text: '\$',
          style: TextStyle(
            color: AppColors.kPrimary.withOpacity(0.3),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));

      canvas.restore();
    }
  }

  void _drawReceiptPattern(Canvas canvas, Size size, double animValue) {
    final paint = Paint()
      ..color = AppColors.kPrimary.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.translate(size.width * 0.85, size.height * 0.8 + sin(animValue * 2 * pi + pi) * 10);

    // Receipt outline
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(35, 0)
      ..lineTo(35, 50)
      ..lineTo(0, 50)
      ..close();
    canvas.drawPath(path, paint);

    // Receipt lines
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(5, 10 + i * 8.0),
        Offset(30, 10 + i * 8.0),
        paint,
      );
    }

    canvas.restore();
  }

  void _drawChartPattern(Canvas canvas, Size size, double animValue) {
    final paint = Paint()
      ..color = AppColors.kPrimary.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width * 0.12, size.height * 0.82);

    // Bar chart
    final barHeights = [15.0, 25.0, 20.0, 30.0];
    for (var i = 0; i < barHeights.length; i++) {
      final height = barHeights[i] + sin(animValue * 2 * pi + i * 0.5) * 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * 12.0, -height, 8, height),
          const Radius.circular(2),
        ),
        paint,
      );
    }

    canvas.restore();
  }

  void _drawShoppingCartPattern(Canvas canvas, Size size, double animValue) {
    final paint = Paint()
      ..color = AppColors.kPrimary.withOpacity(0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.save();
    canvas.translate(size.width * 0.88, size.height * 0.35 + cos(animValue * 2 * pi + pi / 3) * 12);

    // Cart body
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(5, 0)
      ..lineTo(8, 15)
      ..lineTo(25, 15)
      ..lineTo(28, 5)
      ..lineTo(10, 5);
    canvas.drawPath(path, paint);

    // Wheels
    canvas.drawCircle(const Offset(12, 20), 3, paint);
    canvas.drawCircle(const Offset(23, 20), 3, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(LoginBackgroundPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}
