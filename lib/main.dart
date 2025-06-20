import 'package:flutter/material.dart';
import 'package:lari_yuk/pages/dashboard_page.dart';
import 'package:lari_yuk/pages/login_page.dart';
import 'pages/register_page.dart'; 
import 'pages/splash_screen.dart';
import 'package:lari_yuk/pages/challenge_page.dart';
import 'package:lari_yuk/pages/runningStart_page.dart';
import 'package:lari_yuk/pages/ProfilePage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'main_screen.dart';

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
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      //  routes: {
      //   '/' : (context) => SplashScreen(),
      //   '/login' : (context) => LoginPage(),
      //   '/register' : (context) => RegisterPage(),
      //   '/dashboard' : (context) => DashboardPage(),
      //   '/challenge' : (context) => ChallengePage(),
      //   '/running' : (context) => RunningStartPage(),
      //   '/profile' : (context) => ProfilePage(),  
      // } ,
      home: MainScreen(),
    );
  }
}