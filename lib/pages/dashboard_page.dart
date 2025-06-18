import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lari_yuk/pages/ProfilePage.dart';
import 'package:lari_yuk/pages/notification_page.dart';
import 'package:lari_yuk/services/firestore_service.dart';
import 'package:lari_yuk/pages/ProfilePage.dart'; // Import ProfilePage
import 'package:intl/intl.dart'; // Tambahkan ini
import 'package:shared_preferences/shared_preferences.dart';

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

  int todaySteps = 0;
  bool isLoadingSteps = true;

  int todayCalories = 0;
  bool isLoadingCalories = true;

  Future<void> setChallengeDoneToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";
    await prefs.setString('challenge_done_date', todayStr);
  }

  Future<bool> isChallengeDoneToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";
    final doneDate = prefs.getString('challenge_done_date');
    return doneDate == todayStr;
  }

  // List challenge lokal (bisa kamu tambah sendiri)
  final List<Map<String, String>> dailyChallenges = [
    {
      "title": "Lari 2 km",
      "description": "Selesaikan lari sejauh 2 kilometer hari ini!"
    },
    {
      "title": "Jalan 5000 langkah",
      "description": "Jalan kaki minimal 5000 langkah hari ini!"
    },
    {
      "title": "Lari 15 menit",
      "description": "Lari selama minimal 15 menit tanpa berhenti!"
    },
    {
      "title": "Jalan pagi",
      "description": "Jalan kaki di pagi hari minimal 1 km."
    },
    {
      "title": "Lari sore",
      "description": "Lari santai di sore hari selama 20 menit."
    },
  ];

  Map<String, String> getTodayChallenge() {
    final startDate = DateTime(2024, 1, 1); // tanggal mulai challenge
    final today = DateTime.now();
    final diff = today.difference(startDate).inDays;
    final idx = diff % dailyChallenges.length;
    return dailyChallenges[idx];
  }

  @override
  void initState() {
    super.initState();
    _getUserName();
    fetchWeather();
    _fetchTodayRunData();
    _fetchTodaySteps();
    _fetchTodayCalories(); 
    checkUserStatus();// Tambahkan ini
  }

  void checkUserStatus() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  if (doc.exists && doc.data()?['is_new'] == true) {
    Navigator.pushReplacementNamed(context, '/tutorial');
    }
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

  Future<void> _fetchTodaySteps() async {
    final steps = await getTodayStepsFromHistory();
    setState(() {
      todaySteps = steps;
      isLoadingSteps = false;
    });
  }

  Future<void> _fetchTodayCalories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('running_history')
        .where('status', isEqualTo: 'completed')
        .get();

    int totalCalories = 0;
    for (var doc in snapshot.docs) {
      final ts = doc['date'];
      DateTime docDate;
      if (ts is Timestamp) {
        docDate = ts.toDate();
      } else if (ts is DateTime) {
        docDate = ts;
      } else {
        docDate = DateTime.tryParse(ts.toString()) ?? today;
      }
      if (docDate.year == today.year &&
          docDate.month == today.month &&
          docDate.day == today.day) {
        totalCalories += (doc['calories'] ?? 0) as int;
      }
    }
    setState(() {
      todayCalories = totalCalories;
      isLoadingCalories = false;
    });
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

  // Tambahkan fungsi ini:
  Future<void> addNotification(String notif) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> notifs = prefs.getStringList('notifications') ?? [];
    notifs.insert(0, notif); // tambah di awal
    await prefs.setStringList('notifications', notifs);
  }

  @override
  Widget build(BuildContext context) {
    // Daily Challenge Card (tanpa Firestore, otomatis update tiap hari)
    final todayChallenge = getTodayChallenge();

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

              // Daily Challenge Card (DYNAMIC)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FutureBuilder<bool>(
                  future: isChallengeDoneToday(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return SizedBox(
                        height: 140,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.data == true) {
                      return Card(
                        color: const Color(0xffFF6A00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text(
                              'Tidak ada daily challenge hari ini.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final todayChallenge = getTodayChallenge();
                    return Card(
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
                                Expanded(
                                  child: Text(
                                    todayChallenge['title'] ?? 'Daily Challenge',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis, // Agar tidak overflow
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.close),
                                  color: Colors.white,
                                  iconSize: 24,
                                  tooltip: 'Dismiss',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              todayChallenge['description'] ?? '',
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
                                onPressed: () async {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Good job! Kamu menyelesaikan challenge"),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                  await addNotification("Good job! Kamu menyelesaikan challenge");
                                  await setChallengeDoneToday();
                                  setState(() {}); // <-- ini WAJIB agar card langsung update!
                                  Future.delayed(const Duration(seconds: 1), () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const NotificationPage(),
                                      ),
                                    );
                                  });
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
                    );
                  },
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
                            Expanded( // Tambahkan Expanded di sini
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isLoadingSteps
                                        ? 'Loading...'
                                        : todaySteps.toString(),
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
                            Expanded( // Tambahkan Expanded di sini
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isLoadingCalories
                                        ? 'Loading...'
                                        : todayCalories.toString(),
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
            label: 'History',
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
            Navigator.pushReplacementNamed(context, '/history');
          }
        },
      ),
    );
  }
}

Future<void> saveSteps(int steps) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final today = DateTime.now();
  final dateStr = "${today.year}-${today.month}-${today.day}";
  await FirebaseFirestore.instance
      .collection('user_steps')
      .doc(user.uid)
      .set({
        'date': dateStr,
        'steps': steps,
      }, SetOptions(merge: true));
}

Future<int> getTodaySteps() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 0;
  final doc = await FirebaseFirestore.instance
      .collection('user_steps')
      .doc(user.uid)
      .get();
  if (!doc.exists) return 0;
  final today = DateTime.now();
  final dateStr = "${today.year}-${today.month}-${today.day}";
  if (doc['date'] == dateStr) {
    return doc['steps'] ?? 0;
  }
  return 0;
}

Future<int> getTodayStepsFromHistory() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 0;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('running_history')
      .where('status', isEqualTo: 'completed')
      .get();

  int totalSteps = 0;
  for (var doc in snapshot.docs) {
    final ts = doc['date'];
    DateTime docDate;
    if (ts is Timestamp) {
      docDate = ts.toDate();
    } else if (ts is DateTime) {
      docDate = ts;
    } else {
      docDate = DateTime.tryParse(ts.toString()) ?? today;
    }
    if (docDate.year == today.year &&
        docDate.month == today.month &&
        docDate.day == today.day) {
      totalSteps += (doc['steps'] ?? 0) as int;
    }
  }
  return totalSteps;
}

Future<int> getTodayCaloriesFromHistory() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 0;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('running_history')
      .where('status', isEqualTo: 'completed')
      .get();

  int totalCalories = 0;
  for (var doc in snapshot.docs) {
    final ts = doc['date'];
    DateTime docDate;
    if (ts is Timestamp) {
      docDate = ts.toDate();
    } else if (ts is DateTime) {
      docDate = ts;
    } else {
      docDate = DateTime.tryParse(ts.toString()) ?? today;
    }
    if (docDate.year == today.year &&
        docDate.month == today.month &&
        docDate.day == today.day) {
      totalCalories += (doc['calories'] ?? 0) as int;
    }
  }
  return totalCalories;
}