// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';

// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});

//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }

// class _AuthScreenState extends State<AuthScreen> {
//   final AuthService _authService = AuthService();
//   bool _isLoading = false;

//   Future<void> _signInWithGoogle() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       await _authService.signInWithGoogle();
//       // Navigation will be handled by auth state listener in main.dart
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Sign in failed: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.account_circle,
//                   size: 100,
//                   color: Theme.of(context).primaryColor,
//                 ),
//                 const SizedBox(height: 32),
//                 Text(
//                   'Welcome',
//                   style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Sign in to continue',
//                   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                         color: Colors.grey[600],
//                       ),
//                 ),
//                 const SizedBox(height: 48),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton.icon(
//                     onPressed: _isLoading ? null : _signInWithGoogle,
//                     icon: _isLoading
//                         ? const SizedBox(
//                             width: 20,
//                             height: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                             ),
//                           )
//                         : Image.asset(
//                             'assets/images/google_logo.png',
//                             height: 24,
//                             errorBuilder: (context, error, stackTrace) {
//                               return const Icon(Icons.login);
//                             },
//                           ),
//                     label: Text(_isLoading ? 'Signing in...' : 'Sign in with Google'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.black87,
//                       elevation: 1,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         side: BorderSide(color: Colors.grey[300]!),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign in failed: $e"), backgroundColor: Colors.red),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final ringsSize = width * 0.75;
    final centerLogoSize = ringsSize * 0.38;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: ringsSize,
                height: ringsSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildRing(ringsSize, Colors.pink.shade100.withOpacity(0.4)),
                    _buildGradientRing(ringsSize * 0.82),
                    _buildRing(ringsSize * 0.66, Colors.purple.shade50.withOpacity(0.25)),

                    // Orbit floating icons (Material icons replacing PNG images)
                    _buildOrbitIcon(Icons.cake, ringsSize * 0.41, -pi / 2),
                    _buildOrbitIcon(Icons.calendar_today_rounded, ringsSize * 0.41, pi),
                    _buildOrbitIcon(Icons.mail_rounded, ringsSize * 0.41, pi / 2),
                    _buildOrbitIcon(Icons.favorite_rounded, ringsSize * 0.41, 0),

                    // CENTERED LOGO
                    Container(
                      width: centerLogoSize,
                      height: centerLogoSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            offset: Offset(0, 6),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: ClipOval(
                        child: Image.asset(
                          "assets/images/logo.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // SIGN-IN BUTTON (bottom)
            Positioned(
              left: 24,
              right: 24,
              bottom: 30,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset("assets/images/google.png", height: 36),
                            const SizedBox(width: 20),
                            const Text(
                              "Sign up with Google",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // simple faint ring
  Widget _buildRing(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }

  // colorful gradient ring to mimic screenshot
  Widget _buildGradientRing(double size) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GradientRingPainter(),
    );
  }

  // floating orbit icon
  Widget _buildOrbitIcon(IconData icon, double radius, double angle) {
    return Transform.translate(
      offset: Offset(radius * cos(angle), radius * sin(angle)),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        child: Icon(icon, size: 26, color: Colors.purple),
      ),
    );
  }
}

/// Draws a smooth rainbow gradient arc ring
class _GradientRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 6.0;
    final rect = Offset.zero & size;

    final paint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.indigo,
          Colors.purple,
          Colors.red,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2 - strokeWidth, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
