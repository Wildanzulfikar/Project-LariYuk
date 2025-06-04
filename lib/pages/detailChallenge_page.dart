import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lari_yuk/theme.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DetailChallengePage extends StatefulWidget {
  DetailChallengePage({Key? key}) : super(key: key);

  @override
  State<DetailChallengePage> createState() => _DetailChallengePageState();
}

class _DetailChallengePageState extends State<DetailChallengePage> {
  final ScreenshotController _contentScreenshotController = ScreenshotController();
  int _selectedIndex = 1; // Default to 'Challenge'

  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/challenge');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/running-start');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  // Extract the Scaffold as a method for easy screenshotting
  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Detail',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black, size: 24),
            onPressed: () async {
              print('Share icon pressed');
              final image = await _contentScreenshotController.capture(pixelRatio: 2.0);
              print('Screenshot taken');
              if (image == null) {
                print('Image is null');
                return;
              }
              showDialog(
                context: context,
                builder: (context) => DefaultTextStyle(
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                  child: AlertDialog(
                    title: const Text('Preview Screenshot'),
                    content: Image.memory(image),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          final directory = await getTemporaryDirectory();
                          final imagePath = await File('${directory.path}/challenge_share.png').create();
                          await imagePath.writeAsBytes(image);

                          await Share.shareFiles(
                            [imagePath.path],
                            text: 'Check out my challenge progress! https://your-link.com',
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('Share'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildScaffoldContent(context),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xffFF6A00),
        unselectedItemColor: Colors.grey,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Challenge',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.play_arrow), label: 'Start'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onNavBarTapped,
      ),
    );
  }

  // Extract the content for screenshotting
  Widget _buildScaffoldContent(BuildContext context) {
    return SingleChildScrollView(
      child: DefaultTextStyle(
        style: GoogleFonts.plusJakartaSans(
          color: Colors.black,
          fontSize: 14,
        ),
        child: Screenshot(
          controller: _contentScreenshotController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Image (no padding, full width)
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Image.asset(
                  'assets/image 5.png',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              // Main content with consistent padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    // User Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundImage: AssetImage('assets/photomoki.png'),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Wildan Zufikar',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Di perbarui pukul 16:00',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Detail Title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Detail Tantangan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Challenge Title
                    Text(
                      '"Lari Jauh, Lebih Kuat Setiap Hari" –\nPersonal Marathon Challenge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Challenge Description
                    Text(
                      'Tantang dirimu dengan Personal Marathon Challenge! Tetapkan target jarak lari atau jalan sesuai kemampuanmu dan mulai perjalanan menuju versi terbaik dari dirimu. Dengan pantauan progres harian, setiap langkah membawamu lebih dekat ke garis finis – lebih kuat, lebih konsisten, setiap hari.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Progress Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF7F2F),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '28.8 Km',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Stack(
                        children: [
                          Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: 0.6, // 60% progress
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(0xFFFF7F2F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Progress Text
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: const [
                          Icon(Icons.flag, color: Color(0xFFFF7F2F), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Kamu sudah menyelesaikan 60%',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/challenge');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF7F2F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Kembali ke Halaman Challenge',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildScaffold(context);
  }
}