import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lari_yuk/pages/notification_page.dart';
import 'package:lari_yuk/services/firestore_service.dart';
import 'package:lari_yuk/pages/ProfilePage.dart'; // Import ProfilePage


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int currentIndex = 0;

  String weatherDescription = '';
  double temperature = 0;
  String weatherLocation = 'Loading...';
  bool isLoading = true;
  String userName = 'Loading...';
  String? profileImageUrl;
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? todayRunData;

  @override
  void initState() {
    super.initState();
    _getUserName();
    fetchWeather();
    _fetchTodayRunData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    print("USERLOGIN: ${user}");
    if (user != null) {
      setState(() {
        userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
        profileImageUrl = user.photoURL;
      });
    }
  }

  Future<void> _fetchTodayRunData() async {
    setState(() => isLoading = true);
    try {
      todayRunData = await _firestoreService.getTodayRunningData();
      print("RUNNING DATA: $todayRunData");
    } catch (e) {
      print('Error fetching today\'s run data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching run data: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Ambil Lokasi Terkini
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        weatherDescription = 'Layanan Lokasi Diaktifkan!';
        isLoading = false;
      });
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          weatherDescription = 'Izin lokasi ditolak';
          isLoading = false;
        });
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        weatherDescription = 'Izin lokasi ditolak permanen';
        isLoading = false;
      });
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String?> _getCityFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemark = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemark.isNotEmpty) {
        return placemark.first.locality ?? "Uknown Location";
      }
      return null;
    } catch (e) {
      print("Error Get City ${e}");
      return null;
    }
  }

  Future<void> fetchWeather() async {
    try {
      const apiKey = 'f27dcb2f2fa385362cda3d5bc1ccb497';

      Position? position = await _getCurrentLocation();
      if (position == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      String? city = await _getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (city == null) {
        setState(() {
          weatherDescription = 'Gagal mendapatkan nama kota';
          isLoading = false;
        });
        return;
      }

      setState(() {
        weatherLocation = city;
      });
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric&lang=id',
      );
      print('URL: $url');
      final response = await http.get(url);
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temperature = data['main']['temp'].toDouble();
          weatherDescription = data['weather'][0]['description'];
          isLoading = false;
        });
      } else {
        setState(() {
          weatherDescription =
              'Gagal mengambil data cuaca: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('Error: $e\nStackTrace: $stackTrace');
      setState(() {
        weatherDescription = 'Error saat mengambil data: $e';
        isLoading = false;
      });
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // MODIFIED: Added onTap to navigate to ProfilePage with slide animation
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => ProfilePage(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(-1.0, 0.0); // Start from left
                                const end = Offset(0.0, 0.0); // End at center
                                const curve = Curves.ease;

                                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : AssetImage('assets/photomoki.png'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome 🙌',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            userName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notifications_none_outlined),
                    iconSize: 28,
                    color: Colors.grey[700],
                    tooltip: 'Notifications',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Daily Challenge Card
              Card(
                color: const Color(0xffFF6A00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.directions_run,
                                color: Colors.white,
                                size: 30,
                              ),
                              SizedBox(width: 8),
                            ],
                          ),
                          Text(
                            'Daily Challenge',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text("Dismiss Challenge"),
                                      content: Text(
                                        "Kartu challenge disembunyikan.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: Text("OK"),
                                        ),
                                      ],
                                    ),
                              );
                            },
                            icon: const Icon(Icons.close),
                            color: Colors.white,
                            iconSize: 24,
                            tooltip: 'Dismiss',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sprint for 30 seconds. Repeat this\ninterval 5 times',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Good job! Kamu menyelesaikan challenge",
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            'Done',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Today Stats Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today Stats",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'See All',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Menampilkan statistik lengkap..."),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_ios_rounded),
                        iconSize: 14,
                        color: Colors.grey[600],
                        tooltip: 'See All Stats',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Today Stats Cards
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: const Color(0xffFF6A00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.directions_walk,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isLoading
                                      ? 'Loading...'
                                      : (todayRunData?['steps']?.toString() ?? '0'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Steps',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      color: const Color(0xffFF6A00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                   isLoading
                                      ? 'Loading...'
                                      : (todayRunData?['calories']?.toString() ?? '0'),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Kalori',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weather Section
              Text(
                "Perkiraan Cuaca",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xff2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child:
                      isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              const Icon(
                                Icons.cloud,
                                color: Colors.white,
                                size: 60,
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$weatherLocation',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${temperature.toStringAsFixed(0)}°C',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 28,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    weatherDescription,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xffFF6A00),
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: 'Start'), // Moved Start to index 1
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Challenge',
          ), // Moved Challenge to index 2
          // Removed Profile item
        ],
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 0) {
            // Stay on Dashboard
          } else if (index == 1) { // Updated index for Start
            Navigator.pushReplacementNamed(context, '/running-track');
          } else if (index == 2) { // Updated index for Challenge
            Navigator.pushReplacementNamed(context, '/challenge');
          }
          // Removed logic for index 3 (Profile)
        },
      ),
    );
  }
}