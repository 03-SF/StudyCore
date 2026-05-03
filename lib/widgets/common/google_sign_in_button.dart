import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFDADCE0), width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF4285F4),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3C4043),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Blue arc (right side)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -0.5236, // -30 deg
      3.6652,  // 210 deg
      true,
      paint,
    );

    // White mask center
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.62, paint);

    // Green arc (bottom-left)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      1.5708,  // 90 deg
      1.5708,  // 90 deg
      true,
      paint,
    );

    // Yellow arc (bottom-right)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      0.5236,  // 30 deg
      1.0472,  // 60 deg
      true,
      paint,
    );

    // Red arc (top-left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      3.1416,  // 180 deg
      1.5708,  // 90 deg
      true,
      paint,
    );

    // White inner circle
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.62, paint);

    // Blue horizontal bar (the crossbar of the G)
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.19, r, r * 0.38),
      paint,
    );

    // White inner circle (clip bar)
    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r * 0.42, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
