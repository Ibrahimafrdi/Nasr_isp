import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/complaints/data/models/complaint_model.dart';

abstract class ComplaintRemoteDataSource {
  Future<void> addComplaint(ComplaintModel complaint);
  Future<List<ComplaintModel>> getComplaints({
    String? status,
    String? priority,
    String? type,
    String? employeeId,
    String? currentUserId,
    bool isAdmin = true,
    bool mineOnly = false,
    String? searchQuery,
  });
  Future<List<ComplaintModel>> getComplaintsByCustomer(String customerId);
  Future<void> updateComplaint(ComplaintModel complaint);
  Future<void> deleteComplaint(String id);
}

class ComplaintRemoteDataSourceImpl implements ComplaintRemoteDataSource {
  final FirebaseFirestore _firestore;

  ComplaintRemoteDataSourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _col => _firestore.collection('complaints');

  @override
  Future<void> addComplaint(ComplaintModel complaint) async {
    final docRef = _col.doc(complaint.id.isEmpty ? null : complaint.id);
    final effectiveComplaint = complaint.id.isEmpty
        ? complaint.copyWith(id: docRef.id)
        : complaint;

    final data = effectiveComplaint.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    if (effectiveComplaint.status == ComplaintStatus.resolved ||
        effectiveComplaint.status == ComplaintStatus.closed) {
      data['resolvedAt'] = FieldValue.serverTimestamp();
    } else {
      data['resolvedAt'] = null;
    }

    await docRef.set(data);
  }

  @override
  Future<List<ComplaintModel>> getComplaints({
    String? status,
    String? priority,
    String? type,
    String? employeeId,
    String? currentUserId,
    bool isAdmin = true,
    bool mineOnly = false,
    String? searchQuery,
  }) async {
    Query query = _col;

    if (!isAdmin) {
      // Employees only ever see complaints assigned to them.
      // This must match the Firestore rules exactly.
      if (currentUserId == null || currentUserId.isEmpty) return [];
      query = query.where('assignedEmployeeId', isEqualTo: currentUserId);
    } else if (mineOnly && currentUserId != null && currentUserId.isNotEmpty) {
      query = query.where('assignedEmployeeId', isEqualTo: currentUserId);
    } else if (employeeId != null && employeeId.isNotEmpty) {
      query = query.where('assignedEmployeeId', isEqualTo: employeeId);
    }

    final snapshot = await query.get();
    List<ComplaintModel> list = snapshot.docs
        .map((doc) => ComplaintModel.fromFirestore(doc))
        .toList();

    // In-memory filters to guarantee zero Firestore composite index errors
    if (status != null && status.isNotEmpty) {
      list = list.where((c) => c.status.name == status).toList();
    }
    if (priority != null && priority.isNotEmpty) {
      list = list.where((c) => c.priority.name == priority).toList();
    }
    if (type != null && type.isNotEmpty) {
      list = list.where((c) => c.type.name == type).toList();
    }

    // Sort in-memory by createdAt descending
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Filter in-memory by search query (customer name, phone, or customer ID)
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase().trim();
      list = list.where((c) {
        final nameMatches = c.customerName.toLowerCase().contains(queryLower);
        final phoneMatches = c.customerPhone.toLowerCase().contains(queryLower);
        final idMatches = c.customerId.toLowerCase().contains(queryLower);
        final descMatches = c.description.toLowerCase().contains(queryLower);
        return nameMatches || phoneMatches || idMatches || descMatches;
      }).toList();
    }

    return list;
  }

  @override
  Future<List<ComplaintModel>> getComplaintsByCustomer(
    String customerId,
  ) async {
    final snapshot = await _col
        .where('customerId', isEqualTo: customerId)
        .get();

    final list = snapshot.docs
        .map((doc) => ComplaintModel.fromFirestore(doc))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<void> updateComplaint(ComplaintModel complaint) async {
    final docRef = _col.doc(complaint.id);
    final currentDoc = await docRef.get();
    if (!currentDoc.exists) {
      throw Exception('Complaint with ID ${complaint.id} does not exist.');
    }

    final currentData = currentDoc.data() as Map<String, dynamic>? ?? {};

    // Send only fields that changed, so an employee's update stays inside
    // what the Firestore rules allow.
    final data = <String, dynamic>{};
    complaint.toMap().forEach((key, value) {
      if (key == 'createdAt' || key == 'updatedAt' || key == 'resolvedAt') {
        return;
      }
      if (currentData[key] != value) data[key] = value;
    });
    data['updatedAt'] = FieldValue.serverTimestamp();

    final isDone =
        complaint.status == ComplaintStatus.resolved ||
        complaint.status == ComplaintStatus.closed;
    if (isDone) {
      if (currentData['resolvedAt'] == null) {
        data['resolvedAt'] = FieldValue.serverTimestamp();
      }
    } else if (currentData['resolvedAt'] != null) {
      data['resolvedAt'] = null;
    }

    await docRef.update(data);
  }

  @override
  Future<void> deleteComplaint(String id) async {
    await _col.doc(id).delete();
  }
}
