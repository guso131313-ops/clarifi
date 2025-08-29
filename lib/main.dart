import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

// Firebase Web Options
const FirebaseOptions _webOptions = FirebaseOptions(
  apiKey: "AIzaSyDdgupx6yq_tY6JiE42Ujy6yx3XPb0KeOk",
  authDomain: "clarifi-89c1c.firebaseapp.com",
  projectId: "clarifi-89c1c",
  storageBucket: "clarifi-89c1c.firebasestorage.app",
  messagingSenderId: "473455065533",
  appId: "1:473455065533:web:3fac5b2cbac273ccbdfad4",
  measurementId: "G-L9Q5WMM18X",
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(options: _webOptions);
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

// ==================== APP ====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clarifi',
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        return user == null ? const AuthScreen() : HomeScreen(user: user);
      },
    );
  }
}

// ==================== LOGIN ====================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl  = TextEditingController();
  bool loading = false;

  Future<void> signUp() async {
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Error al registrarse');
    } finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> signIn() async {
    setState(() => loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Error al iniciar sesión');
    } finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        _snack('Google en Android lo activamos después. Usa Email/Password por ahora.');
      }
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? 'Error con Google');
    } catch (e) {
      _snack('No se pudo iniciar sesión con Google');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clarifi – Acceso')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
                const SizedBox(height: 20),
                if (loading) const CircularProgressIndicator(),
                if (!loading) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: signIn, child: const Text('Iniciar sesión')),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: signUp, child: const Text('Crear cuenta')),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.login),
                      onPressed: signInWithGoogle,
                      label: const Text('Continuar con Google (Web)'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== HOME + TRANSACCIONES ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});
  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _now;
  late DateTime _start;
  late DateTime _end;
  late String _monthTitle;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _start = DateTime(_now.year, _now.month, 1);
    _end   = (_now.month == 12)
        ? DateTime(_now.year + 1, 1, 1)
        : DateTime(_now.year, _now.month + 1, 1);
    _monthTitle = "${_now.year}-${_now.month.toString().padLeft(2, '0')}";
  }

  Future<void> _addQuickTransaction({
    required double amount,
    required String type, // 'income' | 'expense'
    required String category,
    String? note,
  }) async {
    try {
      final uid = widget.user.uid;
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('transactions')
          .add({
        'amount': amount,
        'type': type,
        'date': Timestamp.fromDate(DateTime.now()),
        'category': category,
        'note': note,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transacción guardada ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando: $e')),
        );
      }
    }
  }

  Future<List<BarChartGroupData>> _loadMonthlyBarGroups() async {
    final uid = widget.user.uid;

    try {
      final qs = await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_start))
          .where('date', isLessThan: Timestamp.fromDate(_end))
          .get();

      final daysInMonth = _end.difference(_start).inDays;
      final totalsByDay = List<double>.filled(daysInMonth, 0);

      for (final d in qs.docs) {
        final ts = d['date'] as Timestamp;
        final dt = ts.toDate();
        final idx = dt.day - 1; // día 1 -> índice 0
        final amt = (d['amount'] as num).toDouble();
        totalsByDay[idx] += amt;
      }

      final List<BarChartGroupData> groups = [];
      for (int i = 0; i < daysInMonth; i++) {
        groups.add(
          BarChartGroupData(
            x: i + 1,
            barRods: [
              BarChartRodData(
                toY: totalsByDay[i],
                width: 8,
                borderRadius: BorderRadius.circular(2),
              )
            ],
          ),
        );
      }
      return groups;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando datos: $e')),
        );
      }
      return const <BarChartGroupData>[];
    }
  }

  void _showAddDialog() {
    final amountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'General');
    String type = 'expense';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar transacción'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto (negativo gasto, positivo ingreso)'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'expense', child: Text('Gasto')),
                DropdownMenuItem(value: 'income', child: Text('Ingreso')),
              ],
              onChanged: (v) => type = v ?? 'expense',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final parsed = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
              await _addQuickTransaction(
                amount: parsed,
                type: type,
                category: categoryCtrl.text.trim().isEmpty ? 'General' : categoryCtrl.text.trim(),
              );
              if (mounted) Navigator.pop(context);
              setState(() {}); // recargar gráfico
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.user.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text('Clarifi – $uid'),
        actions: [
          IconButton(
            tooltip: 'Salir',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<BarChartGroupData>>(
          future: _loadMonthlyBarGroups(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final groups = snap.data ?? const <BarChartGroupData>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mes: $_monthTitle', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      barGroups: groups,
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 5,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                            ),
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
