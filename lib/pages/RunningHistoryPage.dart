import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class RunningHistoryPage extends StatefulWidget {
  const RunningHistoryPage({super.key});

  @override
  State<RunningHistoryPage> createState() => _RunningHistoryPageState();
}

class _RunningHistoryPageState extends State<RunningHistoryPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DocumentSnapshot> _history = [];
  bool _isLoading = false;

  double _totalDistance = 0;
  double _totalDuration = 0;
  int _totalSteps = 0;
  Map<int, double> _monthlyDistance = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchHistory();
    _fetchMonthlySummary();
  }

  Future<void> _fetchHistory() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      final start = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
      final end = start.add(const Duration(days: 1));

      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('running_history')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThan: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .get();

      setState(() {
        _history = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMonthlySummary() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final firstDayNextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);

    try {
      final snapshot = await _db
          .collection('users')
          .doc(uid)
          .collection('running_history')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth))
          .where('date', isLessThan: Timestamp.fromDate(firstDayNextMonth))
          .get();

      double totalDist = 0;
      double totalDur = 0;
      int totalStep = 0;
      Map<int, double> distancePerDay = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final distance = (data['distance'] ?? 0).toDouble();

        totalDist += distance;
        totalDur += (data['duration'] ?? 0).toDouble();
        totalStep += int.tryParse(data['steps'].toString()) ?? 0;

        distancePerDay[date.day] = (distancePerDay[date.day] ?? 0) + distance;
      }

      setState(() {
        _totalDistance = totalDist;
        _totalDuration = totalDur;
        _totalSteps = totalStep;
        _monthlyDistance = distancePerDay;
      });
    } catch (e) {
      print("Gagal memuat ringkasan bulanan: $e");
    }
  }

  Future<void> _deleteHistory(String docId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Riwayat"),
        content: const Text("Apakah kamu yakin ingin menghapus data ini?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Batal")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Hapus")),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('users').doc(uid).collection('running_history').doc(docId).delete();
      _fetchHistory();
      _fetchMonthlySummary();
    }
  }

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.orange),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildHistoryItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['date'] as Timestamp).toDate();
    final formattedDate = DateFormat('EEEE, dd MMM yyyy – HH:mm', 'id_ID').format(date);
    final distance = (data['distance'] as num).toStringAsFixed(2);
    final duration = (data['duration'] as num).toStringAsFixed(1);
    final steps = data['steps'] ?? 0;
    final status = data['status'] ?? '-';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.directions_run, color: Colors.blue),
        title: Text('Jarak: $distance km | Durasi: $duration menit',
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tanggal: $formattedDate'),
            Text('Langkah: $steps | Status: $status'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteHistory(doc.id),
        ),
      ),
    );
  }

 Widget _buildMonthlyDistanceList() {
  final daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);

  return ListView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(), // Biar bisa ditaruh dalam Column
    itemCount: daysInMonth,
    itemBuilder: (context, index) {
      final day = index + 1;
      final distance = _monthlyDistance[day] ?? 0.0;

      return ListTile(
        leading: Text(
          '$day Juni',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        title: LinearProgressIndicator(
          value: distance > 0 ? (distance / 10).clamp(0.0, 1.0) : 0.0,
          color: distance > 0 ? Colors.blue : Colors.grey,
          backgroundColor: Colors.grey[300],
        ),
        trailing: Text('${distance.toStringAsFixed(2)} km'),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Riwayat Lari"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TableCalendar(
                locale: 'id_ID',
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.week,
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _fetchHistory();
                  _fetchMonthlySummary();
                },
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ringkasan Bulanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem(Icons.directions_run, 'Jarak', '${_totalDistance.toStringAsFixed(2)} km'),
                            _buildSummaryItem(Icons.timer, 'Durasi', '${_totalDuration.toStringAsFixed(1)} mnt'),
                            _buildSummaryItem(Icons.directions_walk, 'Langkah', '$_totalSteps'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_monthlyDistance.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Grafik Jarak Harian", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildMonthlyDistanceList(),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: Text("Belum ada data bulan ini.")),
                ),
              const Divider(thickness: 1, height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Riwayat Harian", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  : _history.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text("Belum ada riwayat lari di tanggal ini.")))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _history.length,
                          itemBuilder: (ctx, i) => _buildHistoryItem(_history[i]),
                        ),
            ],
          ),
        ),
      ),

    );
  }
}