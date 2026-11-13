import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/complaints/data/models/complaint_model.dart';
import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';

void main() {
  group('ComplaintModel & ComplaintEntity Tests', () {
    test('fromMap parses valid map correctly', () {
      final now = DateTime(2026, 11, 12, 10, 30);
      final map = {
        'customerId': 'cust_123',
        'customerName': 'Test Customer',
        'customerPhone': '03001234567',
        'type': 'noConnection',
        'priority': 'urgent',
        'status': 'open',
        'description': 'Internet disconnected since morning',
        'assignedEmployeeId': 'emp_1',
        'assignedEmployeeName': 'John Tech',
        'resolutionNotes': null,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
        'resolvedAt': null,
        'createdById': 'admin_1',
        'createdByName': 'Admin User',
      };

      final model = ComplaintModel.fromMap(map, 'comp_1');

      expect(model.id, 'comp_1');
      expect(model.customerId, 'cust_123');
      expect(model.customerName, 'Test Customer');
      expect(model.customerPhone, '03001234567');
      expect(model.type, ComplaintType.noConnection);
      expect(model.priority, ComplaintPriority.urgent);
      expect(model.status, ComplaintStatus.open);
      expect(model.description, 'Internet disconnected since morning');
      expect(model.assignedEmployeeId, 'emp_1');
      expect(model.assignedEmployeeName, 'John Tech');
      expect(model.createdAt, now);
      expect(model.updatedAt, now);
      expect(model.resolvedAt, isNull);
      expect(model.createdById, 'admin_1');
      expect(model.createdByName, 'Admin User');
      expect(model.isResolvedOrClosed, isFalse);
    });

    test('fromMap parses defensively with missing fields and unknown enums', () {
      final map = <String, dynamic>{
        'type': 'unknown_type',
        'priority': 'crazy_priority',
        'status': 'weird_status',
      };

      final model = ComplaintModel.fromMap(map, 'comp_2');

      expect(model.id, 'comp_2');
      expect(model.customerId, '');
      expect(model.customerName, '');
      expect(model.customerPhone, '');
      expect(model.type, ComplaintType.other); // safe default
      expect(model.priority, ComplaintPriority.medium); // safe default
      expect(model.status, ComplaintStatus.open); // safe default
      expect(model.description, '');
      expect(model.assignedEmployeeId, isNull);
      expect(model.createdAt, isNotNull);
    });

    test('toMap produces expected Firestore map', () {
      final now = DateTime(2026, 11, 12, 12, 0);
      final model = ComplaintModel(
        id: 'comp_3',
        customerId: 'cust_456',
        customerName: 'Alice',
        customerPhone: '03123456789',
        type: ComplaintType.slowSpeed,
        priority: ComplaintPriority.high,
        status: ComplaintStatus.resolved,
        description: 'Speed below 5Mbps',
        assignedEmployeeId: 'emp_2',
        assignedEmployeeName: 'Bob',
        resolutionNotes: 'Splice box optic power normalized',
        createdAt: now,
        updatedAt: now,
        resolvedAt: now,
        createdById: 'admin_1',
        createdByName: 'Admin',
      );

      final map = model.toMap();

      expect(map['customerId'], 'cust_456');
      expect(map['customerName'], 'Alice');
      expect(map['customerPhone'], '03123456789');
      expect(map['type'], 'slowSpeed');
      expect(map['priority'], 'high');
      expect(map['status'], 'resolved');
      expect(map['resolutionNotes'], 'Splice box optic power normalized');
      expect(map['resolvedAt'], isA<Timestamp>());
    });

    test('isResolvedOrClosed and ageInDays logic', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final complaint = ComplaintEntity(
        id: 'c1',
        customerId: 'c1',
        customerName: 'Cust',
        customerPhone: '123',
        type: ComplaintType.billing,
        priority: ComplaintPriority.low,
        status: ComplaintStatus.inProgress,
        description: 'Overcharged',
        createdAt: threeDaysAgo,
        updatedAt: threeDaysAgo,
      );

      expect(complaint.isResolvedOrClosed, isFalse);
      expect(complaint.ageInDays, greaterThanOrEqualTo(3));

      final resolvedComplaint = complaint.copyWith(status: ComplaintStatus.resolved);
      expect(resolvedComplaint.isResolvedOrClosed, isTrue);

      final closedComplaint = complaint.copyWith(status: ComplaintStatus.closed);
      expect(closedComplaint.isResolvedOrClosed, isTrue);
    });
  });
}

