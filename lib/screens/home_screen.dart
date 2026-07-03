import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/live_data_card.dart';
import '../widgets/intercrop_card.dart';
import '../widgets/quick_action_button.dart';
import '../services/app_state.dart';
import 'weather_forecast_screen.dart';
import 'intercrop_advisor_screen.dart';
import 'agribot_screen.dart';
import 'lms_screen.dart';
import 'disease_prediction_screen.dart';
import 'notes_screen.dart';
import 'livestock_screen.dart';
import 'crop_calendar_screen.dart';
import 'finance_screen.dart';
import 'market_prices_screen.dart';
import 'market_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'news_screen.dart';
import 'scheme_screen.dart';
import 'video_feed_screen.dart';
import 'agrihub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedIndex;

  // Weather Banner Image Carousel variables (all cards are agriculture related)
  int _currentImageIndex = 0;
  Timer? _weatherTimer;
  final List<String> _carouselImages = [
    'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?w=800&q=80', // generic agriculture/plants
    'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=800&q=80', // farmer spraying field
    'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=800&q=80', // tractor cultivating
    'https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=800&q=80', // sprouts in tray
    'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800&q=80', // sunset wheat field
  ];

  // Daily Agricultural Advisories Carousel variables
  final PageController _advisoryPageController = PageController(initialPage: 0);
  int _currentAdvisoryIndex = 0;
  Timer? _advisoryTimer;

  @override
  void initState() {
    super.initState();
    // Weather banner image carousel timer (4 seconds cycle)
    _weatherTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % _carouselImages.length;
        });
      }
    });
    // Agricultural card advisories carousel timer (5 seconds cycle)
    _advisoryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        final nextPage = (_currentAdvisoryIndex + 1) % 4;
        if (_advisoryPageController.hasClients) {
          _advisoryPageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    _advisoryTimer?.cancel();
    _advisoryPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState().languageNotifier,
      builder: (context, lang, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textCol = Theme.of(context).colorScheme.onSurface;
        final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
        final cardBg = Theme.of(context).cardColor;
        final dividerCol = Theme.of(context).dividerColor;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section with Greeting
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                    color: scaffoldBg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Section
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                ).then((_) {
                                  // Refresh home state on returning from ProfileScreen to sync edits
                                  setState(() {});
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFF22C55E), width: 2),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    final photo = AppState()
                                        .currentUser?['photo']
                                        ?.toString();
                                    ImageProvider imgProvider;
                                    if (photo == null || photo.isEmpty) {
                                      imgProvider = const NetworkImage(
                                          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=120&q=80');
                                    } else if (photo.startsWith('http')) {
                                      imgProvider = NetworkImage(photo);
                                    } else {
                                      imgProvider = FileImage(File(photo));
                                    }
                                    return CircleAvatar(
                                      radius: 18,
                                      backgroundColor: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      backgroundImage: imgProvider,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Arigrow',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Greeting Text
                        RichText(
                          text: TextSpan(
                            text: AppLocalizations.translate(
                                lang, 'good_morning'),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textCol,
                            ),
                            children: [
                              TextSpan(
                                text: AppState().currentUser?['fullName'] ??
                                    'User',
                                style: const TextStyle(
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Weather Card (Coimbatore)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B281E)
                            : const Color(0xFFF9FDF9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2E4031)
                              : const Color(0xFFE8F5E9),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Farmer Image with Auto slideshow crossfade transitions (Asset & Network)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 1000),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              child: _carouselImages[_currentImageIndex]
                                      .startsWith('http')
                                  ? Image.network(
                                      _carouselImages[_currentImageIndex],
                                      key: ValueKey<int>(_currentImageIndex),
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      _carouselImages[_currentImageIndex],
                                      key: ValueKey<int>(_currentImageIndex),
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Coimbatore location
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Color(0xFF22C55E), size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      (AppState().currentUser?['location'] ??
                                              'Coimbatore')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textCol.withOpacity(0.8),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.translate(
                                      lang, 'current_weather'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '31°C',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.translate(lang, 'overcast'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textCol,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // No rain expected
                                Row(
                                  children: [
                                    const Icon(Icons.check_box,
                                        color: Color(0xFF22C55E), size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppLocalizations.translate(
                                          lang, 'no_rain'),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Humidity & Wind Speed row
                                Row(
                                  children: [
                                    // Humidity
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.opacity,
                                              color: Color(0xFF22C55E),
                                              size: 24),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppLocalizations.translate(
                                                    lang, 'humidity_title'),
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '48%',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: textCol,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Wind Speed
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.air,
                                              color: Color(0xFF22C55E),
                                              size: 24),
                                          const SizedBox(width: 8),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                AppLocalizations.translate(
                                                    lang, 'wind_speed'),
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '13 km/h',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: textCol,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // View Detailed Forecast Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const WeatherForecastScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.calendar_today,
                                        color: Colors.black, size: 18),
                                    label: Text(
                                      AppLocalizations.translate(
                                          lang, 'view_detailed_forecast'),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(
                                          0xFF00FF66), // Vibrant neon green
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Auto-changing Agricultural Advisory Cards Carousel
                  SizedBox(
                    height: 180,
                    child: PageView(
                      controller: _advisoryPageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentAdvisoryIndex = index;
                        });
                      },
                      children: [
                        _buildAdvisoryCard(
                          context,
                          isDark,
                          textCol,
                          category: AppLocalizations.translate(
                              lang, 'pest_alert_cat'),
                          title: AppLocalizations.translate(
                              lang, 'pest_alert_title'),
                          desc: AppLocalizations.translate(
                              lang, 'pest_alert_desc'),
                          actionLabel: AppLocalizations.translate(
                              lang, 'pest_alert_action'),
                          icon: Icons.bug_report,
                          primaryColor: const Color(0xFFEF4444),
                          bgColor: isDark
                              ? const Color(0xFF2C1616)
                              : const Color(0xFFFEE2E2),
                          borderColor: isDark
                              ? const Color(0xFF5A2020)
                              : const Color(0xFFFCA5A5),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DiseasePredictionScreen(),
                              ),
                            );
                          },
                        ),
                        _buildAdvisoryCard(
                          context,
                          isDark,
                          textCol,
                          category: AppLocalizations.translate(
                              lang, 'fertilizer_cat'),
                          title: AppLocalizations.translate(
                              lang, 'fertilizer_title'),
                          desc: AppLocalizations.translate(
                              lang, 'fertilizer_desc'),
                          actionLabel: AppLocalizations.translate(
                              lang, 'fertilizer_action'),
                          icon: Icons.science_outlined,
                          primaryColor: const Color(0xFFA855F7),
                          bgColor: isDark
                              ? const Color(0xFF1F162C)
                              : const Color(0xFFF3E8FF),
                          borderColor: isDark
                              ? const Color(0xFF432A5F)
                              : const Color(0xFFE9D5FF),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AgriBotScreen(),
                              ),
                            );
                          },
                        ),
                        _buildAdvisoryCard(
                          context,
                          isDark,
                          textCol,
                          category: AppLocalizations.translate(
                              lang, 'market_alert_cat'),
                          title: AppLocalizations.translate(
                              lang, 'market_alert_title'),
                          desc: AppLocalizations.translate(
                              lang, 'market_alert_desc'),
                          actionLabel: AppLocalizations.translate(
                              lang, 'market_alert_action'),
                          icon: Icons.trending_up,
                          primaryColor: const Color(0xFFEA580C),
                          bgColor: isDark
                              ? const Color(0xFF2E1C0F)
                              : const Color(0xFFFFF7ED),
                          borderColor: isDark
                              ? const Color(0xFF5E3A1A)
                              : const Color(0xFFFFEDD5),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MarketPricesScreen(),
                              ),
                            );
                          },
                        ),
                        _buildAdvisoryCard(
                          context,
                          isDark,
                          textCol,
                          category:
                              AppLocalizations.translate(lang, 'intercrop_cat'),
                          title: AppLocalizations.translate(
                              lang, 'intercrop_title'),
                          desc: AppLocalizations.translate(
                              lang, 'intercrop_desc'),
                          actionLabel: AppLocalizations.translate(
                              lang, 'intercrop_action'),
                          icon: Icons.eco_outlined,
                          primaryColor: const Color(0xFF22C55E),
                          bgColor: isDark
                              ? const Color(0xFF132A18)
                              : const Color(0xFFE8F5E9),
                          borderColor: isDark
                              ? const Color(0xFF1E4D26)
                              : const Color(0xFFC8E6C9),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const IntercropAdvisorScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Indicator dots row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _currentAdvisoryIndex == index ? 18 : 6,
                        decoration: BoxDecoration(
                          color: _currentAdvisoryIndex == index
                              ? const Color(0xFF22C55E)
                              : (isDark ? Colors.grey[700] : Colors.grey[350]),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Live Data Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.translate(lang, 'live_data'),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AgriBotScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFC2FBD7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.smart_toy_outlined,
                                  color: Color(0xFF22C55E),
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.35,
                          children: [
                            LiveDataCard(
                              icon: Icons.water_drop,
                              iconColor: const Color(0xFF06B6D4),
                              title: AppLocalizations.translate(
                                  lang, 'soil_moisture'),
                              value: '62%',
                              status:
                                  AppLocalizations.translate(lang, 'optimal'),
                              backgroundColor: isDark
                                  ? const Color(0xFF162A35)
                                  : const Color(0xFFECF9FF),
                            ),
                            LiveDataCard(
                              icon: Icons.thermostat,
                              iconColor: const Color(0xFFFF6B35),
                              title: AppLocalizations.translate(
                                  lang, 'temperature'),
                              value: '24°C',
                              status:
                                  AppLocalizations.translate(lang, 'optimal'),
                              backgroundColor: isDark
                                  ? const Color(0xFF2C1E18)
                                  : const Color(0xFFFFF5ED),
                            ),
                            LiveDataCard(
                              icon: Icons.opacity,
                              iconColor: const Color(0xFF06B6D4),
                              title:
                                  AppLocalizations.translate(lang, 'humidity'),
                              value: '68%',
                              status:
                                  AppLocalizations.translate(lang, 'optimal'),
                              backgroundColor: isDark
                                  ? const Color(0xFF162A35)
                                  : const Color(0xFFECF9FF),
                            ),
                            LiveDataCard(
                              icon: Icons.science,
                              iconColor: const Color(0xFFA855F7),
                              title:
                                  AppLocalizations.translate(lang, 'soil_ph'),
                              value: '6.8',
                              status:
                                  AppLocalizations.translate(lang, 'optimal'),
                              backgroundColor: isDark
                                  ? const Color(0xFF231E2B)
                                  : const Color(0xFFF3E8FF),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Intercrop Suggestion Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.translate(
                                  lang, 'intercrop_suggestion'),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const IntercropAdvisorScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                AppLocalizations.translate(lang, 'view_report'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF22C55E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const IntercropCard(
                          cropHealth: '92%',
                          healthDescription:
                              'Your crops are in excellent\ncondition. Minimal stress detected\nacross all zones.',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Quick Actions Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.translate(lang, 'quick_actions'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.9,
                          children: [
                            QuickActionButton(
                              icon: Icons.school,
                              label: AppLocalizations.translate(lang, 'lms'),
                              color: isDark
                                  ? const Color(0xFF3F51B5).withOpacity(0.15)
                                  : const Color(0xFFE8EAF6),
                              iconColor: const Color(0xFF3F51B5),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LmsScreen(),
                                  ),
                                );
                              },
                            ),
                            QuickActionButton(
                              icon: Icons.photo_camera_outlined,
                              label: AppLocalizations.translate(
                                  lang, 'disease_detection'),
                              color: isDark
                                  ? const Color(0xFFE53935).withOpacity(0.15)
                                  : const Color(0xFFFFEBEE),
                              iconColor: const Color(0xFFE53935),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DiseasePredictionScreen(),
                                  ),
                                );
                              },
                            ),
                            QuickActionButton(
                              icon: Icons.article_outlined,
                              label: AppLocalizations.translate(lang, 'notes'),
                              color: isDark
                                  ? const Color(0xFFFBC02D).withOpacity(0.15)
                                  : const Color(0xFFFFFDE7),
                              iconColor: const Color(0xFFFBC02D),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotesScreen(),
                                  ),
                                );
                              },
                            ),
                            QuickActionButton(
                              icon: Icons.newspaper_outlined,
                              label: AppLocalizations.translate(lang, 'news'),
                              color: isDark
                                  ? const Color(0xFFF57C00).withOpacity(0.15)
                                  : const Color(0xFFFFF3E0),
                              iconColor: const Color(0xFFF57C00),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NewsScreen(),
                                  ),
                                );
                              },
                            ),
                            QuickActionButton(
                              icon: Icons.verified_user_outlined,
                              label: AppLocalizations.translate(lang, 'scheme'),
                              color: isDark
                                  ? const Color(0xFF00BFA5).withOpacity(0.15)
                                  : const Color(0xFFE8F8F5),
                              iconColor: const Color(0xFF00BFA5),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SchemeScreen(),
                                  ),
                                );
                              },
                            ),
                            QuickActionButton(
                              icon: Icons.trending_up,
                              label: AppLocalizations.translate(
                                  lang, 'market_prices'),
                              color: isDark
                                  ? const Color(0xFFFFB300).withOpacity(0.15)
                                  : const Color(0xFFFFF8E1),
                              iconColor: const Color(0xFFFFB300),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MarketPricesScreen(),
                                  ),
                                );
                              },
                            ),
                            QuickActionButton(
                              icon: Icons.credit_card_outlined,
                              label:
                                  AppLocalizations.translate(lang, 'finance'),
                              color: isDark
                                  ? const Color(0xFF673AB7).withOpacity(0.15)
                                  : const Color(0xFFEDE7F6),
                              iconColor: const Color(0xFF673AB7),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FinanceScreen(),
                                  ),
                                );
                              },
                            ),
                            QuickActionButton(
                              icon: Icons.calendar_month_outlined,
                              label: AppLocalizations.translate(
                                  lang, 'crop_calendar'),
                              color: isDark
                                  ? const Color(0xFF00ACC1).withOpacity(0.15)
                                  : const Color(0xFFE0F7FA),
                              iconColor: const Color(0xFF00ACC1),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const CropCalendarScreen(),
                                  ),
                                );
                              },
                            ),
                            QuickActionButton(
                              icon: Icons.pets,
                              label:
                                  AppLocalizations.translate(lang, 'livestock'),
                              color: isDark
                                  ? const Color(0xFFFF5722).withOpacity(0.15)
                                  : const Color(0xFFFBE9E7),
                              iconColor: const Color(0xFFFF5722),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LivestockHomeScreen(),
                                  ),
                                );
                              },
                            ),
                            QuickActionButton(
                              icon: Icons.hub_outlined,
                              label:
                                  AppLocalizations.translate(lang, 'agrihub'),
                              color: isDark
                                  ? const Color(0xFF4CAF50).withOpacity(0.15)
                                  : const Color(0xFFE8F5E9),
                              iconColor: const Color(0xFF4CAF50),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AgriHubScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.school),
                label: AppLocalizations.translate(lang, 'lms'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people),
                label: AppLocalizations.translate(lang, 'community'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.shopping_bag),
                label: AppLocalizations.translate(lang, 'market'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.pets),
                label: AppLocalizations.translate(lang, 'livestock'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.newspaper),
                label: AppLocalizations.translate(lang, 'news'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.settings),
                label: AppLocalizations.translate(lang, 'settings'),
              ),
            ],
            currentIndex: _selectedIndex ?? 0,
            selectedItemColor: _selectedIndex != null
                ? const Color(0xFF22C55E)
                : Colors.grey[400],
            unselectedItemColor: Colors.grey[400],
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
              if (index == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LmsScreen(),
                  ),
                ).then((_) {
                  setState(() {
                    _selectedIndex = null;
                  });
                });
              } else if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoFeedScreen(),
                  ),
                ).then((_) {
                  setState(() {
                    _selectedIndex = null;
                  });
                });
              } else if (index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MarketScreen(),
                  ),
                ).then((_) {
                  setState(() {
                    _selectedIndex = null;
                  });
                });
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LivestockHomeScreen(),
                  ),
                ).then((_) {
                  setState(() {
                    _selectedIndex = null;
                  });
                });
              } else if (index == 4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewsScreen(),
                  ),
                ).then((_) {
                  setState(() {
                    _selectedIndex = null;
                  });
                });
              } else if (index == 5) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ).then((_) {
                  setState(() {
                    _selectedIndex = null;
                  });
                });
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildAdvisoryCard(
    BuildContext context,
    bool isDark,
    Color textCol, {
    required String category,
    required String title,
    required String desc,
    required String actionLabel,
    required IconData icon,
    required Color primaryColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
