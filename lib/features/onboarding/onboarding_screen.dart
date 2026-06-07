import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const int _pageCount = 3;

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
    final isLast = _currentIndex == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(
            children: [
              // Skip — hidden on last page
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: isLast ? 0.0 : 1.0,
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

              // Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (v) => setState(() => _currentIndex = v),
                  children: const [
                    _PageBeforeAfter(),
                    _PageResize(),
                    _PageFormatConvert(),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Dot indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pageCount, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == i
                          ? cs.primary
                          : cs.onSurfaceVariant.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 18),

              // CTA button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving
                      ? null
                      : () {
                          if (isLast) {
                            _finishOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      isLast ? 'Let\'s Go!' : 'Next',
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
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.seenKey, true);
    if (!mounted) return;
    widget.onCompleted();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 1 — Before / After: lead with the pain, show the payoff visually
// ─────────────────────────────────────────────────────────────────────────────

class _PageBeforeAfter extends StatelessWidget {
  const _PageBeforeAfter();

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
                const _BeforeAfterCard(),
                const SizedBox(height: 28),
                Text(
                  'Reduce Size, Keep Quality',
                  textAlign: TextAlign.center,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Compress photos by up to 90% with zero visible quality loss. '
                  'Upload and share your images instantly without limits.',
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

/// Draws a side-by-side before/after card using a real photo from Unsplash
/// plus animated size-badge overlays.
class _BeforeAfterCard extends StatefulWidget {
  const _BeforeAfterCard();

  @override
  State<_BeforeAfterCard> createState() => _BeforeAfterCardState();
}

class _BeforeAfterCardState extends State<_BeforeAfterCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _badgeScale;

  // Bundled asset — no network needed
  static const _imageUrl = 'assets/onboarding/compress_demo.jpg';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _badgeScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1.05,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEFF2F6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFDEE4EC),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              // Label row
              Row(
                children: [
                  _Label('BEFORE', color: cs.onSurfaceVariant),
                  const Spacer(),
                  _Label('AFTER', color: const Color(0xFF1DB88A)),
                ],
              ),
              const SizedBox(height: 8),
              // Photo row
              Expanded(
                child: Row(
                  children: [
                    // Before — original, slightly desaturated
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                0.6,
                                0.3,
                                0.1,
                                0,
                                0,
                                0.2,
                                0.7,
                                0.1,
                                0,
                                0,
                                0.1,
                                0.1,
                                0.8,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                              ]),
                              child: Image.asset(
                                _imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                            // Dim overlay to reinforce "before" feel
                            Container(
                              color: Colors.black.withValues(alpha: 0.15),
                            ),
                            // Size badge
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: ScaleTransition(
                                scale: _badgeScale,
                                child: _SizeBadge(
                                  label: '4.2 MB',
                                  bgColor: Colors.black.withValues(alpha: 0.65),
                                  textColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Arrow
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: const Color(0xFF1DB88A),
                        size: 20,
                      ),
                    ),

                    // After — vivid, sharp
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              _imageUrl,
                              fit: BoxFit.cover,
                            ),
                            // Green tint overlay to reinforce "after"
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    const Color(0xFF1DB88A)
                                        .withValues(alpha: 0.18),
                                  ],
                                ),
                              ),
                            ),
                            // Size badge
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: ScaleTransition(
                                scale: _badgeScale,
                                child: const _SizeBadge(
                                  label: '380 KB',
                                  bgColor: Color(0xFF1DB88A),
                                  textColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Reduction tag
              ScaleTransition(
                scale: _badgeScale,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB88A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: const Color(0xFF1DB88A).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_down_rounded,
                          size: 14, color: Color(0xFF1DB88A)),
                      SizedBox(width: 5),
                      Text(
                        '91% smaller — same visual quality',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1DB88A),
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final Color color;
  const _Label(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: color,
      ),
    );
  }
}

class _SizeBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  const _SizeBadge(
      {required this.label, required this.bgColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2 — Resize: exact dimensions, visual mock-up
// ─────────────────────────────────────────────────────────────────────────────

class _PageResize extends StatelessWidget {
  const _PageResize();

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
                const _ResizeCard(),
                const SizedBox(height: 28),
                Text(
                  'Pixel-Perfect Resizing',
                  textAlign: TextAlign.center,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Resize images using standard social media presets or input custom dimensions. '
                  'Lock aspect ratio to keep images looking perfect.',
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

class _ResizeCard extends StatefulWidget {
  const _ResizeCard();

  @override
  State<_ResizeCard> createState() => _ResizeCardState();
}

class _ResizeCardState extends State<_ResizeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideUp;
  late final Animation<double> _badgeScale;

  // Bundled asset — no network needed
  static const _imageUrl = 'assets/onboarding/resize_demo.jpg';

  // Preset chips to display
  static const _presets = ['Instagram', 'Twitter', 'Wallpaper', 'Thumbnail'];
  static const _accentBlue = Color(0xFF3B9EFF);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _badgeScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1.05,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEFF2F6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFDEE4EC),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeIn,
          child: AnimatedBuilder(
            animation: _slideUp,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: child,
            ),
            child: Column(
              children: [
                // Dimension input mock
                _DimensionInputMock(cs: cs, isDark: isDark),
                const SizedBox(height: 12),
                // Photo preview with dimension overlay
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _imageUrl,
                          fit: BoxFit.cover,
                        ),
                        // Corner resize handles
                        ..._cornerHandles(_accentBlue),
                        // Output size badge
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: ScaleTransition(
                            scale: _badgeScale,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _accentBlue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.aspect_ratio_rounded,
                                      size: 13, color: Colors.white),
                                  SizedBox(width: 5),
                                  Text(
                                    '1080 × 1080',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Preset chips
                ScaleTransition(
                  scale: _badgeScale,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _presets
                          .map((p) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _PresetChip(
                                    label: p,
                                    color: _accentBlue,
                                    selected: p == 'Instagram'),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _cornerHandles(Color color) {
    const size = 16.0;
    const thickness = 3.0;
    Widget handle(AlignmentGeometry alignment, BorderRadius radius) {
      return Positioned.fill(
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _CornerPainter(
                    color: color, radius: radius, thickness: thickness),
              ),
            ),
          ),
        ),
      );
    }

    return [
      handle(Alignment.topLeft,
          const BorderRadius.only(topLeft: Radius.circular(4))),
      handle(Alignment.topRight,
          const BorderRadius.only(topRight: Radius.circular(4))),
      handle(Alignment.bottomLeft,
          const BorderRadius.only(bottomLeft: Radius.circular(4))),
      handle(Alignment.bottomRight,
          const BorderRadius.only(bottomRight: Radius.circular(4))),
    ];
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final BorderRadius radius;
  final double thickness;
  const _CornerPainter(
      {required this.color, required this.radius, required this.thickness});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // Determine which corner by checking the radius
    final tl = radius.topLeft != Radius.zero;
    final tr = radius.topRight != Radius.zero;
    final bl = radius.bottomLeft != Radius.zero;
    final br = radius.bottomRight != Radius.zero;

    if (tl) {
      canvas.drawLine(Offset(0, h * 0.6), Offset(0, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(w * 0.6, 0), paint);
    } else if (tr) {
      canvas.drawLine(Offset(w * 0.4, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h * 0.6), paint);
    } else if (bl) {
      canvas.drawLine(Offset(0, h * 0.4), Offset(0, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w * 0.6, h), paint);
    } else if (br) {
      canvas.drawLine(Offset(w * 0.4, h), Offset(w, h), paint);
      canvas.drawLine(Offset(w, h), Offset(w, h * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

class _DimensionInputMock extends StatelessWidget {
  final ColorScheme cs;
  final bool isDark;
  const _DimensionInputMock({required this.cs, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const accentBlue = Color(0xFF3B9EFF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          _InputField(label: 'W', value: '1080', color: accentBlue),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.link_rounded,
                size: 16, color: accentBlue.withValues(alpha: 0.7)),
          ),
          _InputField(label: 'H', value: '1080', color: accentBlue),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'px',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InputField(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.7)),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  const _PresetChip(
      {required this.label, required this.color, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? color : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: selected ? color : color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 3 — Format Convert: format badges + photo demo
// ─────────────────────────────────────────────────────────────────────────────

class _PageFormatConvert extends StatelessWidget {
  const _PageFormatConvert();

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
                const _FormatConvertCard(),
                const SizedBox(height: 28),
                Text(
                  'Convert Formats Instantly',
                  textAlign: TextAlign.center,
                  style: tt.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Seamlessly convert HEIC, PNG, JPEG, WebP, and AVIF. '
                  'Ensure your files are compatible with every device and platform.',
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

class _FormatConvertCard extends StatefulWidget {
  const _FormatConvertCard();

  @override
  State<_FormatConvertCard> createState() => _FormatConvertCardState();
}

class _FormatConvertCardState extends State<_FormatConvertCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _badgeScale;

  // Bundled asset — no network needed
  static const _imageUrl = 'assets/onboarding/convert_demo.jpg';

  static const _accentPurple = Color(0xFFA855F7);

  // Format flow: input on left, output formats on right
  static const _outputFormats = [
    _FormatBadgeData(label: 'JPEG', color: Color(0xFF3B9EFF), selected: false),
    _FormatBadgeData(label: 'PNG', color: Color(0xFF1DB88A), selected: false),
    _FormatBadgeData(label: 'WebP', color: Color(0xFFA855F7), selected: true),
    _FormatBadgeData(label: 'AVIF', color: Color(0xFFFFB800), selected: false),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _badgeScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 1.0, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1.05,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEFF2F6),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFDEE4EC),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              // Input format tag
              ScaleTransition(
                scale: _badgeScale,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _FormatTag(
                    label: 'HEIC',
                    icon: Icons.phone_iphone_rounded,
                    color: cs.onSurfaceVariant,
                    bgColor: cs.surfaceContainerHighest,
                    prefix: 'Input:',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Main photo
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        _imageUrl,
                        fit: BoxFit.cover,
                      ),
                      // Purple tint
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              _accentPurple.withValues(alpha: 0.20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Output format picker
              ScaleTransition(
                scale: _badgeScale,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Convert to:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: _outputFormats
                          .map((f) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _FormatPickerChip(data: f),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatBadgeData {
  final String label;
  final Color color;
  final bool selected;
  const _FormatBadgeData(
      {required this.label, required this.color, required this.selected});
}

class _FormatPickerChip extends StatelessWidget {
  final _FormatBadgeData data;
  const _FormatPickerChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: data.selected ? data.color : data.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: data.selected ? data.color : data.color.withValues(alpha: 0.3),
          width: data.selected ? 1.5 : 1,
        ),
        boxShadow: data.selected
            ? [
                BoxShadow(
                  color: data.color.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Text(
        data.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: data.selected ? Colors.white : data.color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _FormatTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String prefix;
  const _FormatTag({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            '$prefix ',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.7)),
          ),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
