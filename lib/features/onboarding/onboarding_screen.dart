import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  static const String seenKey = 'onboarding_seen_v1';

  final VoidCallback onCompleted;

  const OnboardingScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _isSaving = false;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      title: 'Compress with one tap',
      subtitle:
          'Shrink image size while keeping quality. Pick quality once and process fast.',
      icon: Icons.compress_rounded,
      accentColor: Color(0xFF1DB88A),
      secondaryColor: Color(0xFF0F7B5F),
    ),
    _OnboardingPageData(
      title: 'Resize, convert, and batch',
      subtitle:
          'Change dimensions, switch formats, and apply edits to many photos at once.',
      icon: Icons.auto_awesome_mosaic_rounded,
      accentColor: Color(0xFF3B9EFF),
      secondaryColor: Color(0xFF1A6FD1),
    ),
    _OnboardingPageData(
      title: 'Preview and share instantly',
      subtitle:
          'See before and after results, then save or share your optimized images in seconds.',
      icon: Icons.share_rounded,
      accentColor: Color(0xFFA855F7),
      secondaryColor: Color(0xFF7C3ACD),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLast = _currentIndex == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: isLast ? 0 : 1,
                  duration: const Duration(milliseconds: 220),
                  child: IgnorePointer(
                    ignoring: isLast || _isSaving,
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onSurfaceVariant,
                      ),
                      child: const Text('Skip'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (value) {
                    setState(() {
                      _currentIndex = value;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _OnboardingPage(page: page);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? cs.primary
                          : cs.onSurfaceVariant.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          if (isLast) {
                            _finishOnboarding();
                            return;
                          }

                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                          );
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      isLast ? 'Get started' : 'Next',
                      style: tt.labelLarge?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finishOnboarding() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.seenKey, true);

    if (!mounted) return;

    widget.onCompleted();
  }
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color secondaryColor;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.secondaryColor,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageData page;

  const _OnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _IllustrationCard(page: page),
                const SizedBox(height: 28),
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  page.subtitle,
                  textAlign: TextAlign.center,
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IllustrationCard extends StatelessWidget {
  final _OnboardingPageData page;

  const _IllustrationCard({required this.page});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: 1.05,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEFF2F6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : const Color(0xFFDEE4EC),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Outer ring (wrapped in a gentle floating animation)
              _FloatingIllustration(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: page.accentColor.withOpacity(isDark ? 0.08 : 0.06),
                  ),
                  child: Center(
                    // Inner filled circle with icon
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            page.accentColor,
                            page.secondaryColor,
                          ],
                        ),
                      ),
                      child: Icon(
                        page.icon,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Three small dots as a subtle decorative element
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(page.accentColor.withOpacity(0.5), 6),
                  const SizedBox(width: 6),
                  _dot(page.accentColor.withOpacity(0.3), 5),
                  const SizedBox(width: 6),
                  _dot(page.accentColor.withOpacity(0.15), 4),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _FloatingIllustration extends StatefulWidget {
  final Widget child;
  const _FloatingIllustration({required this.child});

  @override
  State<_FloatingIllustration> createState() => _FloatingIllustrationState();
}

class _FloatingIllustrationState extends State<_FloatingIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
