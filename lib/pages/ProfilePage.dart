import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Back Icon and Profile title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, size: 24),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile section
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/profile.jpg'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'WILDAN ZULFIKAR',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Daerah Khusus Ibukota\nJakarta, Indonesia',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: const [
                            Text('Mengikuti', style: TextStyle(color: Colors.grey)),
                            Text('1', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(width: 40),
                        Column(
                          children: const [
                            Text('Para pengikut', style: TextStyle(color: Colors.grey)),
                            Text('1', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                          child: const Text('Edit'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Berat & Tinggi Badan
              const Text('Berat Badan', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('1000 CM', style: TextStyle(color: Colors.grey)),
              const Divider(),
              const Text('Tinggi Badan', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('1000 KG', style: TextStyle(color: Colors.grey)),
              const Divider(),

              const SizedBox(height: 16),
              const Text('Monthly Report', style: TextStyle(fontWeight: FontWeight.bold)),
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
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 30),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double value, TitleMeta meta) {
              const months = [
                'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
                'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'
              ];
              if (value.toInt() < months.length) {
                return Text(months[value.toInt()], style: const TextStyle(fontSize: 10));
              }
              return const Text('');
            },
          ),
        ),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(12, (index) {
        final dummyValue = (index + 1) * 0.7 % 10; // nilai dummy antara 0–10
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(toY: dummyValue, color: Colors.orange, width: 14),
          ],
        );
      }),
    ),
  ),
),
              const SizedBox(height: 16),

              // Bottom two cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _infoCard(Icons.emoji_events, 'Challange Cleared', '10'),
                  _infoCard(Icons.flag, 'Session Finished', '10'),
                ],
              )
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
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.white)),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))
          ],
        ),
      ),
    );
  }
}
