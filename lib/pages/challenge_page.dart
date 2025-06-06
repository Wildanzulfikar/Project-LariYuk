import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lari_yuk/theme.dart';

class ChallengePage extends StatelessWidget {
  const ChallengePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final double cardSpacing = 16;
    final double horizontalPadding = 28.0;
    final double cardWidth = (width - (horizontalPadding * 2) - cardSpacing) / 2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'Challenge',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Top Image (move outside Padding)
              ClipRRect(
                child: Image.asset(
                  'assets/Group 80.png',
                  width: MediaQuery.of(context).size.width, // full width
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deskripsi
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Deskripsi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Halaman Challenge memungkinkan pengguna untuk menantang diri sendiri dengan menetapkan target jarak tempuh lari atau berjalan. Pengguna dapat menentukan jarak sesuai keinginan mereka dan memantau progres harian hingga target tercapai. Cocok untuk menjaga motivasi, meningkatkan konsistensi, dan mencapai tujuan kebugaran pribadi.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1.2, height: 32),
                    // Challenge Terjadwal Hari Ini
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: const Text(
                        'Challenge Terjadwal Hari Ini',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Daily Challenge Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFFF7F2F),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Stack(
                          children: [
                            // Decorative Circles
                            Positioned(
                              top: -18,
                              left: -18,
                              child: CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.18),
                                radius: 32,
                              ),
                            ),
                            Positioned(
                              bottom: -14,
                              right: -14,
                              child: CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.18),
                                radius: 28,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: const Icon(
                                      Icons.flag,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Challenge Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              'Daily Challenge',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 17,
                                              ),
                                            ),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: () {},
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'Sprint for 30 seconds. Repeat this interval 5 times',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.5,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Color(0xFFFF7F2F),
                                              shape: const StadiumBorder(),
                                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                                              elevation: 0,
                                            ),
                                            child: const Text(
                                              'Done',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Challenge Lainnya
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: const Text(
                        'Challenge Lainnya',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Center the cards in a Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _HoverableChallengeCard(
                            width: double.infinity, // Tidak perlu width lagi, biarkan Expanded yang atur
                            onTap: () {
                              Navigator.pushNamed(context, '/detail-challenge');
                            },
                          ),
                        ),
                        SizedBox(width: cardSpacing),
                        Expanded(
                          child: _HoverableChallengeCard(
                            width: double.infinity,
                            onTap: () {
                              Navigator.pushNamed(context, '/detail-challenge');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
            bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xffFF6A00),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
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
        currentIndex: 2, // Updated index to 2 for Challenge
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (index == 1) { // Updated index for Start
            Navigator.pushReplacementNamed(context, '/running-start');
          } else if (index == 2) { // Updated index for Challenge
            Navigator.pushReplacementNamed(context, '/challenge');
          }
          // Removed logic for index 3 (Profile)
        },
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4, right: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFFF7F2F), width: 1.5),
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/image 6.png',
                height: 100,
                width: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 100,
              child: Text(
                '"Lari Jauh, Lebih Kuat Setiap Hari" – Personal Marathon ...',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dimulai : 29 Mei 2025',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverableChallengeCard extends StatefulWidget {
  final VoidCallback? onTap;
  final double width;
  const _HoverableChallengeCard({Key? key, this.onTap, required this.width}) : super(key: key);

  @override
  State<_HoverableChallengeCard> createState() => _HoverableChallengeCardState();
}

class _HoverableChallengeCardState extends State<_HoverableChallengeCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(left: 4, right: 4),
          transform: _isHovered
              ? (Matrix4.identity()..scale(1.04))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFFFF7F2F), width: 1.5),
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Challenge Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/image 6.png',
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '"Lari Jauh, Lebih Kuat Setiap Hari" – Personal...',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dimulai : 29 Mei 2025',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
