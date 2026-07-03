import 'package:flutter/material.dart';

class EnvironmentScreen extends StatefulWidget {
  final bool hideBackButton;
  const EnvironmentScreen({
    Key? key,
    this.hideBackButton = false,
  }) : super(key: key);

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  // Comfort Ranges Data
  final List<Map<String, dynamic>> _comfortRanges = [
    {
      "animal": "Cattle",
      "tempMin": 5,
      "tempMax": 25,
      "humidityMin": 40,
      "humidityMax": 80,
    },
    {
      "animal": "Goat",
      "tempMin": 10,
      "tempMax": 30,
      "humidityMin": 50,
      "humidityMax": 70,
    },
    {
      "animal": "Sheep",
      "tempMin": 5,
      "tempMax": 25,
      "humidityMin": 50,
      "humidityMax": 70,
    },
    {
      "animal": "Chicken",
      "tempMin": 18,
      "tempMax": 28,
      "humidityMin": 50,
      "humidityMax": 75,
    },
    {
      "animal": "Pig",
      "tempMin": 15,
      "tempMax": 25,
      "humidityMin": 50,
      "humidityMax": 70,
    },
    {
      "animal": "Horse",
      "tempMin": 5,
      "tempMax": 25,
      "humidityMin": 45,
      "humidityMax": 75,
    },
  ];

  // Weather-Based Care Tips Data
  final List<String> _careTips = [
    "Maintain regular feeding schedule",
    "Ensure clean water is always available",
    "Continue routine health monitoring",
    "Keep shelters clean and well-ventilated",
    "Allow adequate outdoor time for exercise",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Environment',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: widget.hideBackButton
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF22C55E)),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title and Logo Header Card
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEAF8F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.thermostat_outlined,
                          color: Color(0xFF22C55E),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Environment',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                                fontFamily: 'serif',
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Monitor pasture conditions and barn comfort',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Safe Ranges Card
                  _buildSafeRangesCard(),
                  const SizedBox(height: 24),

                  // Weather-Based Care Tips Card
                  _buildCareTipsCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafeRangesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.info_outline, color: Color(0xFF22C55E), size: 20),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Safe Ranges by Animal Type',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF132F23),
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grid of 6 animals (Fixed 2 columns grid to match mockup)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85, // Perfect height-to-width ratio for vertical layout
            ),
            itemCount: _comfortRanges.length,
            itemBuilder: (context, index) {
              final range = _comfortRanges[index];
              return _buildAnimalComfortTile(range);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalComfortTile(Map<String, dynamic> range) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            range["animal"],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          // Temp row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: SlantedThermometer(size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Temp: ${range["tempMin"]}-${range["tempMax"]}°C",
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Humidity row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: DropletIcon(size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Humidity: ${range["humidityMin"]}-${range["humidityMax"]}%",
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCareTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: const [
              Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 22),
              SizedBox(width: 8),
              Text(
                'Weather-Based Care Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tips List (Single column listing on mobile viewport constraints)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _careTips.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCareTipTile((index + 1).toString(), _careTips[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCareTipTile(String number, String tipText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF8F2),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF22C55E),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tipText,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Custom Painters for high fidelity visuals
// ----------------------------------------------------------------------------

class SlantedThermometerPainter extends CustomPainter {
  const SlantedThermometerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Center coordinates for bulb and tip
    final double bx = w * 0.32;
    final double by = h * 0.68;
    final double tx = w * 0.72;
    final double ty = h * 0.28;

    // Draw grey outline backplate
    final outlinePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22 + 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(bx, by), Offset(tx, ty), outlinePaint);
    canvas.drawCircle(Offset(bx, by), w * 0.26, outlinePaint..style = PaintingStyle.fill);

    // Draw white background core inside outline
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(bx, by), Offset(tx, ty), whitePaint);
    canvas.drawCircle(Offset(bx, by), w * 0.22, whitePaint..style = PaintingStyle.fill);

    // Draw pink/red liquid reservoir
    final liquidPaint = Paint()
      ..color = const Color(0xFFEC4899)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(bx, by), w * 0.15, liquidPaint);

    // Draw pink/red liquid tube (partially filled to 70% level)
    final liquidTubePaint = Paint()
      ..color = const Color(0xFFEC4899)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.11
      ..strokeCap = StrokeCap.round;
    
    final double fillPct = 0.68;
    final double lx = bx + (tx - bx) * fillPct;
    final double ly = by + (ty - by) * fillPct;
    canvas.drawLine(Offset(bx, by), Offset(lx, ly), liquidTubePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SlantedThermometer extends StatelessWidget {
  final double size;
  const SlantedThermometer({Key? key, this.size = 18}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const SlantedThermometerPainter(),
      ),
    );
  }
}

class DropletPainter extends CustomPainter {
  const DropletPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Paint for the droplet gradient
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF60A5FA), // Light Blue
          Color(0xFF3B82F6), // Vibrant Blue
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path = Path();
    // Start at top tip
    path.moveTo(w * 0.5, h * 0.12);
    // Right side curve down to bottom
    path.cubicTo(
      w * 0.85,
      h * 0.45,
      w * 0.9,
      h * 0.74,
      w * 0.5,
      h * 0.92,
    );
    // Left side curve back to top tip
    path.cubicTo(
      w * 0.1,
      h * 0.74,
      w * 0.15,
      h * 0.45,
      w * 0.5,
      h * 0.12,
    );
    path.close();
    canvas.drawPath(path, paint);

    // Light reflection highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round;

    final highlightPath = Path();
    highlightPath.moveTo(w * 0.32, h * 0.60);
    highlightPath.quadraticBezierTo(
      w * 0.26,
      h * 0.72,
      w * 0.38,
      h * 0.80,
    );
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DropletIcon extends StatelessWidget {
  final double size;
  const DropletIcon({Key? key, this.size = 18}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: const DropletPainter(),
      ),
    );
  }
}
