import 'package:nasr_isp/features/complaints/domain/repositories/complaint_repository.dart';

class DeleteComplaint {
  final ComplaintRepository repository;

  DeleteComplaint(this.repository);

  Future<void> call(String id) async {
    return repository.deleteComplaint(id);
  }
}

