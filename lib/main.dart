import 'package:flutter/material.dart';
import 'package:lari_yuk/pages/dashboard_page.dart';
import 'package:lari_yuk/pages/login_page.dart';
import 'package:lari_yuk/pages/register_page.dart';
import 'package:lari_yuk/pages/profilePage.dart'; // pastikan file ini ada
import 'pages/register_page.dart'; 
import 'pages/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:lari_yuk/pages/challenge_page.dart';
import 'package:lari_yuk/pages/detailChallenge_page.dart';
import 'package:lari_yuk/pages/detail_page.dart';
import 'package:lari_yuk/pages/runningStart_page.dart'; // Sudah benar

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
      title: 'Lari Yuk',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter', // jika ingin seragam dengan Google Fonts Inter
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      initialRoute: '/challenge',
      routes: {
        '/': (context) => ProfilePage(),
        '/register': (context) => const RegisterPage(),
        // '/profile': (context) => ProfilePage(), // sudah include halaman profil
        '/' : (context) => SplashScreen(),
        '/login' : (context) => LoginPage(),
        '/register' : (context) => RegisterPage(),
        '/dashboard' : (context) => DashboardPage(),
        '/detail-challenge': (context) => DetailChallengePage(),
        '/detail-page': (context) => DetailPage(),
        '/running-start': (context) => RunningStartPage(), 
      },
    );
  }
}
