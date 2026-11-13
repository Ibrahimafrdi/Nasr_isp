import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';
import 'package:nasr_isp/features/complaints/domain/repositories/complaint_repository.dart';

class CreateComplaint {
  final ComplaintRepository repository;

  CreateComplaint(this.repository);

  Future<void> call(ComplaintEntity complaint) async {
    return repository.createComplaint(complaint);
  }
}

