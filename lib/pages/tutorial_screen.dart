import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  List<TargetFocus> targets = [];

  // GlobalKeys untuk setiap elemen yang ingin disorot
  GlobalKey keyProfile = GlobalKey();
  GlobalKey keyNotification = GlobalKey();
  GlobalKey keyChallengeCard = GlobalKey();
  GlobalKey keyStatsCard = GlobalKey();
  GlobalKey keyWeatherCard = GlobalKey();
  GlobalKey keyNavHome = GlobalKey();
  GlobalKey keyNavStart = GlobalKey();
  GlobalKey keyNavHistory = GlobalKey();

  late TutorialCoachMark tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    initTargets();
    checkIfUserIsNew();
  }

  void checkIfUserIsNew() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()?['is_new'] == true) {
      initTargets(); // inisialisasi highlight
      WidgetsBinding.instance.addPostFrameCallback((_) => showTutorial());
    } else {
      // Lewati tutorial, langsung ke dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }
}

  void initTargets() {
  targets.addAll([
    TargetFocus(
      identify: "profile",
      keyTarget: keyProfile,
      radius: 60, // tambahkan radius yang besar agar bentuknya mendekati lingkaran
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Text(
            "Ini adalah profil kamu.",
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),
        ),
      ],
    ),
    TargetFocus(
      identify: "notification",
      keyTarget: keyNotification,
      radius: 60,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Text(
            "Kamu bisa melihat notifikasi di sini.",
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
    TargetFocus(
      identify: "challenge",
      keyTarget: keyChallengeCard,
      shape: ShapeLightFocus.RRect,
      contents: [
        TargetContent(
          align: ContentAlign.bottom,
          child: Text(
            "Tantangan harian, coba diselesaikan ya!",
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
    TargetFocus(
      identify: "stats",
      keyTarget: keyStatsCard,
      shape: ShapeLightFocus.RRect,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          child: Text(
            "Statistik harian kamu: langkah & kalori.",
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
    TargetFocus(
      identify: "weather",
      keyTarget: keyWeatherCard,
      shape: ShapeLightFocus.RRect,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          child: Text(
            "Lihat prakiraan cuaca untuk olahraga di luar.",
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
    TargetFocus(
      identify: "nav_home",
      keyTarget: keyNavHome,
      radius: 60,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          child: Text(
            "Beranda aplikasi.",
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
    TargetFocus(
      identify: "nav_start",
      keyTarget: keyNavStart,
      radius: 60,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          child: Text(
            "Mulai aktivitas olahraga kamu.",
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
    TargetFocus(
      identify: "nav_history",
      keyTarget: keyNavHistory,
      radius: 60,
      contents: [
        TargetContent(
          align: ContentAlign.top,
          child: Text(
            "Riwayat aktivitas kamu ditampilkan di sini.",
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  ]);
}


  void showTutorial() {
  tutorialCoachMark = TutorialCoachMark(
    targets: targets,
    colorShadow: Colors.orange, // Ganti warna jadi oranye
    textSkip: "Lewati",
    paddingFocus: 8,
    opacityShadow: 0.8,
    onFinish: () {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'is_new': false}).then((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
    },
    onSkip: () {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'is_new': false}).then((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
      return true;
    },
  )..show(context: context);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // AppBar custom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  key: keyProfile,
                  backgroundImage: NetworkImage("https://example.com/photo.jpg"),
                  radius: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Welcome 👋\ntrinikko81",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  key: keyNotification,
                  icon: const Icon(Icons.notifications_none),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  key: keyChallengeCard,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "Daily Challenge\nSprint for 30 seconds. Repeat 5 times.",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  key: keyStatsCard,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.orange,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: const [
                              Icon(Icons.directions_walk, color: Colors.white),
                              SizedBox(height: 8),
                              Text("0 Steps", style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        color: Colors.orange,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: const [
                              Icon(Icons.local_fire_department, color: Colors.white),
                              SizedBox(height: 8),
                              Text("0 Kalori", style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  key: keyWeatherCard,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    "Kecamatan Karang Tengah\n27°C\nawan pecah",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, key: keyNavHome),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_arrow, key: keyNavStart),
            label: "Start",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, key: keyNavHistory),
            label: "History",
          ),
        ],
      ),
    );
  }
}
