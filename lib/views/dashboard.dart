import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/firestore_service.dart';
import 'transaction_form.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.user});
  final User user;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _service = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  DateTimeRange _rangeFor(int index) {
    final now = DateTime.now();
    switch (index) {
      case 0:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: start.add(const Duration(days: 1)));
      case 1:
        final start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
        return DateTimeRange(start: start, end: start.add(const Duration(days: 7)));
      case 2:
        final start = DateTime(now.year, now.month, 1);
        final end = (now.month == 12)
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);
        return DateTimeRange(start: start, end: end);
      default:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year + 1, 1, 1);
        return DateTimeRange(start: start, end: end);
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar transacción'),
        content: TransactionForm(
          onSubmit: (amount, type, date, category, note) async {
            await _service.addTransaction(
              widget.user.uid,
              TransactionModel(
                amount: amount,
                type: type,
                date: date,
                category: category,
                note: note,
              ),
            );
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Día'),
            Tab(text: 'Semana'),
            Tab(text: 'Mes'),
            Tab(text: 'Año'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tab,
        children: List.generate(4, (i) => _buildRangeView(i)),
      ),
    );
  }

  Widget _buildRangeView(int index) {
    final range = _rangeFor(index);
    return StreamBuilder<List<TransactionModel>>(
      stream: _service.transactionsInRange(
        widget.user.uid,
        range.start,
        range.end,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final txs = snap.data ?? [];
        final bars = _buildBarData(txs, index, range);
        final line = _buildLineData(txs, index, range);
        final pie = index == 2 ? _buildPieData(txs) : null;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barGroups: bars,
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [LineChartBarData(spots: line)],
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                if (pie != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(sections: pie),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  List<BarChartGroupData> _buildBarData(
      List<TransactionModel> txs, int index, DateTimeRange range) {
    int count;
    switch (index) {
      case 0:
        count = 24;
        break;
      case 1:
        count = 7;
        break;
      case 2:
        count = range.end.difference(range.start).inDays;
        break;
      default:
        count = 12;
    }
    final totals = List<double>.filled(count, 0);
    for (final t in txs) {
      final dt = t.date;
      int i;
      switch (index) {
        case 0:
          i = dt.hour;
          break;
        case 1:
          i = dt.weekday - 1;
          break;
        case 2:
          i = dt.day - 1;
          break;
        default:
          i = dt.month - 1;
      }
      totals[i] += t.amount;
    }
    return List.generate(
      count,
      (i) => BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(toY: totals[i], width: 8)],
      ),
    );
  }

  List<FlSpot> _buildLineData(
      List<TransactionModel> txs, int index, DateTimeRange range) {
    int count;
    switch (index) {
      case 0:
        count = 24;
        break;
      case 1:
        count = 7;
        break;
      case 2:
        count = range.end.difference(range.start).inDays;
        break;
      default:
        count = 12;
    }
    final totals = List<double>.filled(count, 0);
    for (final t in txs) {
      final dt = t.date;
      int i;
      switch (index) {
        case 0:
          i = dt.hour;
          break;
        case 1:
          i = dt.weekday - 1;
          break;
        case 2:
          i = dt.day - 1;
          break;
        default:
          i = dt.month - 1;
      }
      totals[i] += t.amount;
    }
    double acc = 0;
    final spots = <FlSpot>[];
    for (int i = 0; i < count; i++) {
      acc += totals[i];
      spots.add(FlSpot(i.toDouble(), acc));
    }
    return spots;
  }

  List<PieChartSectionData> _buildPieData(List<TransactionModel> txs) {
    final map = <String, double>{};
    for (final t in txs) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    final colors = Colors.primaries;
    int i = 0;
    return map.entries
        .map((e) => PieChartSectionData(
              value: e.value,
              title: e.key,
              color: colors[i++ % colors.length],
            ))
        .toList();
  }
}
