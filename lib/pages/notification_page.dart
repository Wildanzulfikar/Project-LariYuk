import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _notificationTile(
            icon: Icons.directions_run,
            title: 'Challenge Baru Tersedia!',
            subtitle: 'Selesaikan 5 sprint hari ini untuk bonus XP!',
          ),
          _notificationTile(
            icon: Icons.local_fire_department,
            title: 'Kalori Tercapai 🎉',
            subtitle: 'Kamu telah membakar 150 kalori hari ini!',
          ),
          _notificationTile(
            icon: Icons.cloud,
            title: 'Update Cuaca',
            subtitle: 'Hari ini cerah berawan. Cocok untuk lari pagi.',
          ),
        ],
      ),
    );
  }

  Widget _notificationTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orangeAccent,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: GoogleFonts.plusJakartaSans()),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }
}
