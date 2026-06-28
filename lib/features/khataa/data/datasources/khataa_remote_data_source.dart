import 'package:cloud_firestore/cloud_firestore.dart';

class KhataaEntry {
  final String id;
  final String customerId;
  final String customerName;
  final String type;       // 'credit' | 'debit'
  final double amount;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  const KhataaEntry({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  factory KhataaEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return KhataaEntry(
      id: doc.id,
      customerId: data['customerId'] as String,
      customerName: data['customerName'] as String,
      type: data['type'] as String,
      amount: (data['amount'] as num).toDouble(),
      description: data['description'] as String,
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'customerName': customerName,
    'type': type,
    'amount': amount,
    'description': description,
    'date': Timestamp.fromDate(date),
  };
}

abstract class KhataaRemoteDataSource {
  Future<void> addEntry(KhataaEntry entry);
  Future<List<KhataaEntry>> getEntries();
  Future<List<KhataaEntry>> getEntriesByCustomer(String customerId);
  Future<void> deleteEntry(String id);
}

class KhataaRemoteDataSourceImpl implements KhataaRemoteDataSource {
  final FirebaseFirestore _firestore;

  KhataaRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('khataa');

  @override
  Future<void> addEntry(KhataaEntry entry) async {
    final data = entry.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _col.doc(entry.id).set(data);
  }

  @override
  Future<List<KhataaEntry>> getEntries() async {
    final snapshot = await _col.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => KhataaEntry.fromFirestore(doc)).toList();
  }

  @override
  Future<List<KhataaEntry>> getEntriesByCustomer(String customerId) async {
    final snapshot = await _col
        .where('customerId', isEqualTo: customerId)
        .orderBy('date', descending: true)
        .get();
    return snapshot.docs.map((doc) => KhataaEntry.fromFirestore(doc)).toList();
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _col.doc(id).delete();
  }
}
