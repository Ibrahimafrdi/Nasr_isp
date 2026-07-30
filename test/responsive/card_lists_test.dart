import 'package:flutter_test/flutter_test.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/features/customers/presentation/widgets/customer_card_list.dart';
import 'package:nasr_isp/features/employees/domain/entities/employee_entity.dart';
import 'package:nasr_isp/features/employees/presentation/widgets/employee_card_list.dart';
import 'package:nasr_isp/features/expenses/domain/entities/expense_entity.dart';
import 'package:nasr_isp/features/expenses/presentation/widgets/expense_card_list.dart';
import 'package:nasr_isp/features/installations/domain/entities/installation_entity.dart';
import 'package:nasr_isp/features/installations/presentation/widgets/installation_card_list.dart';
import 'package:nasr_isp/features/inventory/presentation/widgets/inventory_card_list.dart';
import 'package:nasr_isp/features/payments/presentation/widgets/payment_card_list.dart';
import 'package:nasr_isp/shared/models/models.dart';

import '../helpers/responsive_harness.dart';

/// Deliberately long, realistic values. Pakistani names run well past the
/// width these cards were originally laid out for, and it was exactly this
/// that overflowed the employee-name and "Paid by" rows.
const _longName = 'Muhammad Abdul Rehman Siddiqui Qureshi';
const _longDesignation = 'Senior Field Installation Technician (Fibre)';

EmployeeEntity _employee({String name = _longName}) => EmployeeEntity(
  id: 'e1',
  name: name,
  phone: '0300-1234567',
  email: 'abdul.rehman.siddiqui@nasrisp.example.com',
  address: 'House 42, Street 7, Gulshan-e-Iqbal Block 13-D, Karachi',
  designation: _longDesignation,
  sectorArea: 'Gulshan-e-Iqbal / Gulistan-e-Johar',
  status: EmployeeStatus.active,
  salary: 65000,
);

ExpenseEntity _expense({String paidBy = _longName}) => ExpenseEntity(
  id: 'x1',
  title: 'Replacement fibre splice enclosures for the Malir tower uplink',
  category: ExpenseCategory.equipment,
  amount: 187500,
  date: DateTime(2026, 7, 15),
  paidBy: paidBy,
  notes: 'Ordered against PO-2026-0184; delivered in two partial shipments.',
);

void main() {
  setUpAll(disableGoogleFontsFetching);

  testWidgets('EmployeeCardList survives long names at every width', (
    tester,
  ) async {
    for (final width in kTestWidths) {
      await pumpAtWidth(
        tester,
        EmployeeCardList(
          employees: [_employee()],
          installationCounts: const {'e1': 27},
          onViewDetail: (_) {},
          onEdit: (_) {},
          onToggleStatus: (_) {},
        ),
        width,
      );
      expectNoOverflow(tester, reason: 'EmployeeCardList at width $width');
    }
  });

  testWidgets('ExpenseCardList survives long payer names at every width', (
    tester,
  ) async {
    for (final width in kTestWidths) {
      await pumpAtWidth(
        tester,
        ExpenseCardList(
          expenses: [_expense()],
          isAdmin: true,
          onEdit: (_) {},
          onDelete: (_) {},
        ),
        width,
      );
      expectNoOverflow(tester, reason: 'ExpenseCardList at width $width');
    }
  });

  testWidgets('long employee name is ellipsised rather than clipped', (
    tester,
  ) async {
    await pumpAtWidth(
      tester,
      EmployeeCardList(
        employees: [_employee()],
        installationCounts: const {},
        onViewDetail: (_) {},
        onEdit: (_) {},
        onToggleStatus: (_) {},
      ),
      360,
    );
    expectNoOverflow(tester);

    final nameFinder = find.text(_longName);
    expect(nameFinder, findsOneWidget);
    // Must fit inside the 360dp viewport, not spill past it.
    expect(tester.getSize(nameFinder).width, lessThan(360));
  });

  testWidgets('expense card action row does not overflow a 320dp phone', (
    tester,
  ) async {
    await pumpAtWidth(
      tester,
      ExpenseCardList(
        expenses: [_expense()],
        isAdmin: true,
        onEdit: (_) {},
        onDelete: (_) {},
      ),
      320,
    );
    expectNoOverflow(tester);
  });

  testWidgets('CustomerCardList survives long values at every width', (
    tester,
  ) async {
    final customer = CustomerModel(
      id: 'c1',
      name: _longName,
      phone: '0300-1234567',
      cnic: '42101-1234567-8',
      address: 'House 42, Street 7, Gulshan-e-Iqbal Block 13-D, Karachi',
      connectionType: 'Optical Fibre',
      packageId: 'p1',
      monthlyBill: 3500,
      status: 'active',
      notes: '',
      nextDueDate: DateTime(2026, 8, 5),
    );

    for (final width in kTestWidths) {
      await pumpAtWidth(
        tester,
        CustomerCardList(
          customers: [customer],
          currentUser: const UserModel(
            id: 'u1',
            email: 'admin@nasr.com',
            role: 'admin',
            name: 'Admin',
            phone: '0300-0000000',
          ),
          getPackageName: (_) => 'Fibre Unlimited 50 Mbps Residential',
          onDelete: (_) {},
        ),
        width,
      );
      expectNoOverflow(tester, reason: 'CustomerCardList at width $width');
    }
  });

  testWidgets('PaymentCardList survives long values at every width', (
    tester,
  ) async {
    final payment = PaymentModel(
      id: 'p1',
      customerId: 'c1',
      customerName: _longName,
      amount: 3500,
      paidAmount: 1200,
      status: 'partial',
      dueDate: DateTime(2026, 8, 5),
      method: 'Bank Transfer (Meezan)',
      billingMonth: '2026-08',
    );

    for (final width in kTestWidths) {
      await pumpAtWidth(
        tester,
        PaymentCardList(
          payments: [payment],
          isAdmin: true,
          onRecordPayment: (_) {},
        ),
        width,
      );
      expectNoOverflow(tester, reason: 'PaymentCardList at width $width');
    }
  });

  testWidgets('InstallationCardList survives long values at every width', (
    tester,
  ) async {
    final installation = InstallationEntity(
      id: 'i1',
      customerId: 'c1',
      customerName: _longName,
      connectionType: ConnectionType.opticalFibre,
      installationDate: DateTime(2026, 7, 20),
      assignedEmployeeName: 'Muhammad Abdul Rehman Siddiqui',
      installationCost: 12500,
      status: InstallationStatus.inProgress,
      remarks: 'Requires a second drop cable run along the rear boundary wall.',
      createdAt: DateTime(2026, 7, 18),
    );

    for (final width in kTestWidths) {
      await pumpAtWidth(
        tester,
        InstallationCardList(
          installations: [installation],
          isAdmin: true,
          onEdit: (_) {},
          onDelete: (_) {},
        ),
        width,
      );
      expectNoOverflow(tester, reason: 'InstallationCardList at width $width');
    }
  });

  testWidgets('InventoryCardList survives long values at every width', (
    tester,
  ) async {
    const item = InventoryItemEntity(
      id: 'inv1',
      name: 'Single-mode fibre splice enclosure, 24-core, outdoor rated',
      category: InventoryCategory.equipment,
      unit: 'pcs',
      quantityInStock: 4,
      reorderLevel: 10,
      unitCost: 8750,
      sellPrice: 11000,
      supplier: 'Karachi Fibre Optics Trading Company (Pvt) Ltd',
      connectionType: InventoryConnectionType.opticalFibre,
    );

    for (final width in kTestWidths) {
      await pumpAtWidth(
        tester,
        InventoryCardList(
          items: const [item],
          categoryLabel: (c) =>
              c == InventoryCategory.equipment ? 'Equipment' : 'Consumable',
          onViewDetail: (_) {},
          onAdjustStock: (_) {},
          onEdit: (_) {},
          onDelete: (_) {},
        ),
        width,
      );
      expectNoOverflow(tester, reason: 'InventoryCardList at width $width');
    }
  });
}
