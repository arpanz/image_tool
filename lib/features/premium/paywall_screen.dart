import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/utils/ad_manager.dart';
import '../../core/theme/app_theme.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen>
    with SingleTickerProviderStateMixin {
  final InAppPurchase _iap = InAppPurchase.instance;
  bool _available = true;
  bool _isLoading = false;
  bool _isLifetimeSelected = true;

  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Timer? _restoreTimer;
  bool _purchaseHandled = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnimation = Tween<double>(begin: 0.15, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    _initStore();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _restoreTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initStore() async {
    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      if (mounted) setState(() => _available = false);
      return;
    }
    if (AdManager.instance.products.isNotEmpty) {
      if (mounted) setState(() => _products = AdManager.instance.products);
    }
    _subscription = _iap.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription?.cancel(),
      onError: (e) => debugPrint('Paywall: stream error: $e'),
    );
    if (_products.isEmpty) {
      final response = await _iap.queryProductDetails({
        AdManager.productId,
        AdManager.yearlyProductId,
      });
      if (mounted) {
        setState(() {
          _products = response.productDetails;
          AdManager.instance.products = _products;
        });
      }
    }
  }

  ProductDetails? _getProduct(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> list) async {
    for (final p in list) {
      if (p.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _isLoading = true);
      } else if (p.status == PurchaseStatus.error) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Purchase failed: ${p.error?.message}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ));
        }
      } else if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        final known = {
          AdManager.productId,
          AdManager.yearlyProductId,
          AdManager.legacyProductId
        };
        if (known.contains(p.productID)) {
          _restoreTimer?.cancel();
          if (!_purchaseHandled) {
            _purchaseHandled = true;
            await _grantPremium();
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }

  Future<void> _grantPremium() async {
    await AdManager.instance.enableProVersion();
    if (mounted) {
      setState(() => _isLoading = false);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(
        content: Text(
            'Image Resizer Pro unlocked \u2728 Enjoy ad-free, unlimited processing!'),
        backgroundColor: Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _buyProduct() async {
    if (_products.isEmpty) return;
    final id =
        _isLifetimeSelected ? AdManager.productId : AdManager.yearlyProductId;
    final product = _getProduct(id);
    if (product == null) return;
    _purchaseHandled = false;
    try {
      await _iap
          .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (mounted) setState(() => _isLoading = true);
    _restoreTimer?.cancel();
    _purchaseHandled = false;
    try {
      await _iap.restorePurchases();
      _restoreTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No previous purchases found for this account.'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      });
    } catch (e) {
      _restoreTimer?.cancel();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Builder(builder: (context) {
        const accent = Color(0xFF9D97FF); // Image Resizer accent
        const accentGold = Color(0xFFFFD700);
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: const Color(0xFF0B0B12),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0D1A), Color(0xFF0B0B12)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ── Close ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white38, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),

                  // ── Scrollable body ────────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            const SizedBox(height: 8),

                            // Hero animation
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: const _ImageResizerHero(size: 130),
                            ),
                            const SizedBox(height: 22),

                            // Headline
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Image Resizer Pro',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                  height: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 44),
                              child: Text(
                                'Compress and resize images without limits — no ads, no caps, just pure speed.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.white54,
                                    height: 1.55),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Feature rows
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              child: Column(
                                children: [
                                  _featureRow(
                                    Icons.compress_rounded,
                                    'Unlimited Compressions',
                                    'Compress as many images as you want, every day.',
                                    const Color(0xFF6C63FF),
                                  ),
                                  _featureRow(
                                    Icons.photo_size_select_large_rounded,
                                    'Unlimited Resizes',
                                    'Pixel-perfect resizing with all fit modes unlocked.',
                                    const Color(0xFF11998E),
                                  ),
                                  _featureRow(
                                    Icons.block_flipped,
                                    'Completely Ad-Free',
                                    'No banners, no interstitials. Just your images.',
                                    const Color(0xFFFF6B6B),
                                  ),
                                  _featureRow(
                                    Icons.auto_fix_high_rounded,
                                    'All Output Formats',
                                    'Export to JPG, PNG, WebP — all formats, no locks.',
                                    Colors.orangeAccent,
                                  ),
                                  _featureRow(
                                    Icons.rocket_launch_rounded,
                                    'All Future Features',
                                    'Batch processing and new tools ship to Pro first.',
                                    Colors.tealAccent,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom panel ───────────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13121E),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 28,
                            offset: const Offset(0, -8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag handle
                          Container(
                            width: 36,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),

                          // Pricing cards
                          _pricingCard(
                            title: 'Lifetime',
                            price: _getProduct(AdManager.productId)
                                    ?.price ??
                                '...',
                            subtitle: 'One-time payment. Own it forever.',
                            badge: 'BEST VALUE',
                            badgeColor: accentGold,
                            isSelected: _isLifetimeSelected,
                            theme: theme,
                            onTap: () =>
                                setState(() => _isLifetimeSelected = true),
                          ),
                          const SizedBox(height: 10),
                          _pricingCard(
                            title: 'Yearly',
                            price: _getProduct(AdManager.yearlyProductId)
                                    ?.price ??
                                '...',
                            subtitle: 'Billed once a year. Cancel anytime.',
                            badge: null,
                            badgeColor: Colors.white30,
                            isSelected: !_isLifetimeSelected,
                            theme: theme,
                            onTap: () =>
                                setState(() => _isLifetimeSelected = false),
                          ),
                          const SizedBox(height: 16),

                          // CTA button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed:
                                  _available && !_isLoading ? _buyProduct : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white))
                                  : Text(
                                      _isLifetimeSelected
                                          ? 'Get Lifetime Access'
                                          : 'Start Yearly Plan',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Trust badges
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _trustBadge(_isLifetimeSelected
                                  ? '\u2713  Lifetime'
                                  : '\u2713  Yearly'),
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 4),
                                child: Text('\u2022',
                                    style: TextStyle(
                                        color: Colors.white24,
                                        fontSize: 11)),
                              ),
                              _trustBadge(_isLifetimeSelected
                                  ? '\u2713  No subscription'
                                  : '\u2713  Cancel anytime'),
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 4),
                                child: Text('\u2022',
                                    style: TextStyle(
                                        color: Colors.white24,
                                        fontSize: 11)),
                              ),
                              _trustBadge('\u2713  No data shared'),
                            ],
                          ),
                          const SizedBox(height: 4),

                          TextButton(
                            onPressed: _restorePurchases,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white30,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 36),
                            ),
                            child: const Text(
                              'Already purchased? Restore Purchases',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _trustBadge(String text) => Text(text,
      style: const TextStyle(
          color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600));

  Widget _featureRow(
      IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: Colors.white,
                        letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12.5, color: Colors.white54, height: 1.3)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF4ADE80), size: 18),
        ],
      ),
    );
  }

  Widget _pricingCard({
    required String title,
    required String price,
    required String subtitle,
    required String? badge,
    required Color badgeColor,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    const selectedBorder = Color(0xFF9D97FF);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF9D97FF).withOpacity(0.09)
              : const Color(0xFF1C1B2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? selectedBorder
                : Colors.white.withOpacity(0.07),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected ? selectedBorder : Colors.white24,
                    width: 2),
                color:
                    isSelected ? selectedBorder : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white60)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(badge,
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  letterSpacing: 0.4)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: isSelected
                              ? Colors.white54
                              : Colors.white30,
                          fontSize: 11.5)),
                ],
              ),
            ),
            Text(price,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isSelected
                        ? const Color(0xFF9D97FF)
                        : Colors.white60)),
          ],
        ),
      ),
    );
  }
}

// ─── Image Resizer Hero Animation ──────────────────────────────────────────────

class _ImageResizerHero extends StatefulWidget {
  final double size;
  const _ImageResizerHero({required this.size});

  @override
  State<_ImageResizerHero> createState() => _ImageResizerHeroState();
}

class _ImageResizerHeroState extends State<_ImageResizerHero>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulse,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Rotating halo rings
            AnimatedBuilder(
              animation: _rotateCtrl,
              builder: (_, __) => Transform.rotate(
                angle: _rotateCtrl.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _HaloPainter(),
                ),
              ),
            ),

            // Centre card with app icon
            Container(
              width: widget.size * 0.68,
              height: widget.size * 0.68,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
                ),
                borderRadius: BorderRadius.circular(widget.size * 0.18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.45),
                    blurRadius: 30,
                    spreadRadius: -4,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_size_select_large_rounded,
                    size: widget.size * 0.25,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  const Text('PRO',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2)),
                ],
              ),
            ),

            // Crown badge
            Positioned(
              top: -8,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.black, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HaloPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;

    // Outer dashed ring
    final dashPaint = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    _drawDashedCircle(canvas, center, outerR - 2, dashPaint, 24);

    // Inner ring
    final innerPaint = Paint()
      ..color = const Color(0xFF9D97FF).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, outerR * 0.82, innerPaint);

    // Dots on outer ring
    final dotPaint = Paint()
      ..color = const Color(0xFF9D97FF).withOpacity(0.6)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final x = center.dx + (outerR - 2) * math.cos(angle);
      final y = center.dy + (outerR - 2) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
    }
  }

  void _drawDashedCircle(
      Canvas canvas, Offset center, double radius, Paint paint, int segments) {
    final step = (2 * math.pi) / segments;
    for (int i = 0; i < segments; i++) {
      if (i % 2 == 0) continue;
      final startAngle = i * step;
      final path = Path()
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          step * 0.75,
          false,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

