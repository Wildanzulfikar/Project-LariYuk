import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RunningTrackPage extends StatefulWidget {
  const RunningTrackPage({super.key});

  @override
  State<RunningTrackPage> createState() => _RunningTrackPageState();
}

class _RunningTrackPageState extends State<RunningTrackPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<Position>? _positionStreamSubscription;
  List<latlng.LatLng> _trackedRoute = [];
  List<latlng.LatLng> _animatedRoute = [];
  Timer? _animationTimer;
  int _animatedIndex = 0;
  bool _isTracking = false;
  bool _isPaused = false;
  double _totalDistance = 0.0;
  DateTime _startTime = DateTime.now();
  Timer? _timer;
  int _elapsedSeconds = 0;
  final List<Polyline> _polylines = [];
  late MapController _mapController;

  latlng.LatLng? _initialPosition;
  bool _isMapReady = false;

  String? get _currentUserId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _checkLocationPermission().then((_) => _setInitialLocation());
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _timer?.cancel();
    _animationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied forever')),
      );
    }
  }

  Future<void> _setInitialLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _initialPosition = latlng.LatLng(pos.latitude, pos.longitude);
        _isMapReady = true;
      });
    } catch (e) {
      debugPrint("Gagal dapat lokasi awal: $e");
    }
  }

  void _startTracking() async {
    if (_isTracking) return;

    _isTracking = true;
    _isPaused = false;
    _startTime = DateTime.now();

    _trackedRoute.clear();
    _animatedRoute.clear();
    _animatedIndex = 0;
    _totalDistance = 0.0;
    _elapsedSeconds = 0;
    _polylines.clear();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!_isPaused) {
        final latLng = latlng.LatLng(position.latitude, position.longitude);
        setState(() {
          _trackedRoute.add(latLng);
          if (_trackedRoute.length > 1) {
            _totalDistance += Geolocator.distanceBetween(
              _trackedRoute[_trackedRoute.length - 2].latitude,
              _trackedRoute[_trackedRoute.length - 2].longitude,
              latLng.latitude,
              latLng.longitude,
            );
          }
          _startPolylineAnimation();
          _mapController.move(latLng, 16.0);
        });
      }
    });
  }

  void _startPolylineAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_animatedIndex < _trackedRoute.length) {
        setState(() {
          _animatedRoute.add(_trackedRoute[_animatedIndex]);
          _animatedIndex++;
          _updateAnimatedPolyline();
        });
      } else {
        _animationTimer?.cancel();
      }
    });
  }

  void _updateAnimatedPolyline() {
    _polylines.clear();
    _polylines.add(
      Polyline(points: _trackedRoute, strokeWidth: 2.0, color: Colors.grey),
    );
    _polylines.add(
      Polyline(points: _animatedRoute, strokeWidth: 5.0, color: Colors.blue),
    );
  }

  void _pauseTracking() {
    if (_isTracking && !_isPaused) {
      _isPaused = true;
      _positionStreamSubscription?.pause();
      _animationTimer?.cancel();
      setState(() {});
    }
  }

  void _resumeTracking() {
    if (_isTracking && _isPaused) {
      _isPaused = false;
      _positionStreamSubscription?.resume();
      _startPolylineAnimation();
      setState(() {});
    }
  }

  void _stopTracking() async {
    if (!_isTracking) return;

    _positionStreamSubscription?.cancel();
    _timer?.cancel();
    _animationTimer?.cancel();
    _isTracking = false;
    _isPaused = false;

    if (_totalDistance < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jarak terlalu pendek untuk disimpan.')),
      );
      _positionStreamSubscription?.pause();
      _animationTimer?.cancel();
      _isPaused = true;

      setState(() {});
      return;
    }

    final duration = _elapsedSeconds;
    final calories = _calculateCalories(_totalDistance / 1000, duration);
    final steps = _estimateSteps(_totalDistance / 1000);

    if (_currentUserId != null) {
      await _db.collection('users').doc(_currentUserId).collection('running_history').add({
        'date': Timestamp.fromDate(DateTime.now().toUtc().add(const Duration(hours: 7))),
        'distance': _totalDistance / 1000,
        'duration': duration / 60,
        'calories': calories,
        'steps': steps,
        'status': 'completed',
        'pace': duration / 60 / (_totalDistance / 1000),
      });

      await _db.collection('users').doc(_currentUserId).update({
        'totalRuns': FieldValue.increment(1),
        'totalDistance': FieldValue.increment(_totalDistance / 1000),
      });
    }
    setState(() {});
  }

  int _calculateCalories(double distanceKm, int durationSeconds) {
    const double caloriesPerKm = 50.0;
    return (distanceKm * caloriesPerKm).round();
  }

  int _estimateSteps(double distanceKm) {
    return (distanceKm * 1000).round();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }

  String _formatPace(int seconds, double distanceKm) {
    if (distanceKm <= 0) return '0:00';
    final paceSec = seconds / distanceKm;
    final min = paceSec ~/ 60;
    final sec = (paceSec % 60).toInt();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, '/dashboard');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Running Tracker'),
          backgroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Expanded(
              child: _isMapReady
                  ? FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _initialPosition!,
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.lari_yuk',
                        ),
                        PolylineLayer(polylines: _polylines),
                        MarkerLayer(
                          markers: [
                            if (_animatedRoute.isNotEmpty)
                              Marker(
                                point: _animatedRoute.last,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 30),
                              ),
                          ],
                        ),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _isTracking
                    ? [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatBox('Duration', _formatDuration(_elapsedSeconds)),
                            _buildStatBox('Distance', '${(_totalDistance / 1000).toStringAsFixed(1)} KM'),
                            _buildStatBox('Pace', _formatPace(_elapsedSeconds, _totalDistance / 1000)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _isPaused ? _resumeTracking : _pauseTracking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                minimumSize: const Size(100, 50),
                              ),
                              child: Text(_isPaused ? 'Resume' : 'Pause'),
                            ),
                            ElevatedButton(
                              onPressed: _stopTracking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                minimumSize: const Size(100, 50),
                              ),
                              child: const Text('Stop'),
                            ),
                          ],
                        ),
                      ]
                    : [
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _startTracking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(200, 50),
                          ),
                          child: const Text('Start'),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}