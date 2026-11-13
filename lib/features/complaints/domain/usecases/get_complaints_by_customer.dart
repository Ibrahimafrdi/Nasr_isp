import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';
import 'package:nasr_isp/features/complaints/domain/repositories/complaint_repository.dart';

class GetComplaintsByCustomer {
  final ComplaintRepository repository;

  GetComplaintsByCustomer(this.repository);

  Future<List<ComplaintEntity>> call(String customerId) async {
    return repository.getComplaintsByCustomer(customerId);
  }
}

