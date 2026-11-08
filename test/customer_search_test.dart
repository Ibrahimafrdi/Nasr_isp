import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/features/customers/data/models/customer_model.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';

void main() {
  group('Customer Search by User ID Tests', () {
    final c1 = CustomerModel(
      id: 'cust-1',
      name: 'Ahmed Ali',
      userId: 'ahmed_isp_01',
      phone: '03001234567',
      cnic: '3520112345671',
      address: 'Street 1, Lahore',
      connectionType: 'fiber',
      monthlyBill: 1500,
      status: CustomerEntity.statusActive,
      notes: 'VIP customer',
    );

    final c2 = CustomerModel(
      id: 'cust-2',
      name: 'Bilal Khan',
      userId: 'bilal_ftth_99',
      phone: '03007654321',
      cnic: '3520198765432',
      address: 'Block B, Model Town',
      connectionType: 'wireless',
      monthlyBill: 2000,
      status: CustomerEntity.statusActive,
      notes: '',
    );

    final c3 = CustomerModel(
      id: 'cust-3',
      name: 'Usman Tariq',
      userId: null,
      phone: '03219998877',
      cnic: '3520111122334',
      address: 'Sector C, Bahria',
      connectionType: 'fiber',
      monthlyBill: 2500,
      status: CustomerEntity.statusActive,
      notes: '',
    );

    final customers = [c1, c2, c3];

    List<CustomerModel> filterBySearch(List<CustomerModel> list, String query) {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) return list;
      return list.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q) ||
            c.cnic.toLowerCase().contains(q) ||
            c.address.toLowerCase().contains(q) ||
            (c.userId != null && c.userId!.toLowerCase().contains(q));
      }).toList();
    }

    test('finds customer by exact user ID', () {
      final result = filterBySearch(customers, 'ahmed_isp_01');
      expect(result.length, 1);
      expect(result.first.name, 'Ahmed Ali');
    });

    test('finds customer by partial user ID (case-insensitive)', () {
      final result = filterBySearch(customers, 'BILAL_FTTH');
      expect(result.length, 1);
      expect(result.first.name, 'Bilal Khan');
    });

    test('gracefully handles customers with null userId', () {
      final result = filterBySearch(customers, 'non_existent_user');
      expect(result.isEmpty, true);
    });

    test('finds customer by name as well', () {
      final result = filterBySearch(customers, 'usman');
      expect(result.length, 1);
      expect(result.first.id, 'cust-3');
    });
  });
}

