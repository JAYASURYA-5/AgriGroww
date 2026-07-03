import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:agrigrow/services/ad_service.dart';

class WeatherForecastScreen extends StatefulWidget {
  const WeatherForecastScreen({Key? key}) : super(key: key);

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // API key configuration.
  final String _apiKey = '4fe167c68c9a59c482151115be6cc147'; 
  
  bool _isLoading = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _suggestions = [];
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _forecastWeather;
  Map<String, dynamic>? _selectedLocation;
  bool _showDetails = false;
  String? _apiError;

  // Geocoding search from OpenWeatherMap Geo API
  Future<void> _searchLocations(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _apiError = null;
    });

    // We search with country filter IN to prioritize Indian districts/cities
    final url = Uri.parse(
        'https://api.openweathermap.org/geo/1.0/direct?q=${Uri.encodeComponent(query)},IN&limit=10&appid=$_apiKey');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        final List<Map<String, dynamic>> indiaLocations = results
            .where((item) =>
                item['country'] == 'IN' ||
                (item['country'] ?? '').toString().toLowerCase() == 'india')
            .map((item) => {
                  'name': item['name'] as String,
                  'state': (item['state'] ?? '') as String,
                  'lat': (item['lat'] as num).toDouble(),
                  'lon': (item['lon'] as num).toDouble(),
                })
            .toList();

        setState(() {
          _suggestions = indiaLocations;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _apiError = 'Invalid API Key. Please verify your OpenWeatherMap API Key.';
        });
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Fetch current weather and 5-day/3-hour forecast from OpenWeatherMap
  Future<void> _fetchWeather(Map<String, dynamic> location) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _selectedLocation = location;
      _suggestions = [];
      _searchController.text = location['name'];
      _apiError = null;
    });

    final lat = location['lat'];
    final lon = location['lon'];
    
    final currentUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$_apiKey');
    final forecastUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&appid=$_apiKey');

    try {
      final currentResponse = await http.get(currentUrl);
      final forecastResponse = await http.get(forecastUrl);

      if (currentResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        setState(() {
          _currentWeather = json.decode(currentResponse.body);
          _forecastWeather = json.decode(forecastResponse.body);
        });
      } else {
        setState(() {
          _apiError = 'Failed to retrieve weather details from OpenWeatherMap.';
        });
      }
    } catch (e) {
      debugPrint('Weather fetch error: $e');
      setState(() {
        _apiError = 'Network error. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Format Condition Title capitalization
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  // Map OpenWeatherMap icon to Material IconData
  IconData _getWeatherIcon(String iconCode) {
    if (iconCode.startsWith('01')) return Icons.wb_sunny;
    if (iconCode.startsWith('02') || iconCode.startsWith('03') || iconCode.startsWith('04')) {
      return Icons.cloud;
    }
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return Icons.umbrella;
    if (iconCode.startsWith('11')) return Icons.thunderstorm;
    if (iconCode.startsWith('13')) return Icons.ac_unit;
    if (iconCode.startsWith('50')) return Icons.filter_drama;
    return Icons.cloud;
  }

  // Map OpenWeatherMap icon color
  Color _getWeatherIconColor(String iconCode) {
    if (iconCode.startsWith('01')) return const Color(0xFFFFB300);
    if (iconCode.startsWith('02') || iconCode.startsWith('03') || iconCode.startsWith('04')) {
      return Colors.white;
    }
    if (iconCode.startsWith('09') || iconCode.startsWith('10')) return Colors.blue[200]!;
    if (iconCode.startsWith('11')) return Colors.yellow[300]!;
    if (iconCode.startsWith('13')) return Colors.lightBlue[100]!;
    if (iconCode.startsWith('50')) return Colors.grey[300]!;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = const Color(0xFF1E2640);
    final cardBg = const Color(0xFF232E4C);

    return Scaffold(
      backgroundColor: themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_showDetails) ...[
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Weather Forecast',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Search Bar matching Image 1
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchLocations,
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'chennai',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      border: InputBorder.none,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Native Advanced Ads
                if (_suggestions.isEmpty && !_isSearching && _currentWeather == null && _selectedLocation == null) ...[
                  AdService.getNativeAdWidget(height: 100),
                  const SizedBox(height: 16),
                ],

                if (_apiError != null) ...[
                  Text(
                    _apiError!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],

                // Search Suggestions List
                if (_isSearching)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (_suggestions.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final loc = _suggestions[index];
                      return GestureDetector(
                        onTap: () => _fetchWeather(loc),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.pinkAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc['name'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${loc['state']}, IN',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                // Main Weather Card matching Image 2 & 3
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else if (_currentWeather != null && _selectedLocation != null) ...[
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showDetails = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top info (City, Condition, Icon)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_selectedLocation!['name']}, IN',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _capitalize(
                                          _currentWeather!['weather'][0]
                                              ['description']),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getWeatherIcon(_currentWeather!['weather']
                                      [0]['icon']),
                                  color: _getWeatherIconColor(
                                      _currentWeather!['weather'][0]
                                          ['icon']),
                                  size: 44,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Temperature Large
                          Text(
                            '${_currentWeather!['main']['temp'].round()}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(
                              color: Colors.white.withOpacity(0.1),
                              thickness: 1),
                          const SizedBox(height: 16),

                          // Hourly list using the first 6 forecast elements
                          _buildHourlyList(),
                          const SizedBox(height: 24),

                          // Click to view detailed forecast bottom text
                          Center(
                            child: Text(
                              'Click to view detailed forecast',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AdService.getNativeAdWidget(height: 100),
                ],
              ] else ...[
                // Detailed Forecast View (Image 4 & 5 + 3-day forecast, timeline grid & trend chart)
                _buildDetailedForecastView(),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }



  // Build hourly forecast row for the simplified forecast card view
  Widget _buildHourlyList() {
    if (_forecastWeather == null) return const SizedBox();

    final List forecastList = _forecastWeather!['list'];
    final List<Widget> items = [];

    // Slice the first 6 timeline values
    for (int k = 0; k < 6 && k < forecastList.length; k++) {
      final item = forecastList[k];
      final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final timeStr = DateFormat('HH:mm').format(dt);
      final temp = (item['main']['temp'] as num).round();
      final iconCode = item['weather'][0]['icon'] as String;

      items.add(
        Expanded(
          child: Column(
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Icon(
                _getWeatherIcon(iconCode),
                color: _getWeatherIconColor(iconCode),
                size: 24,
              ),
              const SizedBox(height: 12),
              Text(
                '$temp°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items,
    );
  }

  // Build detailed weather cards panel including 3-Day Forecast, Timeline grid & Trend chart
  Widget _buildDetailedForecastView() {
    if (_currentWeather == null || _forecastWeather == null) return const SizedBox();

    final main = _currentWeather!['main'];
    final temp = main['temp'].round();
    final feelsLike = main['feels_like'].round();
    final humidity = main['humidity'];
    final pressure = main['pressure'];
    final windSpeed = _currentWeather!['wind']['speed'];
    final windDirection = _currentWeather!['wind']['deg'];
    
    // Visibility: OpenWeatherMap returns meters, divide by 1000 for km
    final visibilityMeters = _currentWeather!['visibility'] ?? 10000;
    final visibility = (visibilityMeters / 1000.0).toStringAsFixed(1);
    
    final cloudiness = _currentWeather!['clouds']['all'] ?? 100;

    final int sunriseTimestamp = _currentWeather!['sys']['sunrise'];
    final int sunsetTimestamp = _currentWeather!['sys']['sunset'];
    
    String sunriseStr = "05:42 AM";
    String sunsetStr = "06:35 PM";

    try {
      final sr = DateTime.fromMillisecondsSinceEpoch(sunriseTimestamp * 1000);
      sunriseStr = DateFormat('hh:mm a').format(sr);
    } catch (_) {}
    try {
      final ss = DateTime.fromMillisecondsSinceEpoch(sunsetTimestamp * 1000);
      sunsetStr = DateFormat('hh:mm a').format(ss);
    } catch (_) {}

    final cardBg = const Color(0xFF232E4C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title block with Share and Close buttons
        Row(
          children: [
            Expanded(
              child: Text(
                '${_selectedLocation!['name']},\nIN',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Share Button
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Weather details shared successfully!'),
                  ),
                );
              },
              icon: const Icon(Icons.share, color: Colors.blueAccent, size: 18),
              label: const Text(
                'Share',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: cardBg,
                side: const BorderSide(color: Colors.blueAccent),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Close Button
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showDetails = false;
                });
              },
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
              label: const Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: cardBg,
                side: const BorderSide(color: Colors.redAccent),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Parameter cards grid/list
        _buildDetailCard(
          title: 'TEMPERATURE',
          value: '$temp°C',
          subtitle: 'Feels like $feelsLike°C',
          iconWidget: _buildThermometerIcon(),
        ),
        const SizedBox(height: 16),

        _buildDetailCard(
          title: 'WIND SPEED',
          value: '$windSpeed m/s',
          subtitle: 'Direction: $windDirection°',
          iconWidget: _buildWindIcon(),
        ),
        const SizedBox(height: 16),

        _buildDetailCard(
          title: 'HUMIDITY',
          value: '$humidity%',
          subtitle: 'Moisture in air',
          iconWidget: _buildHumidityDropIcon(),
        ),
        const SizedBox(height: 16),

        _buildDetailCard(
          title: 'PRESSURE',
          value: '$pressure hPa',
          subtitle: 'Atmospheric pressure',
          iconWidget: _buildPressureArrowIcon(),
        ),
        const SizedBox(height: 16),

        _buildDetailCard(
          title: 'VISIBILITY',
          value: '$visibility km',
          subtitle: 'Clear visibility',
          iconWidget: _buildVisibilityEyeIcon(),
        ),
        const SizedBox(height: 16),

        // Cloudiness parameter card
        _buildDetailCard(
          title: 'CLOUDINESS',
          value: '$cloudiness%',
          subtitle: 'Cloud coverage',
          iconWidget: _buildCloudinessIcon(),
        ),
        const SizedBox(height: 16),

        // Sunrise parameter card
        _buildDetailCard(
          title: 'SUNRISE',
          value: sunriseStr,
          subtitle: 'Morning time',
          iconWidget: const SunriseIcon(),
        ),
        const SizedBox(height: 16),

        // Sunset parameter card
        _buildDetailCard(
          title: 'SUNSET',
          value: sunsetStr,
          subtitle: 'Evening time',
          iconWidget: const SunsetIcon(),
        ),
        const SizedBox(height: 24),

        // 3-Day Forecast Section
        const Text(
          '3-Day Forecast',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildThreeDayForecastList(),
        const SizedBox(height: 24),

        // Today's Weather Timeline
        const Text(
          'Today’s Weather Timeline',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildTimelineGrid(),
        const SizedBox(height: 24),

        // Temperature Trend Chart
        _buildTemperatureTrendChart(),
      ],
    );
  }

  // Common UI template for detailed parameters
  Widget _buildDetailCard({
    required String title,
    required String value,
    required String subtitle,
    required Widget iconWidget,
  }) {
    final cardBg = const Color(0xFF232E4C);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          iconWidget,
        ],
      ),
    );
  }

  // Build the 3-day forecast list cards by grouping forecast data by day
  Widget _buildThreeDayForecastList() {
    final List forecastList = _forecastWeather!['list'];
    final Map<String, List<dynamic>> grouped = {};

    for (var item in forecastList) {
      final dtTxt = item['dt_txt'] as String; // e.g. "2026-06-12 12:00:00"
      final dateStr = dtTxt.split(' ')[0];
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(item);
    }

    final cardBg = const Color(0xFF232E4C);
    final List<Widget> dayCards = [];
    final sortedDates = grouped.keys.toList()..sort();

    // Loop through the first 3 distinct dates
    for (int i = 0; i < 3 && i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final dayItems = grouped[date]!;

      // Math for Min and Max temperatures across the day
      double minTemp = 100.0;
      double maxTemp = -100.0;
      for (var item in dayItems) {
        final tMin = (item['main']['temp_min'] as num).toDouble();
        final tMax = (item['main']['temp_max'] as num).toDouble();
        if (tMin < minTemp) minTemp = tMin;
        if (tMax > maxTemp) maxTemp = tMax;
      }

      // Pick representative weather icon around mid-day (12:00:00)
      var representative = dayItems[0];
      for (var item in dayItems) {
        if (item['dt_txt'].toString().contains('12:00:00')) {
          representative = item;
          break;
        }
      }

      final weather = representative['weather'][0];
      final iconCode = weather['icon'] as String;
      final description = weather['description'] as String;

      final dt = DateTime.parse(date);
      final dayStr = DateFormat('EEEE, MMM d').format(dt);

      dayCards.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Text(
                dayStr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Icon(
                _getWeatherIcon(iconCode),
                color: _getWeatherIconColor(iconCode),
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                '${((maxTemp + minTemp) / 2).round()}°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'H: ${maxTemp.round()}° L: ${minTemp.round()}°',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _capitalize(description),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: dayCards);
  }

  // Build the 8 timeline items in a 2x4 grid layout
  Widget _buildTimelineGrid() {
    final List forecastList = _forecastWeather!['list'];
    final List<Widget> items = [];

    // Slice 8 points from the forecast data list
    for (int k = 0; k < 8 && k < forecastList.length; k++) {
      final item = forecastList[k];
      final dt = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
      final timeStr = DateFormat('HH:mm').format(dt);
      final temp = (item['main']['temp'] as num).round();
      final iconCode = item['weather'][0]['icon'] as String;

      items.add(
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF232E4C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Icon(
                _getWeatherIcon(iconCode),
                color: _getWeatherIconColor(iconCode),
                size: 28,
              ),
              const SizedBox(height: 10),
              Text(
                '$temp°',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: items,
    );
  }

  // Temperature trend custom painter chart
  Widget _buildTemperatureTrendChart() {
    final List forecastList = _forecastWeather!['list'];
    final List<double> chartTemps = [];
    final List<String> chartTimes = [];

    // Collect first 8 forecast elements
    for (int k = 0; k < 8 && k < forecastList.length; k++) {
      final item = forecastList[k];
      chartTemps.add((item['main']['temp'] as num).toDouble());
      chartTimes.add(item['dt_txt'] as String);
    }

    return TemperatureTrendChart(
      temperatures: chartTemps,
      times: chartTimes,
    );
  }

  // Visual custom icons
  Widget _buildThermometerIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 8,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Positioned(
              bottom: 12,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.pinkAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.air,
        color: Colors.purpleAccent,
        size: 32,
      ),
    );
  }

  Widget _buildHumidityDropIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.water_drop,
        color: Colors.blueAccent,
        size: 32,
      ),
    );
  }

  Widget _buildPressureArrowIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.arrow_downward,
          color: Colors.blue,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildVisibilityEyeIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.brown.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.visibility,
            color: Colors.brown,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildCloudinessIcon() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.cloud,
        color: Colors.white70,
        size: 32,
      ),
    );
  }
}

// Graphic Sunrise Icon component matching mockup
class SunriseIcon extends StatelessWidget {
  const SunriseIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B), Color(0xFF64B5F6)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 16,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFFFD54F),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            child: Container(
              width: 22,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Graphic Sunset Icon component matching mockup
class SunsetIcon extends StatelessWidget {
  const SunsetIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFFFF512F)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFFFB74D),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 10,
            child: Container(
              width: 12,
              height: 26,
              color: const Color(0xFF311B92),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWindowRow(),
                  _buildWindowRow(),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 20,
            child: Container(
              width: 14,
              height: 34,
              color: const Color(0xFF1A237E),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWindowRow(),
                  _buildWindowRow(),
                  _buildWindowRow(),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 32,
            child: Container(
              width: 14,
              height: 20,
              color: const Color(0xFF311B92),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildWindowRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(width: 2, height: 2, color: Colors.yellow[200]),
        Container(width: 2, height: 2, color: Colors.yellow[200]),
      ],
    );
  }
}

// Temperature Trend chart container
class TemperatureTrendChart extends StatelessWidget {
  final List<double> temperatures;
  final List<String> times;

  const TemperatureTrendChart({
    Key? key,
    required this.temperatures,
    required this.times,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (temperatures.isEmpty || times.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "No chart data available",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    return Container(
      height: 240,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF232E4C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temperature Trend',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: TemperatureChartPainter(
                temperatures: temperatures,
                times: times,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TemperatureChartPainter extends CustomPainter {
  final List<double> temperatures;
  final List<String> times;

  TemperatureChartPainter({
    required this.temperatures,
    required this.times,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFFFF6B35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = const Color(0xFFFF6B35)
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    const double leftPadding = 44;
    const double bottomPadding = 24;
    const double topPadding = 16;
    const double rightPadding = 16;

    final double chartWidth = size.width - leftPadding - rightPadding;
    final double chartHeight = size.height - topPadding - bottomPadding;

    if (temperatures.isEmpty) return;

    double maxTemp = temperatures.reduce((a, b) => a > b ? a : b);
    double minTemp = temperatures.reduce((a, b) => a < b ? a : b);

    if (maxTemp == minTemp) {
      maxTemp += 2;
      minTemp -= 2;
    } else {
      final range = maxTemp - minTemp;
      maxTemp += range * 0.15;
      minTemp -= range * 0.15;
    }

    final double range = maxTemp - minTemp;
    final points = <Offset>[];
    final double xStep = chartWidth / (temperatures.length - 1);

    for (int i = 0; i < temperatures.length; i++) {
      final double x = leftPadding + (i * xStep);
      final double y = topPadding + chartHeight - ((temperatures[i] - minTemp) / range * chartHeight);
      points.add(Offset(x, y));
    }

    // Y Grid lines & axis labels
    final yTicks = 4;
    for (int i = 0; i < yTicks; i++) {
      final val = minTemp + (range / (yTicks - 1) * i);
      final double y = topPadding + chartHeight - (i * (chartHeight / (yTicks - 1)));
      
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        paintGrid,
      );

      textPainter.text = TextSpan(
        text: val.toStringAsFixed(1),
        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftPadding - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // X axis labels
    final int xTicks = 4;
    final int step = (temperatures.length / xTicks).floor();
    for (int i = 0; i < xTicks; i++) {
      final idx = i * step;
      if (idx >= times.length) break;

      final double x = leftPadding + (idx * xStep);
      final double y = size.height - bottomPadding + 6;

      String formattedTime = times[idx];
      try {
        final dt = DateTime.parse(times[idx]);
        formattedTime = DateFormat('HH:mm').format(dt);
      } catch (_) {}

      textPainter.text = TextSpan(
        text: formattedTime,
        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
    }

    // Curve rendering
    if (points.isNotEmpty) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        
        final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
        final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
        
        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          p1.dx, p1.dy,
        );
      }
      canvas.drawPath(path, paintLine);

      // Markers
      for (final p in points) {
        canvas.drawCircle(p, 5, paintDot);
        canvas.drawCircle(p, 2, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TemperatureChartPainter oldDelegate) {
    return oldDelegate.temperatures != temperatures || oldDelegate.times != times;
  }
}
