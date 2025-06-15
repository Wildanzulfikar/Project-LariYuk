import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lari_yuk/pages/dashboard_page.dart'; // Import DashboardPage

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Map<String, dynamic>> monthlyData = [];
  bool isLoading = true;
  double weight = 65.0;
  double height = 170.0;
  String userName = 'WILDAN ZULFIKAR';
  String userLocation = 'Daerah Khusus Ibukota\nJakarta, Indonesia';
  String? profileImageUrl;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        setState(() => isLoading = false);
        return;
      }

      // 1. Load profile data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          weight =
              data?['weight']?.toDouble() ??
              65.0; // Pastikan field 'weight' ada
          height = data?['height']?.toDouble() ?? 170.0;
          userName = data?['name'] ?? 'Light Switch';
          userLocation = data?['location'] ?? 'Unknown location'; // Sesuaikan
          profileImageUrl = data?['avatarUrl'];
        });
      }

      // 2. Load running history (subcollection)
      final runningHistoryQuery =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('running_history')
              .get();

      final Map<int, double> monthlyDistance = {};

      for (final doc in runningHistoryQuery.docs) {
        final data = doc.data();
        final distance = data['distance'] as double? ?? 0.0;
        final timestamp =
            data['date'] as Timestamp?; // Asumsi field 'date' adalah Timestamp

        if (timestamp != null) {
          final date = timestamp.toDate();
          final month = date.month;
          monthlyDistance[month] = (monthlyDistance[month] ?? 0.0) + distance;
        }
      }

      // 3. Format data untuk chart
      final formattedData = List.generate(12, (index) {
        final month = index + 1;
        return {'month': month, 'distance': monthlyDistance[month] ?? 0.0};
      });

      setState(() {
        monthlyData = formattedData;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    }
  }

  double _calculateMaxY() {
    if (monthlyData.isEmpty) return 10;
    final maxDistance = monthlyData
        .map((e) => e['distance'])
        .reduce((a, b) => a > b ? a : b);
    return (maxDistance * 1.2).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    nameController.text = name;
    weightController.text = weight;
    heightController.text = height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    // MODIFIED: Navigate to dashboard with slide-out animation
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => DashboardPage(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0); // Start from right
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
                    child: const Icon(Icons.arrow_back_ios, size: 24),
                  ),
                  const SizedBox(width: 8),
                  const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),

              // Profile section
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage:
                          profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : const AssetImage('assets/profile.jpg')
                                  as ImageProvider,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userLocation,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: const [
                            Text(
                              'Mengikuti',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              '1',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(width: 40),
                        Column(
                          children: const [
                            Text(
                              'Para pengikut',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              '1',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                          child: const Text('Bagikan kode QR saya'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {
                            if (isEditing) {
                              _saveProfile();
                            } else {
                              setState(() => isEditing = true);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                          child: Text(isEditing ? 'Simpan' : 'Edit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Berat & Tinggi Badan
              const Text(
                'Berat Badan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${weight.toStringAsFixed(1)} KG',
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(),
              const Text(
                'Tinggi Badan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${height.toStringAsFixed(1)} CM',
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(),

              const SizedBox(height: 16),
              const Text(
                'Monthly Report',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Chart
              Container(
                height: 270,
                padding: const EdgeInsets.only(top: 25, left: 12, right: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _calculateMaxY(),
                            barTouchData: BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    return Text(value.toInt().toString());
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (
                                    double value,
                                    TitleMeta meta,
                                  ) {
                                    const months = [
                                      'JAN',
                                      'FEB',
                                      'MAR',
                                      'APR',
                                      'MEI',
                                      'JUN',
                                      'JUL',
                                      'AGU',
                                      'SEP',
                                      'OKT',
                                      'NOV',
                                      'DES',
                                    ];
                                    if (value.toInt() < months.length) {
                                      return Text(
                                        months[value.toInt()],
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups:
                                monthlyData.map((data) {
                                  final monthIndex = data['month'] - 1;
                                  final distance = data['distance'];
                                  return BarChartGroupData(
                                    x: monthIndex,
                                    barRods: [
                                      BarChartRodData(
                                        toY: distance,
                                        color: Colors.orange,
                                        width: 14,
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _infoCard(Icons.emoji_events, 'Challange Cleared', '10'),
                  _infoCard(Icons.flag, 'Session Finished', '10'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
          ),
        ),
      );
    }
  }
