import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<String> notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notifications = prefs.getStringList('notifications') ?? [];
    });
  }

  Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
    setState(() {
      notifications.clear();
    });
  }

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
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              tooltip: 'Clear Notifikasi',
              onPressed: () async {
                await clearNotifications();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Semua notifikasi dihapus!')),
                );
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(child: Text('Belum ada notifikasi'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _notificationTile(
                  icon: Icons.check_circle,
                  title: 'Challenge Selesai!',
                  subtitle: notifications[index],
                );
              },
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
