import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/packages/domain/entities/package_entity.dart';

void main() {
  group('Customer Profit Calculation Tests', () {
    test('calculateProfit correctly calculates monthlyBill - package.costPrice', () {
      final now = DateTime.now();
      const customer = CustomerEntity(
        id: 'cust_1',
        name: 'Test Customer',
        phone: '03001234567',
        cnic: '12345-6789012-3',
        address: 'Test Address',
        connectionType: 'fiber',
        packageId: 'wAlK3UX93H76ROODPYoL',
        monthlyBill: 3000.0,
        status: 'active',
        notes: '',
      );

      final package = PackageEntity(
        id: 'wAlK3UX93H76ROODPYoL',
        name: 'Fiber 20 Mbps',
        speedMbps: 20,
        price: 3000.0,
        costPrice: 941.0,
        connectionType: ConnectionType.opticalFibre,
        description: null,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final profit = customer.calculateProfit(package);
      expect(profit, 2059.0);
    });

    test('calculateProfit handles null package safely without crashing', () {
      const customer = CustomerEntity(
        id: 'cust_2',
        name: 'No Package Customer',
        phone: '03007654321',
        cnic: '12345-6789012-4',
        address: 'Test Address',
        connectionType: 'wireless',
        packageId: null,
        monthlyBill: 3000.0,
        status: 'active',
        notes: '',
      );

      final profit = customer.calculateProfit(null);
      expect(profit, 3000.0);
    });
  });
}
