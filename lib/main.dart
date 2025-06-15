import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lari_yuk/firebase_options.dart';
import 'package:lari_yuk/pages/challenge_page.dart';
import 'package:lari_yuk/pages/dashboard_page.dart';
import 'package:lari_yuk/pages/login_page.dart';
import 'package:lari_yuk/pages/runningStart_page.dart'; // Import the RunningStartPage
import 'package:lari_yuk/pages/running_track_page.dart';
import 'package:lari_yuk/pages/splash_screen.dart';
import 'package:lari_yuk/pages/register_page.dart'; // Import RegisterPage
import 'package:lari_yuk/pages/detailChallenge_page.dart'; // Import DetailChallengePage
import 'package:lari_yuk/pages/notification_page.dart'; // Import NotificationPage
import 'package:lari_yuk/pages/detail_page.dart'; // Import DetailPage
import 'package:lari_yuk/pages/ProfilePage.dart'; // Import ProfilePage


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lari Yuk',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Using initialRoute and routes is a common pattern
      initialRoute: '/', // Set the initial route
      routes: {
        '/': (context) => const SplashScreen(), // Define the root route
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(), // Define Register route
        '/dashboard': (context) => const DashboardPage(),
        '/challenge': (context) => const ChallengePage(),
        '/detailChallenge': (context) => DetailChallengePage(), // Define DetailChallenge route
        '/running-start': (context) => const RunningStartPage(), // Define the /running-start route
        '/profile': (context) => ProfilePage(), // Define Profile route
        '/notification': (context) => NotificationPage(), // Define Notification route
        '/detail': (context) => DetailPage(), // Define Detail route
        '/running-track' : (context) => RunningTrackPage()
      },
    );
  }
}
