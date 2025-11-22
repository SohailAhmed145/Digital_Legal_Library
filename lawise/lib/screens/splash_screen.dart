import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/login_screen.dart';
import 'main/main_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeOpacity;
  late Animation<double> _scaleAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      _fadeController.forward();
      _scaleController.forward();
    }

    // Wait for animations to complete, then navigate
    await Future.delayed(const Duration(milliseconds: 3000));
    if (mounted && !_hasNavigated) {
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    if (_hasNavigated) return;
    _hasNavigated = true;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
                     pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light grey/off-white background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Central Logo with Balance Scale
            AnimatedBuilder(
              animation: _scaleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: BalanceScalePainter(),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Tagline at the bottom
            AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeOpacity.value,
                  child: Text(
                    'Empowering Legal Minds',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the balance scale logo matching the screenshot
class BalanceScalePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final scaleWidth = size.width * 0.6;
    final scaleHeight = size.height * 0.4;

    // Draw the horizontal bar at the top
    canvas.drawLine(
      Offset(center.dx - scaleWidth / 2, center.dy - scaleHeight / 2),
      Offset(center.dx + scaleWidth / 2, center.dy - scaleHeight / 2),
      paint,
    );

    // Draw the left scale pan
    canvas.drawLine(
      Offset(center.dx - scaleWidth / 2, center.dy - scaleHeight / 2),
      Offset(center.dx - scaleWidth / 2, center.dy + scaleHeight / 2),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - scaleWidth / 2, center.dy + scaleHeight / 2),
      Offset(center.dx - scaleWidth / 2 + 15, center.dy + scaleHeight / 2),
      paint,
    );

    // Draw the right scale pan
    canvas.drawLine(
      Offset(center.dx + scaleWidth / 2, center.dy - scaleHeight / 2),
      Offset(center.dx + scaleWidth / 2, center.dy + scaleHeight / 2),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + scaleWidth / 2, center.dy + scaleHeight / 2),
      Offset(center.dx + scaleWidth / 2 - 15, center.dy + scaleHeight / 2),
      paint,
    );

    // Draw the central structure with abstract letterforms
    final letterPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Central vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - scaleHeight / 2),
      Offset(center.dx, center.dy + scaleHeight / 2),
      letterPaint,
    );

    // Horizontal lines intersecting the central vertical
    canvas.drawLine(
      Offset(center.dx - 8, center.dy - 5),
      Offset(center.dx + 8, center.dy - 5),
      letterPaint,
    );
    canvas.drawLine(
      Offset(center.dx - 6, center.dy),
      Offset(center.dx + 6, center.dy),
      letterPaint,
    );
    canvas.drawLine(
      Offset(center.dx - 4, center.dy + 5),
      Offset(center.dx + 4, center.dy + 5),
      letterPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

