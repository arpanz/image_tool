import 'dart:async';
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
          ));
        }
      } else if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        final known = {AdManager.productId, AdManager.yearlyProductId, AdManager.legacyProductId};
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
        content: Text('Pixel Forge Pro activated! All features unlocked.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _buyProduct() async {
    if (_products.isEmpty) return;
    final id = _isLifetimeSelected ? AdManager.productId : AdManager.yearlyProductId;
    final product = _getProduct(id);
    if (product == null) return;
    _purchaseHandled = false;
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
            content: Text('No previous purchases found.'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      });
    } catch (e) {
      _restoreTimer?.cancel();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Builder(builder: (context) {
        const accent = Color(0xFFFFD700);
        final theme = Theme.of(context);
        return Scaffold(
          backgroundColor: const Color(0xFF0F1120),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF151829), Color(0xFF0D0F1A)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Close button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white54, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            const SizedBox(height: 4),
                            // Hero icon animation
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: const _HeroAnimation(size: 120),
                            ),
                            const SizedBox(height: 24),

                            // Headline
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Unlock Pixel Forge Pro',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.8,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Process images without limits. Ad-free, forever.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.white54,
                                    height: 1.5),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Feature list
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  _featureRow(Icons.compress_rounded,
                                      'Unlimited Compressions',
                                      'No daily caps — compress as much as you want.',
                                      Colors.blueAccent),
                                  _featureRow(Icons.photo_size_select_large_rounded,
                                      'Unlimited Resizes',
                                      'Resize freely with all fit modes unlocked.',
                                      Colors.purpleAccent),
                                  _featureRow(Icons.block_flipped,
                                      'Ad-Free Experience',
                                      'Zero interruptions, no banners, no interstitials.',
                                      const Color(0xFFFF6B6B)),
                                  _featureRow(Icons.bolt_rounded,
                                      'Priority Processing',
                                      'Batch-friendly, fast pipeline reserved for Pro.',
                                      Colors.orangeAccent),
                                  _featureRow(Icons.star_rounded,
                                      'All Future Features',
                                      'Every new feature ships to Pro first.',
                                      Colors.tealAccent),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom panel
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181B2E),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 24,
                            offset: const Offset(0, -6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                            price: _getProduct(AdManager.productId)?.price ?? '...',
                            subtitle: 'One-time payment. Own forever.',
                            badge: 'BEST VALUE',
                            badgeColor: accent,
                            isSelected: _isLifetimeSelected,
                            theme: theme,
                            onTap: () => setState(() => _isLifetimeSelected = true),
                          ),
                          const SizedBox(height: 10),
                          _pricingCard(
                            title: 'Yearly',
                            price: _getProduct(AdManager.yearlyProductId)?.price ?? '...',
                            subtitle: 'Billed annually. Cancel anytime.',
                            badge: null,
                            badgeColor: Colors.white30,
                            isSelected: !_isLifetimeSelected,
                            theme: theme,
                            onTap: () => setState(() => _isLifetimeSelected = false),
                          ),
                          const SizedBox(height: 16),

                          // CTA
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _available && !_isLoading ? _buyProduct : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5, color: Colors.black))
                                  : Text(
                                      _isLifetimeSelected
                                          ? 'Get Lifetime Access'
                                          : 'Start Yearly Plan',
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w700)),
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
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text('\u2022',
                                    style: TextStyle(
                                        color: Colors.white24, fontSize: 11)),
                              ),
                              _trustBadge(_isLifetimeSelected
                                  ? '\u2713  No subscription'
                                  : '\u2713  Cancel anytime'),
                            ],
                          ),
                          const SizedBox(height: 4),

                          TextButton(
                            onPressed: _restorePurchases,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white38,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 36),
                            ),
                            child: const Text(
                              'Already purchased? Restore Purchases',
                              style: TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w500),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
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
                        color: Colors.white)),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFFD700).withOpacity(0.08)
              : const Color(0xFF222540),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFD700)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFD700)
                        : Colors.white24,
                    width: 2),
                color: isSelected
                    ? const Color(0xFFFFD700)
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.black, size: 14)
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
                                  : Colors.white70)),
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
                                  fontSize: 9.5,
                                  letterSpacing: 0.3)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: isSelected
                              ? Colors.white54
                              : Colors.white38,
                          fontSize: 11.5)),
                ],
              ),
            ),
            Text(price,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: isSelected
                        ? const Color(0xFFFFD700)
                        : Colors.white60)),
          ],
        ),
      ),
    );
  }
}

// Animated hero for Pixel Forge (image tool theme)
class _HeroAnimation extends StatefulWidget {
  final double size;
  const _HeroAnimation({required this.size});

  @override
  State<_HeroAnimation> createState() => _HeroAnimationState();
}

class _HeroAnimationState extends State<_HeroAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
    _loop();
  }

  void _loop() async {
    while (mounted) {
      try {
        await _ctrl.forward();
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) break;
        await _ctrl.reverse();
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (_) {
        break;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _ImageFramePainter(
                value: _anim.value,
                baseColor: Colors.white.withOpacity(0.06),
                accentColor: const Color(0xFF6C63FF),
              ),
            ),
          ),
        ),
        Positioned(
          top: -12,
          right: -8,
          child: Transform.rotate(
            angle: 0.35,
            child: const Icon(Icons.workspace_premium_rounded,
                color: Color(0xFFFFD700), size: 40,
                shadows: [
                  Shadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      offset: Offset(2, 2))
                ]),
          ),
        ),
      ],
    );
  }
}

class _ImageFramePainter extends CustomPainter {
  final double value;
  final Color baseColor;
  final Color accentColor;

  _ImageFramePainter(
      {required this.value,
      required this.baseColor,
      required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Draw base image frame grid
    _drawImageFrame(canvas, size, bgPaint);

    // Animated accent overlay (diagonal reveal)
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF9D97FF),
          accentColor,
          const Color(0xFF4B45CC),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final maxExtent = size.width + size.height;
    final currentExtent = maxExtent * value;
    final revealPath = Path()
      ..moveTo(0, 0)
      ..lineTo(currentExtent, 0)
      ..lineTo(0, currentExtent)
      ..close();

    canvas.save();
    canvas.clipPath(revealPath);
    accentPaint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    _drawImageFrame(canvas, size, accentPaint);
    accentPaint.maskFilter = null;
    _drawImageFrame(canvas, size, accentPaint);
    canvas.restore();
  }

  void _drawImageFrame(Canvas canvas, Size size, Paint paint) {
    final p = 10.0;
    final r = size.width * 0.18;
    // Outer frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(p, p, size.width - p, size.height - p),
        Radius.circular(r),
      ),
      paint,
    );
    // Inner content area (simulate image)
    final ip = p + 14;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(ip, ip + size.height * 0.2, size.width - ip,
            size.height - ip),
        Radius.circular(r * 0.5),
      ),
      paint,
    );
    // Mountain/landscape lines
    final mid = size.width / 2;
    final path = Path()
      ..moveTo(p + 8, size.height - p - 8)
      ..lineTo(mid - 12, p + size.height * 0.35)
      ..lineTo(mid + 8, p + size.height * 0.45)
      ..lineTo(size.width - p - 8, p + size.height * 0.28);
    canvas.drawPath(path, paint);
    // Sun circle
    canvas.drawCircle(
        Offset(size.width * 0.72, p + size.height * 0.22), 8, paint);
  }

  @override
  bool shouldRepaint(covariant _ImageFramePainter old) =>
      old.value != value;
}
