import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/finance/subscriber_margin.dart';
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

  group('Customer monthlyMargin cost basis', () {
    PackageEntity package() {
      final now = DateTime.now();
      return PackageEntity(
        id: 'pkg_1',
        name: 'Fiber 20 Mbps',
        speedMbps: 20,
        price: 3000.0,
        costPrice: 941.0,
        connectionType: ConnectionType.opticalFibre,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
    }

    CustomerEntity customer({String? packageId}) => CustomerEntity(
          id: 'cust_1',
          name: 'Test Customer',
          phone: '03001234567',
          cnic: '12345-6789012-3',
          address: 'Test Address',
          connectionType: 'fiber',
          packageId: packageId,
          monthlyBill: 3000.0,
          status: 'active',
          notes: '',
        );

    test('reports packageKnown when the package resolves', () {
      final margin = customer(packageId: 'pkg_1').monthlyMargin(package());

      expect(margin.basis, SubscriberCostBasis.packageKnown);
      expect(margin.isReliable, isTrue);
      expect(margin.money.profit, 2059.0);
    });

    test('reports noPackageAssigned when packageId is null', () {
      final margin = customer().monthlyMargin(null);

      expect(margin.basis, SubscriberCostBasis.noPackageAssigned);
      expect(margin.isPackageMissing, isFalse);
    });

    test('treats an empty-string packageId as no package assigned', () {
      final margin = customer(packageId: '').monthlyMargin(null);

      expect(margin.basis, SubscriberCostBasis.noPackageAssigned);
    });

    test('reports packageCostMissing when the package has no cost price', () {
      // A package document written before buy/sell pricing existed defaults to
      // costPrice 0. Treated as unknown, not free — otherwise the customer's
      // whole bill is reported as profit by a package that looks legitimate.
      final zeroCost = PackageEntity(
        id: 'pkg_1',
        name: 'Fiber 20 Mbps',
        speedMbps: 20,
        price: 3000.0,
        costPrice: 0.0,
        connectionType: ConnectionType.opticalFibre,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final margin = customer(packageId: 'pkg_1').monthlyMargin(zeroCost);

      expect(margin.basis, SubscriberCostBasis.packageCostMissing);
      expect(margin.isReliable, isFalse);
      expect(margin.isPackageMissing, isTrue);
      expect(margin.money.profit, 3000.0); // the full bill — now flagged
    });

    test('reports packageUnresolved when a set packageId does not resolve', () {
      // The silent-100%-margin case: a deleted package used to be
      // indistinguishable from a customer with no package at all.
      final margin = customer(packageId: 'deleted_pkg').monthlyMargin(null);

      expect(margin.basis, SubscriberCostBasis.packageUnresolved);
      expect(margin.isPackageMissing, isTrue);
      expect(margin.money.profit, 3000.0);
    });

    test('calculateProfit returns the same number as monthlyMargin', () {
      final c = customer(packageId: 'pkg_1');

      expect(c.calculateProfit(package()), c.monthlyMargin(package()).money.profit);
    });
  });
}
