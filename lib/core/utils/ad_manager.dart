import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdManager {
  static final AdManager instance = AdManager._internal();
  AdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  int _interstitialRetryAttempt = 0;
  static const int _maxRetryAttempts = 5;

  bool _isPro = false;
  bool get isPro => _isPro;

  // IAP product IDs
  static const String productId = 'pro_lifetime';
  static const String yearlyProductId = 'pro_yearly';
  static const String legacyProductId = 'remove_ads_forever';

  List<ProductDetails> products = [];

  // Set by HomeScreen to break circular dependency
  static Future<void> Function(BuildContext context)? onShowPaywall;
  int _interstitialCount = 0;
  int _paywallThreshold = 3;

  // Ad unit IDs
  final String _realBannerId = 'ca-app-pub-4397005408366648/4695380015';
  final String _realInterstitialId = 'ca-app-pub-4397005408366648/5186334601';
  final String _realNativeId = 'ca-app-pub-4397005408366648/4850604320';

  final String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  final String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  final String _testNativeId = 'ca-app-pub-3940256099942544/2247696110';

  String get _bannerId => kDebugMode ? _testBannerId : _realBannerId;
  String get _interstitialId =>
      kDebugMode ? _testInterstitialId : _realInterstitialId;
  String get _nativeId => kDebugMode ? _testNativeId : _realNativeId;

  static const List<String> _testDeviceIds = [];

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('is_premium_user') ?? false;

    if (_isPro) {
      _validatePremiumState();
    } else {
      if (kDebugMode) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: _testDeviceIds),
        );
      }
      await MobileAds.instance.initialize();
      _loadInterstitial();
    }
  }

  Future<void> _validatePremiumState() async {
    try {
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) return;
      StreamSubscription<List<PurchaseDetails>>? sub;
      sub = iap.purchaseStream.listen(
        (purchases) {
          final hasPro = purchases.any(
            (p) =>
                (p.productID == productId ||
                    p.productID == yearlyProductId ||
                    p.productID == legacyProductId) &&
                (p.status == PurchaseStatus.purchased ||
                    p.status == PurchaseStatus.restored),
          );
          if (!hasPro) _disableProVersion();
          sub?.cancel();
        },
        onError: (_) => sub?.cancel(),
      );
      await iap.restorePurchases();
      Future.delayed(const Duration(seconds: 10), () => sub?.cancel());
    } catch (_) {}
  }

  Future<void> _disableProVersion() async {
    _isPro = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_user', false);
    if (kDebugMode) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
    }
    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  Future<void> enableProVersion() async {
    _isPro = true;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium_user', true);
    debugPrint('AdManager: Premium enabled!');
  }

  void _loadInterstitial() {
    if (_isPro || _isInterstitialLoading) return;
    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialRetryAttempt = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdManager: Interstitial failed: ${error.message}');
          _interstitialAd = null;
          _isInterstitialLoading = false;
          _retryInterstitialLoad();
        },
      ),
    );
  }

  void _retryInterstitialLoad() {
    if (_interstitialRetryAttempt >= _maxRetryAttempts) return;
    _interstitialRetryAttempt++;
    final delay = Duration(seconds: 1 << _interstitialRetryAttempt);
    Future.delayed(delay, () => _loadInterstitial());
  }

  void showInterstitial(BuildContext context, {VoidCallback? onAdDismissed}) {
    if (_isPro) {
      onAdDismissed?.call();
      return;
    }
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitial();
          _interstitialCount++;
          if (_interstitialCount >= _paywallThreshold) {
            _interstitialCount = 0;
            _paywallThreshold++;
            if (context.mounted && onShowPaywall != null) {
              onShowPaywall!(context).then((_) => onAdDismissed?.call());
            } else {
              onAdDismissed?.call();
            }
          } else {
            onAdDismissed?.call();
          }
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _loadInterstitial();
          onAdDismissed?.call();
        },
      );
      _interstitialAd!.show();
    } else {
      _loadInterstitial();
      onAdDismissed?.call();
    }
  }

  Widget getBannerAdWidget() {
    if (_isPro) return const SizedBox.shrink();
    return _BannerAdWrapper(adUnitId: _bannerId);
  }

  Widget getMediumNativeAdWidget() {
    if (_isPro) return const SizedBox.shrink();
    return _NativeAdWrapper(adUnitId: _nativeId);
  }

  Widget getSmallNativeAdWidget() {
    if (_isPro) return const SizedBox.shrink();
    return _SmallNativeAdWrapper(adUnitId: _nativeId);
  }
}

class _BannerAdWrapper extends StatefulWidget {
  final String adUnitId;
  const _BannerAdWrapper({required this.adUnitId});

  @override
  State<_BannerAdWrapper> createState() => _BannerAdWrapperState();
}

class _BannerAdWrapperState extends State<_BannerAdWrapper> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int _retryAttempt = 0;
  static const int _maxRetries = 4;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQueryData.fromView(
        PlatformDispatcher.instance.views.first,
      ).size.width.truncate(),
    );
    if (size == null || !mounted) return;
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _retryAttempt = 0;
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _retryLoad();
        },
      ),
    )..load();
  }

  void _retryLoad() {
    if (_retryAttempt >= _maxRetries || !mounted) return;
    _retryAttempt++;
    Future.delayed(Duration(seconds: 1 << _retryAttempt), () {
      if (mounted) _loadAd();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

class _SmallNativeAdWrapper extends StatefulWidget {
  final String adUnitId;
  const _SmallNativeAdWrapper({required this.adUnitId});

  @override
  State<_SmallNativeAdWrapper> createState() => _SmallNativeAdWrapperState();
}

class _SmallNativeAdWrapperState extends State<_SmallNativeAdWrapper> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  int _retryAttempt = 0;
  static const int _maxRetries = 4;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: widget.adUnitId,
      factoryId: 'adFactorySmall',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          _retryAttempt = 0;
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('SmallNativeAd failed to load: ${error.message}');
          ad.dispose();
          _retryLoad();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
      ),
    )..load();
  }

  void _retryLoad() {
    if (_retryAttempt >= _maxRetries || !mounted) return;
    _retryAttempt++;
    Future.delayed(Duration(seconds: 1 << _retryAttempt), () {
      if (mounted) _loadAd();
    });
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 320,
        minHeight: 80,
        maxHeight: 120,
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

class _NativeAdWrapper extends StatefulWidget {
  final String adUnitId;
  const _NativeAdWrapper({required this.adUnitId});

  @override
  State<_NativeAdWrapper> createState() => _NativeAdWrapperState();
}

class _NativeAdWrapperState extends State<_NativeAdWrapper> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  int _retryAttempt = 0;
  static const int _maxRetries = 4;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: widget.adUnitId,
      factoryId: 'adFactoryMedium',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          _retryAttempt = 0;
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAd failed to load: ${error.message}');
          ad.dispose();
          _retryLoad();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
    )..load();
  }

  void _retryLoad() {
    if (_retryAttempt >= _maxRetries || !mounted) return;
    _retryAttempt++;
    Future.delayed(Duration(seconds: 1 << _retryAttempt), () {
      if (mounted) _loadAd();
    });
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 320,
        minHeight: 320,
        maxHeight: 400,
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}
