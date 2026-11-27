import 'package:flutter/material.dart';

/// O "X" desenhado na mão, sem depender de fonte com o caractere 𝕏.
class XLogo extends StatelessWidget {
  const XLogo({super.key, this.size = 22, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ??
        (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black);
    return CustomPaint(
      size: Size.square(size),
      painter: _XLogoPainter(resolved),
    );
  }
}

class _XLogoPainter extends CustomPainter {
  const _XLogoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.145
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    final inset = size.width * 0.1;
    canvas.drawLine(
      Offset(inset, inset),
      Offset(size.width - inset, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _XLogoPainter oldDelegate) => oldDelegate.color != color;
}
