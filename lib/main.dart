import 'package:flutter/material.dart';
import 'package:lari_yuk/pages/login_page.dart';
import 'pages/register_page.dart'; 
import 'pages/splash_screen.dart';

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
       routes: {
        '/' : (context) => SplashScreen(),
        '/login' : (context) => LoginPage(),
        '/register' : (context) => RegisterPage(),
      } ,
    );
  }
}
