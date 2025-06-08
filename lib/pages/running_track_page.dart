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
  bool _isTracking = false;
  bool _isPaused = false;
  double _totalDistance = 0.0;
  DateTime _startTime = DateTime.now();
  late Timer _timer;
  int _elapsedSeconds = 0;
  final List<Polyline> _polylines = [];
  late MapController _mapController;

  String? get _currentUserId {
    final user = _auth.currentUser;
    return user?.uid;
  }

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _timer.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
        }
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied forever')),
        );
      }
      return;
    }
  }

  void _startTracking() async {
    if (_isTracking) return;

    _isTracking = true;
    _isPaused = false;
    _startTime = DateTime.now();
    _trackedRoute.clear();
    _totalDistance = 0.0;
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (mounted && !_isPaused) {
        setState(() {
          final latLng = latlng.LatLng(position.latitude, position.longitude);
          _trackedRoute.add(latLng);
          if (_trackedRoute.length > 1) {
            _totalDistance += Geolocator.distanceBetween(
              _trackedRoute[_trackedRoute.length - 2].latitude,
              _trackedRoute[_trackedRoute.length - 2].longitude,
              latLng.latitude,
              latLng.longitude,
            );
          }
          _updatePolyline();
          _mapController.move(latLng, 16.0); // Zoom level 16
        });
      }
    });
  }

  void _pauseTracking() {
    if (_isTracking && !_isPaused) {
      _isPaused = true;
      _positionStreamSubscription?.pause();
      setState(() {});
    }
  }

  void _resumeTracking() {
    if (_isTracking && _isPaused) {
      _isPaused = false;
      _positionStreamSubscription?.resume();
      setState(() {});
    }
  }

  void _stopTracking() async {
    if (!_isTracking) return;

    _positionStreamSubscription?.cancel();
    _timer.cancel();
    _isTracking = false;
    _isPaused = false;

    final duration = _elapsedSeconds;
    final calories = _calculateCalories(_totalDistance, duration);
    final steps = _estimateSteps(_totalDistance);

    if (_currentUserId != null) {
      await _db
          .collection('users')
          .doc(_currentUserId)
          .collection('running_history')
          .add({
            'date': Timestamp.fromDate(
              DateTime.now().toUtc().add(const Duration(hours: 7)),
            ), // WIB
            'distance': _totalDistance / 1000, // Convert to kilometers
            'duration': duration / 60, // Convert to minutes
            'calories': calories,
            'steps': steps,
            'status': 'completed',
            'pace':
                duration /
                60 /
                (_totalDistance / 1000), // Minutes per kilometer
          });

      await _db.collection('users').doc(_currentUserId).update({
        'totalRuns': FieldValue.increment(1),
        'totalDistance': FieldValue.increment(_totalDistance / 1000),
      });
    }
    setState(() {});
  }

  void _updatePolyline() {
    _polylines.clear();
    _polylines.add(
      Polyline(points: _trackedRoute, strokeWidth: 5.0, color: Colors.blue),
    );
  }

  int _calculateCalories(double distanceKm, int durationSeconds) {
    const double caloriesPerKm = 50.0; // Approx for 65kg person
    return (distanceKm * caloriesPerKm).round();
  }

  int _estimateSteps(double distanceKm) {
    return (distanceKm * 1000).round(); // Approx 1000 steps per kilometer
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatPace(int seconds, double distanceKm) {
    if (distanceKm <= 0) return '0:00';
    final paceSecondsPerKm = seconds / (distanceKm / 1000);
    final paceMinutes = paceSecondsPerKm ~/ 60;
    final paceRemainingSeconds = paceSecondsPerKm % 60;
    return '${paceMinutes.toString().padLeft(2, '0')}:${paceRemainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to DashboardScreen when back button is pressed
        Navigator.pushReplacementNamed(context, '/dashboard');
        return false; // Prevent default back navigation
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Running Tracker'),
          backgroundColor: Colors.orange,
        ),
        body: Column(
          children: [
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const latlng.LatLng(0, 0), // Default center
                  initialZoom: 14.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // Updated to avoid subdomains warning
                  ),
                  PolylineLayer(polylines: _polylines),
                  MarkerLayer(
                    markers: [
                      if (_trackedRoute.isNotEmpty)
                        Marker(
                          point: _trackedRoute.last,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 30,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children:
                    _isTracking
                        ? [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatBox(
                                'Duration',
                                _formatDuration(_elapsedSeconds),
                              ),
                              _buildStatBox(
                                'Distance',
                                '${(_totalDistance / 1000).toStringAsFixed(1)} KM',
                              ),
                              _buildStatBox(
                                'Pace',
                                _formatPace(
                                      _elapsedSeconds,
                                      _totalDistance / 1000,
                                    ) +
                                    ' -rata',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed:
                                    _isPaused
                                        ? _resumeTracking
                                        : _pauseTracking,
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
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
