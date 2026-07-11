import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/ring_progress.dart';
import 'login_screen.dart';

class _OnboardingPage {
  final String title;
  final String body;
  final Widget illustration;

  _OnboardingPage(
      {required this.title, required this.body, required this.illustration});
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  late final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      title: 'See every shilling',
      body:
          'Log income and expenses in seconds and always know exactly where you stand.',
      illustration: _StackedNotesIllustration(),
    ),
    _OnboardingPage(
      title: 'Budgets that hold the line',
      body:
          'Set a monthly budget per category and watch the ring fill as you spend.',
      illustration: const RingProgress(
        progress: 0.62,
        size: 140,
        strokeWidth: 14,
        color: AppColors.primary,
        center: Icon(Icons.account_balance_wallet_rounded,
            color: AppColors.primary, size: 36),
      ),
    ),
    _OnboardingPage(
      title: 'Goals worth celebrating',
      body: 'Track savings goals and get a small win the moment you reach one.',
      illustration: const RingProgress(
        progress: 1.0,
        size: 140,
        strokeWidth: 14,
        color: AppColors.gold,
        trackColor: AppColors.goldPale,
        center:
            Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 36),
      ),
    ),
  ];

  void _finish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            height: 160,
                            child: Center(child: page.illustration)),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut);
                  }
                },
                child: Text(isLast ? 'Get started' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple custom illustration: a small stack of income/expense "notes",
/// built from shapes rather than a generic stock icon.
class _StackedNotesIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 20,
            child: Transform.rotate(
              angle: -0.12,
              child: _note(AppColors.surfaceSunken, AppColors.textMuted),
            ),
          ),
          Positioned(
            top: 6,
            child: Transform.rotate(
              angle: 0.08,
              child: _note(AppColors.expensePale, AppColors.expense),
            ),
          ),
          Positioned(
            top: -6,
            child:
                _note(AppColors.primaryPale, AppColors.primary, elevated: true),
          ),
        ],
      ),
    );
  }

  Widget _note(Color bg, Color accent, {bool elevated = false}) {
    return Container(
      width: 120,
      height: 70,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: elevated
            ? [
                BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8))
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
                width: 32,
                height: 6,
                decoration: BoxDecoration(
                    color: accent, borderRadius: BorderRadius.circular(3))),
            Container(
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(3))),
          ],
        ),
      ),
    );
  }
}
