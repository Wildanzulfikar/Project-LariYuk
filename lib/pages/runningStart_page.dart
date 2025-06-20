import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lari_yuk/main_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class RunningStartPage extends StatefulWidget {
  const RunningStartPage({Key? key}) : super(key: key);

  @override
  State<RunningStartPage> createState() => _RunningStartPageState();
}

class _RunningStartPageState extends State<RunningStartPage> {
  LatLng? _currentLocation;
  double _range = 3.0;
  bool _isRunning = false;
  bool _isPaused = false; // <-- Add this

  // Stats
  Duration _duration = Duration.zero;
  double _distance = 0.0;
  int _temperature = 0;
  Timer? _timer;

  List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  void _startRun() {
    setState(() {
      _isRunning = true;
      _duration = Duration.zero;
      _distance = 0.0;
      _routePoints.clear();
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _duration += Duration(seconds: 1);
      });
    });
    _startTracking();
    _fetchTemperature();
  }

  void _pauseRun() {
    _timer?.cancel();
    _positionStream?.pause();
    setState(() {
      _isPaused = true;
    });
  }

  void _continueRun() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _duration += Duration(seconds: 1);
      });
    });
    _positionStream?.resume();
    setState(() {
      _isPaused = false;
    });
  }

  void _stopRun() {
    _timer?.cancel();
    _positionStream?.cancel();

    final duration = _duration;
    final distance = _distance;
    final pace = _pace;
    final temperature = _temperature;

    setState(() {
      _isRunning = false;
      _isPaused = false;
      _duration = Duration.zero;
      _distance = 0.0;
      _routePoints.clear();
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AfterRunPage(
          duration: duration,
          distance: distance,
          pace: pace,
          temperature: temperature,
        ),
      ),
    );
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    _fetchTemperature();
  }

  void _startTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      final newPoint = LatLng(position.latitude, position.longitude);
      setState(() {
        if (_routePoints.isNotEmpty) {
          final last = _routePoints.last;
          _distance += Distance().as(LengthUnit.Kilometer, last, newPoint);
        }
        _routePoints.add(newPoint);
        _currentLocation = newPoint;
      });
    });
  }

  Future<void> _fetchTemperature() async {
    if (_currentLocation == null) return;
    final lat = _currentLocation!.latitude;
    final lon = _currentLocation!.longitude;
    final url =
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final temp = data['current_weather']?['temperature'];
      if (temp != null) {
        setState(() {
          _temperature = temp.round();
        });
      }
    }
  }

  String get _pace {
    if (_distance == 0) return "0:00";
    final paceSec = _duration.inSeconds / _distance;
    final paceMin = (paceSec / 60).floor();
    final paceRemSec = (paceSec % 60).round().toString().padLeft(2, '0');
    return "$paceMin:$paceRemSec";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Leaflet Map
          Positioned.fill(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _currentLocation ?? LatLng(-6.200000, 106.816666),
                initialZoom: 16.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.app',
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: Color(0xFFD76B1C),
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                if (_currentLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 40,
                        height: 40,
                        point: _currentLocation!,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withOpacity(0.5),
                          ),
                          child: const Icon(Icons.my_location, color: Colors.blue, size: 32),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 56,
              color: Color(0xFFD76B1C),
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                child: Text(
                  'LARIYUKK',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          // If not running, show range selector and Start button
          if (!_isRunning) ...[
            // Range Selector
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Form(
                        child: Column(
                          children: [
                            TextFormField(
                              initialValue: _range.toStringAsFixed(1),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Set Your Range (KM)',
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: Colors.black.withOpacity(0.7),
                                  fontSize: 15,
                                ),
                                border: UnderlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                              ),
                              onChanged: (value) {
                                final parsed = double.tryParse(value);
                                if (parsed != null && parsed >= 1 && parsed <= 10) {
                                  setState(() {
                                    _range = parsed;
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: _range,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: _range.toStringAsFixed(1),
                              activeColor: Color(0xFFD76B1C),
                              onChanged: (value) {
                                setState(() {
                                  _range = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Start Button
            Positioned(
              left: 0,
              right: 0,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _startRun,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFD76B1C), Color(0xFF7B4397)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: Text(
                          'Start',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ] else ...[
            // Running stats UI (moved closer to Pause/Stop buttons)
            Positioned(
              left: 0,
              right: 0,
              bottom: 100 + MediaQuery.of(context).padding.bottom,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statBox('Duration', _formatDuration(_duration)),
                      const SizedBox(width: 16),
                      _statBox('Distance (KM)', _distance.toStringAsFixed(2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statBox('Pace Rata-rata', _pace),
                      const SizedBox(width: 16),
                      _statBox('suhu', '$_temperature°'),
                    ],
                  ),
                ],
              ),
            ),
            // Pause/Continue and Stop buttons
            Positioned(
              left: 0,
              right: 0,
              bottom: 24 + MediaQuery.of(context).padding.bottom,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isPaused ? _continueRun : _pauseRun,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD76B1C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isPaused ? 'Continue' : 'Pause',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _stopRun,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD76B1C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Stop',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      width: 120,
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Color(0xFFD76B1C).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return h == "00" ? "$m:$s" : "$h:$m:$s";
  }
}

class AfterRunPage extends StatefulWidget {
  final Duration duration;
  final double distance;
  final String pace;
  final int temperature;

  const AfterRunPage({
    Key? key,
    required this.duration,
    required this.distance,
    required this.pace,
    required this.temperature,
  }) : super(key: key);

  @override
  State<AfterRunPage> createState() => _AfterRunPageState();
}

class _AfterRunPageState extends State<AfterRunPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(d.inHours);
    final m = twoDigits(d.inMinutes.remainder(60));
    final s = twoDigits(d.inSeconds.remainder(60));
    return h == "00" ? "$m:$s" : "$h:$m:$s";
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: -24).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E6),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Floating Medal Animation
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: child,
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Medal shadow
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFFFFE082),
                            Color(0xFFFFD36B),
                            Color(0x00FFD36B),
                          ],
                          stops: [0.4, 0.8, 1.0],
                        ),
                      ),
                    ),
                    // Medal main
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Color(0xFFFFD36B),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFFD36B).withOpacity(0.5),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.emoji_events,
                          color: Color(0xFFFFB300),
                          size: 48,
                        ),
                      ),
                    ),
                    // Ribbon
                    Positioned(
                      bottom: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 18,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(0xFF7B4397),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                                bottomRight: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 18,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(0xFF7B4397),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(4),
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Congratulations!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222B45),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'You have completed your run! Great job, keep going!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              // Statistics (no card, just floating)
              _statRow(
                icon: Icons.timer,
                label: 'Duration',
                value: _formatDuration(widget.duration),
              ),
              _statRow(
                icon: Icons.directions_run,
                label: 'Distance (KM)',
                value: widget.distance.toStringAsFixed(2),
              ),
              _statRow(
                icon: Icons.speed,
                label: 'Pace',
                value: widget.pace,
              ),
              _statRow(
                icon: Icons.thermostat,
                label: 'Temperature',
                value: '${widget.temperature}°',
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => MainScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A4D),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 4,
                      shadowColor: Colors.orangeAccent.withOpacity(0.3),
                    ),
                    child: Text(
                      'Back to Dashboard',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
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

  Widget _statRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFFFB300), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7B4397),
            ),
          ),
        ],
      ),
    );
  }
}