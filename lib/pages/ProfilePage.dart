import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lari_yuk/pages/dashboard_page.dart'; // Import DashboardPage

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  String name = '';
  String location = 'Daerah Khusus Ibukota\nJakarta, Indonesia';
  String weight = '';
  String height = '';
  String? profileImageUrl;

  final nameController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Fetch user data from Firestore
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      setState(() {
        name = data?['name'] ?? user.displayName ?? 'Unknown User';
        // Convert number to string for weight and height
        weight = data?['weight']?.toString() ?? 'Not Set';
        height = data?['height']?.toString() ?? 'Not Set';
        profileImageUrl = data?['avatarUrl'] ?? user.photoURL;
      });
    }
  }

  Future<void> _saveProfile() async {
    final newName = nameController.text.trim();
    final newWeight = weightController.text.trim();
    final newHeight = heightController.text.trim();

    setState(() {
      name = newName.isNotEmpty ? newName : name;
      weight = newWeight.isNotEmpty ? newWeight : weight;
      height = newHeight.isNotEmpty ? newHeight : height;
      isEditing = false;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'weight': newWeight.isNotEmpty ? num.parse(newWeight) : num.parse(weight), // Convert to number
        'height': newHeight.isNotEmpty ? num.parse(newHeight) : num.parse(height), // Convert to number
        'avatarUrl': profileImageUrl,
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
      final ref = FirebaseStorage.instance.ref().child('profile_images/${FirebaseAuth.instance.currentUser!.uid}/${picked.name}');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      setState(() => profileImageUrl = url);

      // Update Firestore with new photo URL
      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).set({
        'avatarUrl': url,
      }, SetOptions(merge: true));

      // Update Firebase Auth photo URL
      await FirebaseAuth.instance.currentUser!.updatePhotoURL(url);
    }
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
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const DashboardPage(),
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
                  ? TextField(controller: weightController, keyboardType: TextInputType.number)
                  : Text('$weight KG', style: const TextStyle(color: Colors.grey)),
              const Divider(),
              const Text('Tinggi Badan', style: TextStyle(fontWeight: FontWeight.bold)),
              isEditing
                  ? TextField(controller: heightController, keyboardType: TextInputType.number)
                  : Text('$height CM', style: const TextStyle(color: Colors.grey)),
              const Divider(),

              const SizedBox(height: 16),
              const Text(
                'Monthly Report',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Chart
              Container(
                height: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 10,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            const months = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];
                            return Text(value.toInt() < months.length ? months[value.toInt()] : '', style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(12, (i) {
                      final value = (i + 1) * 0.7 % 10;
                      return BarChartGroupData(
                        x: i,
                        barRods: [BarChartRodData(toY: value, color: Colors.orange, width: 14)],
                      );
                    }),
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
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white)),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}