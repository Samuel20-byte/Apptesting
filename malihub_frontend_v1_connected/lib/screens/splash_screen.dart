import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/malihub_logo.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// Brief branded launch screen. If a JWT is already stored (and still
/// valid), skips straight to the Dashboard. Otherwise falls through to
/// onboarding for a first-time feel.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  final _authService = AuthService();
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn));
    _controller.forward();

    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    // Keep the splash on screen for a minimum, pleasant duration while we
    // check for a stored session in parallel.
    final minDelay = Future.delayed(const Duration(milliseconds: 900));

    Widget next = const OnboardingScreen();

    if (await _authService.hasStoredSession()) {
      try {
        final user = await _userService.getMe();
        next = MainShell(user: user);
      } catch (_) {
        // Token missing/expired/invalid — clear it and fall back to login.
        await _authService.logout();
        next = const LoginScreen();
      }
    }

    await minDelay;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => next),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDeep,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MalihubLogo(size: 88),
                const SizedBox(height: 20),
                const Text(
                  'Malihub',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your wealth, in one place',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
