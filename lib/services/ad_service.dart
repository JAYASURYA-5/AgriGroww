import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static bool _initialized = false;
  static bool get isMobile => false; // Forced to false to prevent WebView/GPU crashes on virtualized emulator environments

  // Central initialization method
  static Future<void> init() async {
    if (!isMobile) {
      debugPrint('AdService: Non-mobile platform. Running in Mock Ad Mode.');
      _initialized = true;
      return;
    }

    try {
      WidgetsFlutterBinding.ensureInitialized();
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('AdService: AdMob successfully initialized.');
    } catch (e) {
      debugPrint('AdService: Failed to initialize AdMob: $e');
    }
  }

  // --- 1. BANNER ADS ---
  // Returns a Widget representing a banner ad. Handles loading real banners or rendering mock banners.
  static Widget getBannerAdWidget() {
    if (!isMobile) {
      return const MockBannerAd();
    }
    return const RealBannerAd();
  }

  // --- 2. NATIVE ADS ---
  // Returns a Widget representing a native ad. Handles template-based AdMob native ads or custom styled mock native ads.
  static Widget getNativeAdWidget({double height = 90}) {
    if (!isMobile) {
      return MockNativeAd(height: height);
    }
    return RealNativeAd(height: height);
  }

  // --- 3. REWARDED ADS ---
  // Shows a rewarded video ad. On mobile, loads and plays a real AdMob video ad.
  // On desktop/non-mobile, displays an interactive countdown dialog to simulate the ad watch flow.
  static void showRewardedAd(BuildContext context, VoidCallback onRewardEarned) {
    if (!isMobile) {
      _showMockRewardedAd(context, onRewardEarned);
      return;
    }

    // Mobile rewarded ad loading & playback
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF22C55E)),
                SizedBox(height: 16),
                Text('Loading Sponsored Video...', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    RewardedAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917' // Android test ad unit
          : 'ca-app-pub-3940256099942544/1712485313', // iOS test ad unit
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          Navigator.of(context).pop(); // Dismiss loading spinner
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (RewardedAd ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
              ad.dispose();
              // Fallback to mock if real ad fails to display
              _showMockRewardedAd(context, onRewardEarned);
            },
          );

          ad.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            onRewardEarned();
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          Navigator.of(context).pop(); // Dismiss loading spinner
          debugPrint('AdService: RewardedAd failed to load: $error');
          // Fallback to mock on load failure
          _showMockRewardedAd(context, onRewardEarned);
        },
      ),
    );
  }

  // Interactive fullscreen mock rewarded ad
  static void _showMockRewardedAd(BuildContext context, VoidCallback onRewardEarned) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return const MockRewardedAdDialog();
      },
    ).then((rewarded) {
      if (rewarded == true) {
        onRewardEarned();
      }
    });
  }
}

// ============================================================================
// REAL ADMOB WIDGET IMPLEMENTATIONS
// ============================================================================

class RealBannerAd extends StatefulWidget {
  const RealBannerAd({Key? key}) : super(key: key);

  @override
  State<RealBannerAd> createState() => _RealBannerAdState();
}

class _RealBannerAdState extends State<RealBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
    FocusManager.instance.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
      final primaryFocus = FocusManager.instance.primaryFocus;
      final isInputFocused = primaryFocus != null && primaryFocus is! FocusScopeNode;
      if (isInputFocused) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            final currentFocus = FocusManager.instance.primaryFocus;
            final isStillFocused = currentFocus != null && currentFocus is! FocusScopeNode;
            if (isStillFocused) {
              SystemChannels.textInput.invokeMethod('TextInput.show');
            }
          }
        });
      }
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('RealBannerAd: Failed to load banner: $error');
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    final isInputFocused = primaryFocus != null && primaryFocus is! FocusScopeNode;
    if ((MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0) > 0 || isInputFocused) {
      return const SizedBox();
    }
    if (_isLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // Fallback to mock ad widget while loading or on failure
    return const MockBannerAd();
  }
}

class RealNativeAd extends StatefulWidget {
  final double height;
  const RealNativeAd({Key? key, required this.height}) : super(key: key);

  @override
  State<RealNativeAd> createState() => _RealNativeAdState();
}

class _RealNativeAdState extends State<RealNativeAd> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
    FocusManager.instance.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
      final primaryFocus = FocusManager.instance.primaryFocus;
      final isInputFocused = primaryFocus != null && primaryFocus is! FocusScopeNode;
      if (isInputFocused) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            final currentFocus = FocusManager.instance.primaryFocus;
            final isStillFocused = currentFocus != null && currentFocus is! FocusScopeNode;
            if (isStillFocused) {
              SystemChannels.textInput.invokeMethod('TextInput.show');
            }
          }
        });
      }
    }
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/2247696110'
          : 'ca-app-pub-3940256099942544/3986694507',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('RealNativeAd: Failed to load native ad: $error');
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 12.0,
      ),
    );
    _nativeAd!.load();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChanged);
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    final isInputFocused = primaryFocus != null && primaryFocus is! FocusScopeNode;
    if ((MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0) > 0 || isInputFocused) {
      return const SizedBox();
    }
    if (_isLoaded && _nativeAd != null) {
      return Container(
        height: widget.height,
        alignment: Alignment.center,
        child: AdWidget(ad: _nativeAd!),
      );
    }
    return MockNativeAd(height: widget.height);
  }
}

// ============================================================================
// HIGH-FIDELITY MOCK AD COMPONENTS FOR WINDOWS/TESTING
// ============================================================================

class MockBannerAd extends StatelessWidget {
  const MockBannerAd({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    final isInputFocused = primaryFocus != null && primaryFocus is! FocusScopeNode;
    if ((MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0) > 0 || isInputFocused) {
      return const SizedBox();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 54,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B281E), const Color(0xFF162A1F)]
              : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF22C55E).withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Stack(
        children: [
          // "Ad" badge
          Positioned(
            left: 8,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF22C55E), width: 0.8),
              ),
              child: const Text(
                'AD',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF22C55E),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  color: Color(0xFF22C55E),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sponsored Ad: High-Yield Agri Seeds',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MockNativeAd extends StatelessWidget {
  final double height;
  const MockNativeAd({Key? key, required this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    final isInputFocused = primaryFocus != null && primaryFocus is! FocusScopeNode;
    if ((MediaQuery.maybeOf(context)?.viewInsets.bottom ?? 0) > 0 || isInputFocused) {
      return const SizedBox();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF22C55E).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ad Image placeholder
          Container(
            width: height - 16,
            height: height - 16,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF22C55E).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.spa_outlined,
                color: Color(0xFF22C55E),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Sponsored',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'AgriGrow Organic Fertilizers',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Boost your crop output up to 40% with biological nutrients.',
                  maxLines: height > 70 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Call to Action
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'INSTALL',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class MockRewardedAdDialog extends StatefulWidget {
  const MockRewardedAdDialog({Key? key}) : super(key: key);

  @override
  State<MockRewardedAdDialog> createState() => _MockRewardedAdDialogState();
}

class _MockRewardedAdDialogState extends State<MockRewardedAdDialog> {
  int _secondsRemaining = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        if (mounted) {
          Navigator.of(context).pop(true); // Close and award reward
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Ad Completed! Reward Unlocked successfully.'),
              backgroundColor: Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Black screen with organic visual circles
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withOpacity(0.06),
              ),
            ),
          ),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.play_circle_fill,
                color: Color(0xFF22C55E),
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                'AgriGrow Premium Sponsor',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Watch this short sponsor spot to unlock advanced calculations and download capabilities.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF22C55E), width: 3),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$_secondsRemaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Reward in $_secondsRemaining seconds...',
                style: const TextStyle(
                  color: Color(0xFF22C55E),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          // Skip button
          Positioned(
            top: 24,
            right: 24,
            child: TextButton.icon(
              onPressed: () {
                _timer?.cancel();
                Navigator.of(context).pop(false); // Cancel ad watch
              },
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              label: const Text('Skip Ad', style: TextStyle(color: Colors.white, fontSize: 13)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
