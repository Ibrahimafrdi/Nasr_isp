import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';
import 'package:nasr_isp/features/complaints/domain/repositories/complaint_repository.dart';

class UpdateComplaint {
  final ComplaintRepository repository;

  UpdateComplaint(this.repository);

  Future<void> call(ComplaintEntity complaint) async {
    return repository.updateComplaint(complaint);
  }
}

