import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_purchase_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/usecases/add_supplier_payment.dart';
import 'package:nasr_isp/shared/widgets/adaptive_form_dialog.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class AddSupplierPaymentDialog extends StatefulWidget {
  final String supplierId;
  final List<SupplierPurchaseEntity> pendingPurchases;
  final SupplierPurchaseEntity? initialPurchase;

  const AddSupplierPaymentDialog({
    super.key,
    required this.supplierId,
    required this.pendingPurchases,
    this.initialPurchase,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String supplierId,
    required List<SupplierPurchaseEntity> pendingPurchases,
    SupplierPurchaseEntity? initialPurchase,
  }) {
    return showAppFormDialog<bool>(
      context: context,
      builder: (context) => AddSupplierPaymentDialog(
        supplierId: supplierId,
        pendingPurchases: pendingPurchases,
        initialPurchase: initialPurchase,
      ),
    );
  }

  @override
  State<AddSupplierPaymentDialog> createState() =>
      _AddSupplierPaymentDialogState();
}

class _AddSupplierPaymentDialogState extends State<AddSupplierPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  SupplierPurchaseEntity? _selectedPurchase;
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  PaymentMethod _selectedMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();

    if (widget.initialPurchase != null) {
      _selectedPurchase = widget.initialPurchase;
      _amountController.text = _selectedPurchase!.remainingAmount
          .toStringAsFixed(0);
    } else if (widget.pendingPurchases.isNotEmpty) {
      _selectedPurchase = widget.pendingPurchases.first;
      _amountController.text = _selectedPurchase!.remainingAmount
          .toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onPurchaseSelected(SupplierPurchaseEntity? purchase) {
    setState(() {
      _selectedPurchase = purchase;
      if (purchase != null) {
        _amountController.text = purchase.remainingAmount.toStringAsFixed(0);
      }
    });
  }

  Future<void> _handleSave() async {
    if (_selectedPurchase == null) {
      setState(() => _errorMessage = 'Please select a purchase to settle.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Amount must be greater than zero.');
      return;
    }

    if (amount > _selectedPurchase!.remainingAmount + 0.0001) {
      setState(
        () => _errorMessage =
            'Payment exceeds remaining purchase balance (Rs. ${_selectedPurchase!.remainingAmount.toStringAsFixed(0)}).',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final addPayment = getIt<AddSupplierPayment>();
      await addPayment(
        supplierId: widget.supplierId,
        purchaseId: _selectedPurchase!.id,
        amount: amount,
        method: _selectedMethod,
        date: _selectedDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,##0', 'en_US');

    return AdaptiveFormDialog(
      title: 'Record Supplier Payment',
      canClose: !_isSaving,
      onClose: () => Navigator.of(context).pop(),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save Payment'),
        ),
      ],
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.errorColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Purchase Selector
            const Text(
              'Select Purchase / Invoice',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            if (widget.pendingPurchases.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.successColor.withValues(alpha: 0.2),
                  ),
                ),
                child: const Text(
                  'No pending purchases found for this supplier.',
                  style: TextStyle(fontSize: 13, color: AppTheme.successColor),
                ),
              )
            else
              DropdownButtonFormField<SupplierPurchaseEntity>(
                value: _selectedPurchase,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: widget.pendingPurchases.map((p) {
                  final invText = p.invoiceNo != null && p.invoiceNo!.isNotEmpty
                      ? ' (Inv: ${p.invoiceNo})'
                      : '';
                  final dateText = p.date != null
                      ? DateFormat('dd MMM').format(p.date!)
                      : '';
                  return DropdownMenuItem(
                    value: p,
                    child: Text(
                      '${p.itemName}$invText · Rem: Rs. ${currencyFormat.format(p.remainingAmount)} $dateText',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: _isSaving ? null : _onPurchaseSelected,
              ),

            if (_selectedPurchase != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightGray.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Billed: Rs. ${currencyFormat.format(_selectedPurchase!.totalAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.darkGray,
                      ),
                    ),
                    Text(
                      'Remaining: Rs. ${currencyFormat.format(_selectedPurchase!.remainingAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            AppFormField(
              label: 'Payment Amount (Rs.)',
              controller: _amountController,
              hintText: 'e.g. 5000',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              isRequired: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Amount is required';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid positive amount';
                if (_selectedPurchase != null &&
                    n > _selectedPurchase!.remainingAmount + 0.0001) {
                  return 'Cannot exceed remaining balance (Rs. ${_selectedPurchase!.remainingAmount.toStringAsFixed(0)})';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),
            const Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<PaymentMethod>(
              value: _selectedMethod,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: PaymentMethod.values.map((m) {
                return DropdownMenuItem(
                  value: m,
                  child: Text(
                    m.displayName,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: _isSaving
                  ? null
                  : (val) => setState(
                      () => _selectedMethod = val ?? PaymentMethod.cash,
                    ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Payment Date',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _isSaving
                  ? null
                  : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.mediumGray.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppTheme.darkGray,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            AppFormField(
              label: 'Notes (Optional)',
              controller: _notesController,
              hintText: 'Cheque no, transaction ID, or payment slip details',
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
