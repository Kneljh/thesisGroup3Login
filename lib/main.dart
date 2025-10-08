import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:flutter/services.dart';
import 'splash_screen.dart';

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: SplashScreen()));
}

// --------- Recommendation Model ---------
class GasRecommendation {
  final String title;
  final String status;
  final List<String> details;

  GasRecommendation({
    required this.title,
    required this.status,
    required this.details,
  });
}

// --------- Helper for sensor status ---------
class SensorData {
  static String getStatusIcon(double value, String type) {
    if (type == "CO2") {
      if (value > 3000) return '❌';
      if (value > 2000) return '⚠️';
      return '✅';
    } else {
      if (value > 25) return '❌';
      if (value > 10) return '⚠️';
      return '✅';
    }
  }
}

// --------- Main Screen ---------
class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [HomeScreen(), Center(child: Text("History Page"))];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      resizeToAvoidBottomInset: false,
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
        selectedItemColor: Color(0xFF0BBEDE),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

// --------- Home Screen ---------
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? selectedOption;
  String? selectedRecommendation;
  double displayValue = 0.0;

  bool isAirDropdownOpen = false;
  bool isRecommendationDropdownOpen = false;

  Timer? timer;
  double co2Level = 0.0;
  double ammoniaLevel = 0.0;

  final String espIPco2 = 'http://10.86.0.40';
  final String espIPammonia = 'http://10.86.0.16';

  final List<GasRecommendation> recommendations = [
    GasRecommendation(
      title: 'NH3: 0–10 ppm',
      status: '✅ Optimal',
      details: [
        'Maintain current ventilation and litter management practices.',
        'Continue regular monitoring to ensure levels remain low.',
      ],
    ),
    GasRecommendation(
      title: 'NH3: 11–25 ppm',
      status: '⚠️ Moderate',
      details: [
        'Enhance ventilation to reduce NH₃ accumulation.',
        'Inspect and repair any water leaks to prevent litter dampness.',
        'Consider using litter amendments to bind ammonia.',
      ],
    ),
    GasRecommendation(
      title: 'NH3: >25 ppm',
      status: '❌ High',
      details: [
        'Implement immediate ventilation improvements.',
        'Remove and replace wet or soiled litter.',
        'Evaluate and adjust stocking density if necessary.',
      ],
    ),
    GasRecommendation(
      title: 'CO₂: 0–2000 ppm',
      status: '✅ Optimal',
      details: [
        'Maintain current ventilation systems.',
        'Continue routine monitoring of CO₂ levels.',
      ],
    ),
    GasRecommendation(
      title: 'CO₂: 2001–3000 ppm',
      status: '⚠️ Moderate',
      details: [
        'Increase ventilation rates to enhance air exchange.',
        'Check for and address any sources of CO₂ accumulation.',
      ],
    ),
    GasRecommendation(
      title: 'CO₂: >3000 ppm',
      status: '❌ High',
      details: [
        'Implement immediate ventilation improvements.',
        'Inspect and service heating systems to ensure proper combustion.',
        'Reduce stocking density if overcrowding is contributing.',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // ✅ Keep system UI visible
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    timer = Timer.periodic(const Duration(seconds: 3), (_) => fetchData());
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    timer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final co2Response = await http.get(Uri.parse('$espIPco2/readings'));
      final nh3Response = await http.get(Uri.parse('$espIPammonia/readings'));

      if (co2Response.statusCode == 200 && nh3Response.statusCode == 200) {
        final co2Data = jsonDecode(co2Response.body);
        final nh3Data = jsonDecode(nh3Response.body);

        setState(() {
          co2Level = (co2Data['co2'] ?? 0).toDouble();
          ammoniaLevel = (nh3Data['ammonia'] ?? 0).toDouble();

          if (selectedOption == "Carbon Dioxide") displayValue = co2Level;
          if (selectedOption == "Ammonia") displayValue = ammoniaLevel;
        });
      }
    } catch (e) {
      print("Fetch failed: $e");
    }
  }

  double _normalizeCO2(double ppm) => ppm.clamp(0, 4000) / 4000;
  double _normalizeAmmonia(double ppm) => ppm.clamp(0, 50) / 50;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ Background combination
        Column(
          children: [
            ClipRect(
              child: Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 0.5,
                child: Image.asset(
                  'assets/splashscreen.jpg',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Image.asset(
                'assets/plainbg.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),

        // ✅ Foreground content
        Positioned.fill(
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 300),
                  _buildAirQualityDropdown(),
                  const SizedBox(height: 20),
                  if (isAirDropdownOpen && selectedOption != null)
                    _buildCircularIndicator(),
                  const SizedBox(height: 40),
                  _buildRecommendationsDropdown(),
                  const SizedBox(height: 20),
                  if (isRecommendationDropdownOpen &&
                      selectedRecommendation != null)
                    _buildRecommendationDetails(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ======= Helper Widgets =======
  Widget _buildAirQualityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: _boxDecoration(const Color(0xFF60B574)),
      child: DropdownButton<String>(
        value: selectedOption,
        isExpanded: true,
        hint: const Text(
          "Air Quality",
          style: TextStyle(color: Color(0xFF60B574), fontSize: 18),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF60B574)),
        underline: const SizedBox(),
        items: [
          DropdownMenuItem(
            value: 'Carbon Dioxide',
            child: Text(
              'Carbon Dioxide ${SensorData.getStatusIcon(co2Level, "CO2")}',
            ),
          ),
          DropdownMenuItem(
            value: 'Ammonia',
            child: Text(
              'Ammonia ${SensorData.getStatusIcon(ammoniaLevel, "NH3")}',
            ),
          ),
        ],
        onChanged: (value) {
          setState(() {
            selectedOption = value;
            displayValue =
                (value == "Carbon Dioxide") ? co2Level : ammoniaLevel;
            isAirDropdownOpen = true;
            isRecommendationDropdownOpen = false;
            selectedRecommendation = null;
          });
        },
      ),
    );
  }

  Widget _buildCircularIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(const Color(0xFF60B574)),
      child: CircularPercentIndicator(
        radius: 120.0,
        lineWidth: 15.0,
        percent:
            (selectedOption == "Carbon Dioxide")
                ? _normalizeCO2(displayValue)
                : _normalizeAmmonia(displayValue),
        center: Text(
          "$selectedOption\n${displayValue.toStringAsFixed(selectedOption == "Carbon Dioxide" ? 0 : 1)} ppm",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22.0,
            color: Color(0xFF60B574),
          ),
        ),
        circularStrokeCap: CircularStrokeCap.round,
        progressColor:
            (selectedOption == "Carbon Dioxide")
                ? const Color(0xFF0BBEDE)
                : Colors.red,
        backgroundColor:
            (selectedOption == "Carbon Dioxide")
                ? const Color(0xFFB0E0F5)
                : const Color(0xFFF5B0B0),
      ),
    );
  }

  Widget _buildRecommendationsDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: _boxDecoration(const Color(0xFF0BBEDE)),
      child: DropdownButton<String>(
        value: selectedRecommendation,
        isExpanded: true,
        hint: const Text(
          "Recommendations",
          style: TextStyle(color: Color(0xFF0BBEDE), fontSize: 18),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0BBEDE)),
        underline: const SizedBox(),
        items:
            recommendations
                .map(
                  (rec) => DropdownMenuItem<String>(
                    value: rec.title,
                    child: Text('${rec.title} – ${rec.status}'),
                  ),
                )
                .toList(),
        onChanged: (value) {
          setState(() {
            selectedRecommendation = value;
            isRecommendationDropdownOpen = true;
            isAirDropdownOpen = false;
            selectedOption = null;
          });
        },
      ),
    );
  }

  Widget _buildRecommendationDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 30),
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(const Color(0xFF0BBEDE)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            recommendations
                .firstWhere((rec) => rec.title == selectedRecommendation)
                .details
                .map(
                  (detail) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(detail),
                  ),
                )
                .toList(),
      ),
    );
  }

  BoxDecoration _boxDecoration(Color borderColor) {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: borderColor, width: 1.5),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
