import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';
import 'package:nasr_isp/features/complaints/domain/repositories/complaint_repository.dart';

class GetComplaints {
  final ComplaintRepository repository;

  GetComplaints(this.repository);

  Future<List<ComplaintEntity>> call({
    String? status,
    String? priority,
    String? type,
    String? employeeId,
    String? currentUserId,
    bool isAdmin = true,
    bool mineOnly = false,
    String? searchQuery,
  }) async {
    return repository.getComplaints(
      status: status,
      priority: priority,
      type: type,
      employeeId: employeeId,
      currentUserId: currentUserId,
      isAdmin: isAdmin,
      mineOnly: mineOnly,
      searchQuery: searchQuery,
    );
  }
}

