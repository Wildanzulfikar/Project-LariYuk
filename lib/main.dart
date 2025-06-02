import 'package:flutter/material.dart';
import 'package:lari_yuk/pages/dashboard_page.dart';
import 'package:lari_yuk/pages/login_page.dart';
import 'package:lari_yuk/pages/challenge_page.dart';
import 'package:lari_yuk/pages/detailChallenge_page.dart';
import 'package:lari_yuk/pages/detail_page.dart'; 

void main() {
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
      initialRoute: '/challenge',
      routes: {
        '/': (context) => LoginPage(),
        '/dashboard': (context) => DashboardPage(),
        '/challenge': (context) => ChallengePage(),
        '/detail-challenge': (context) => DetailChallengePage(),
        '/detail-page': (context) => DetailPage(), 
      },
    );
  }
}