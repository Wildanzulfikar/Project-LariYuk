import 'package:flutter/material.dart';
import 'package:lari_yuk/pages/login_page.dart';
import 'package:lari_yuk/pages/register_page.dart';
import 'package:lari_yuk/pages/profilePage.dart'; // pastikan file ini ada

void main() {
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
      routes: {
        '/': (context) => ProfilePage(),
        '/register': (context) => const RegisterPage(),
        // '/profile': (context) => ProfilePage(), // sudah include halaman profil
      },
    );
  }
}
