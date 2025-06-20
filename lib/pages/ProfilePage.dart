import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  bool isLoading = true;
  List<Map<String, dynamic>> monthlyData = [];
  String name = '';
  String location = 'Daerah Khusus Ibukota\nJakarta, Indonesia';
  String weight = '';
  String height = '';
  String? profileImageUrl;

  final nameController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

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
          name = data?['name'] ?? user.displayName ?? 'Unknown User';
          // Convert Firestore numbers to strings, ensuring valid format
          weight = data?['weight'] != null ? data!['weight'].toString() : '65.0';
          height = data?['height'] != null ? data!['height'].toString() : '170.0';
          location = data?['location'] ?? 'Daerah Khusus Ibukota\nJakarta, Indonesia';
          profileImageUrl = data?['avatarUrl'] ?? user.photoURL;
        });
      }

      // 2. Load running history (subcollection)
      final runningHistoryQuery =
          await _firestore.collection('users').doc(user.uid).collection('running_history').get();

      final Map<int, double> monthlyDistance = {};

      for (final doc in runningHistoryQuery.docs) {
        final data = doc.data();
        final distance = data['distance'] as double? ?? 0.0;
        final timestamp = data['date'] as Timestamp?;

        if (timestamp != null) {
          final date = timestamp.toDate();
          final month = date.month;
          monthlyDistance[month] = (monthlyDistance[month] ?? 0.0) + distance;
        }
      }

      // 3. Format data for chart
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

  Future<void> _saveProfile() async {
    final newName = nameController.text.trim();
    final newWeight = weightController.text.trim();
    final newHeight = heightController.text.trim();

    // Validate weight and height inputs
    if (newWeight.isNotEmpty) {
      try {
        double.parse(newWeight);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid weight (e.g., 65.0)')),
        );
        return;
      }
    }
    if (newHeight.isNotEmpty) {
      try {
        double.parse(newHeight);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid height (e.g., 175.0)')),
        );
        return;
      }
    }

    setState(() {
      name = newName.isNotEmpty ? newName : name;
      weight = newWeight.isNotEmpty ? newWeight : weight;
      height = newHeight.isNotEmpty ? newHeight : height;
      isEditing = false;
    });

    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'weight': newWeight.isNotEmpty ? double.parse(newWeight) : double.parse(weight),
        'height': newHeight.isNotEmpty ? double.parse(newHeight) : double.parse(height),
        'avatarUrl': profileImageUrl,
        'location': location,
      }, SetOptions(merge: true));

      // Update Firebase Auth display name and photo URL if changed
      if (newName.isNotEmpty && newName != user.displayName) {
        await user.updateDisplayName(newName);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final ref = FirebaseStorage.instance.ref().child('profile_images/${_auth.currentUser!.uid}/${picked.name}');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      setState(() => profileImageUrl = url);

      // Update Firestore with new photo URL
      await _firestore.collection('users').doc(_auth.currentUser!.uid).set({
        'avatarUrl': url,
      }, SetOptions(merge: true));

      // Update Firebase Auth photo URL
      await _auth.currentUser!.updatePhotoURL(url);
    }
  }

  double _calculateMaxY() {
    if (monthlyData.isEmpty) return 10;
    final maxDistance = monthlyData.map((e) => e['distance'] as double).reduce((a, b) => a > b ? a : b);
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
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/dashboard');
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
                    GestureDetector(
                      onTap: isEditing ? _pickImage : null,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: profileImageUrl != null
                                ? NetworkImage(profileImageUrl!)
                                : const AssetImage('assets/profile.jpg') as ImageProvider,
                          ),
                          if (isEditing)
                            const Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.orange,
                                child: Icon(Icons.edit, size: 14, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    isEditing
                        ? TextField(
                            controller: nameController,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                          )
                        : Text(name, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                      location,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                 
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                       
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
              const Text('Berat Badan', style: TextStyle(fontWeight: FontWeight.bold)),
              isEditing
                  ? TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                      decoration: const InputDecoration(
                        suffixText: 'KG',
                        hintText: 'Enter weight (e.g., 65.0)',
                      ),
                    )
                  : Text(
                      weight.isNotEmpty && double.tryParse(weight) != null
                          ? '${double.parse(weight).toStringAsFixed(1)} KG'
                          : 'Not Set',
                      style: const TextStyle(color: Colors.grey),
                    ),
              const Divider(),
              const Text('Tinggi Badan', style: TextStyle(fontWeight: FontWeight.bold)),
              isEditing
                  ? TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                      decoration: const InputDecoration(
                        suffixText: 'CM',
                        hintText: 'Enter height (e.g., 175.0)',
                      ),
                    )
                  : Text(
                      height.isNotEmpty && double.tryParse(height) != null
                          ? '${double.parse(height).toStringAsFixed(1)} CM'
                          : 'Not Set',
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
                child: isLoading
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
                                getTitlesWidget: (double value, TitleMeta meta) {
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
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: monthlyData.map((data) {
                            final monthIndex = data['month'] - 1;
                            final distance = data['distance'] as double;
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}