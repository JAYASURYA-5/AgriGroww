import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {

  const WeatherCard({
    Key? key,
    required this.location,
    required this.temperature,
    required this.condition,
    this.noRain = false,
    this.showDetails = false,
    this.humidity = '',
    this.windSpeed = '',
  }) : super(key: key);
  final String location;
  final String temperature;
  final String condition;
  final bool noRain;
  final bool showDetails;
  final String humidity;
  final String windSpeed;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Weather',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (showDetails)
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF22C55E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              text: temperature,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF4444),
              ),
              children: const [
                TextSpan(
                  text: '°C',
                  style: TextStyle(
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            condition,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[400], size: 18),
              const SizedBox(width: 4),
              const Text(
                'No rain expected',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          if (showDetails) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Icon(Icons.opacity, color: Colors.blue[300], size: 24),
                    const SizedBox(height: 4),
                    Text(
                      'Humidity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      humidity,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Icon(Icons.air, color: Colors.blue[300], size: 24),
                    const SizedBox(height: 4),
                    Text(
                      'Wind Speed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      windSpeed,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
}
