import 'package:nasr_isp/features/complaints/data/datasources/complaint_remote_data_source.dart';
import 'package:nasr_isp/features/complaints/data/models/complaint_model.dart';
import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';
import 'package:nasr_isp/features/complaints/domain/repositories/complaint_repository.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  final ComplaintRemoteDataSource remoteDataSource;

  ComplaintRepositoryImpl({required this.remoteDataSource});

  ComplaintModel _toModel(ComplaintEntity e) {
    return ComplaintModel(
      id: e.id,
      customerId: e.customerId,
      customerName: e.customerName,
      customerPhone: e.customerPhone,
      type: e.type,
      priority: e.priority,
      status: e.status,
      description: e.description,
      assignedEmployeeId: e.assignedEmployeeId,
      assignedEmployeeName: e.assignedEmployeeName,
      resolutionNotes: e.resolutionNotes,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      resolvedAt: e.resolvedAt,
      createdById: e.createdById,
      createdByName: e.createdByName,
    );
  }

  @override
  Future<void> createComplaint(ComplaintEntity complaint) async {
    await remoteDataSource.addComplaint(_toModel(complaint));
  }

  @override
  Future<List<ComplaintEntity>> getComplaints({
    String? status,
    String? priority,
    String? type,
    String? employeeId,
    String? currentUserId,
    bool isAdmin = true,
    bool mineOnly = false,
    String? searchQuery,
  }) async {
    return await remoteDataSource.getComplaints(
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

  @override
  Future<List<ComplaintEntity>> getComplaintsByCustomer(
      String customerId) async {
    return await remoteDataSource.getComplaintsByCustomer(customerId);
  }

  @override
  Future<void> updateComplaint(ComplaintEntity complaint) async {
    await remoteDataSource.updateComplaint(_toModel(complaint));
  }

  @override
  Future<void> deleteComplaint(String id) async {
    await remoteDataSource.deleteComplaint(id);
  }
}

