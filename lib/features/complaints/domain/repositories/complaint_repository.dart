import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';

abstract class ComplaintRepository {
  Future<void> createComplaint(ComplaintEntity complaint);
  Future<List<ComplaintEntity>> getComplaints({
    String? status,
    String? priority,
    String? type,
    String? employeeId,
    String? currentUserId,
    bool isAdmin = true,
    bool mineOnly = false,
    String? searchQuery,
  });
  Future<List<ComplaintEntity>> getComplaintsByCustomer(String customerId);
  Future<void> updateComplaint(ComplaintEntity complaint);
  Future<void> deleteComplaint(String id);
}

