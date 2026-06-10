import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? const [Color(0xFF061A15), Color(0xFF12382D)]
                  : const [Color(0xFFE5F4EC), Color(0xFFF8FAF8)],
            ),
          ),
        ),
        IgnorePointer(child: CustomPaint(painter: _CricketBackdrop(dark))),
        child,
      ],
    );
  }
}

class _CricketBackdrop extends CustomPainter {
  const _CricketBackdrop(this.dark);

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final accent = dark ? Colors.white : const Color(0xFF087F5B);
    final line = Paint()
      ..color = accent.withAlpha(18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final fill = Paint()
      ..color = accent.withAlpha(10)
      ..style = PaintingStyle.fill;

    final fieldCenter = Offset(size.width * .82, size.height * .24);
    canvas.drawCircle(fieldCenter, size.width * .34, line);
    canvas.drawCircle(fieldCenter, size.width * .25, line);

    canvas.save();
    canvas.rotate(-.16);
    final pitch = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * .2, size.height * .72),
        width: size.width * .24,
        height: size.height * .38,
      ),
      const Radius.circular(18),
    );
    canvas.drawRRect(pitch, fill);
    canvas.drawRRect(pitch, line);
    for (final offset in [-8.0, 0.0, 8.0]) {
      canvas.drawLine(
        Offset(pitch.center.dx + offset, pitch.top + 22),
        Offset(pitch.center.dx + offset, pitch.top + 70),
        line,
      );
      canvas.drawLine(
        Offset(pitch.center.dx + offset, pitch.bottom - 70),
        Offset(pitch.center.dx + offset, pitch.bottom - 22),
        line,
      );
    }
    canvas.restore();

    final ballCenter = Offset(size.width * .72, size.height * .82);
    canvas.drawCircle(ballCenter, 38, fill);
    canvas.drawCircle(ballCenter, 38, line);
    canvas.drawArc(
      Rect.fromCircle(center: ballCenter, radius: 30),
      -.8,
      1.6,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(_CricketBackdrop oldDelegate) => oldDelegate.dark != dark;
}
