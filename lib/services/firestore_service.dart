import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  TransactionModel({
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    this.note,
  });

  final double amount;
  final String type;
  final DateTime date;
  final String category;
  final String? note;

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'type': type,
        'date': Timestamp.fromDate(date),
        'category': category,
        'note': note,
      };

  factory TransactionModel.fromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return TransactionModel(
      amount: (data['amount'] as num).toDouble(),
      type: data['type'] as String,
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] as String? ?? 'General',
      note: data['note'] as String?,
    );
  }
}

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> addTransaction(String uid, TransactionModel t) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .add(t.toMap());
  }

  Stream<List<TransactionModel>> transactionsInRange(
      String uid, DateTime start, DateTime end) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TransactionModel.fromDoc(d)).toList());
  }
}
