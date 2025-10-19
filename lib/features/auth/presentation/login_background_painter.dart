import 'package:flutter/material.dart';
import 'package:sales_app/constants/colors.dart';

class LoginBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Shape 1
    var paint1 = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.kPrimary, AppColors.kPrimary.withOpacity(0.5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    var path1 = Path()
      ..moveTo(size.width * 0.8, 0)
      ..cubicTo(size.width * 0.95, size.height * 0.2, size.width * 0.7, size.height * 0.4, size.width * 0.9, size.height * 0.5)
      ..cubicTo(size.width * 1.1, size.height * 0.6, size.width * 0.6, size.height * 0.7, size.width * 0.8, size.height * 0.9)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path1, paint1);

    // Shape 2
    var paint2 = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.kPrimary.withOpacity(0.7), AppColors.kPrimary.withOpacity(0.3)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    var path2 = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..cubicTo(size.width * 0.05, size.height * 0.8, size.width * 0.3, size.height * 0.6, size.width * 0.1, size.height * 0.5)
      ..cubicTo(size.width * -0.1, size.height * 0.4, size.width * 0.4, size.height * 0.3, size.width * 0.2, size.height * 0.1)
      ..lineTo(0, 0)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
