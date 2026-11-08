import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_purchase_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/usecases/add_supplier_payment.dart';
import 'package:nasr_isp/features/suppliers/domain/usecases/pay_supplier_dues.dart';
import 'package:nasr_isp/features/suppliers/domain/utils/supplier_payment_allocator.dart';
import 'package:nasr_isp/shared/widgets/adaptive_form_dialog.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

/// "All dues" pays against the supplier's whole outstanding balance and the
/// amount is applied to the oldest unpaid invoices first. "One invoice" pays a
/// single chosen invoice (used by the per-invoice "Pay Due" button).
enum _PayMode { allDues, singleInvoice }

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
  final _currencyFormat = NumberFormat('#,##0', 'en_US');

  late final TextEditingController _amountController;
  late final TextEditingController _notesController;

  late _PayMode _mode;
  SupplierPurchaseEntity? _selectedPurchase;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  String? _errorMessage;

  /// Unpaid invoices, oldest first.
  late final List<SupplierPurchaseEntity> _payable;
  late final double _totalDue;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();

    _payable = SupplierPaymentAllocator.payable(widget.pendingPurchases);
    _totalDue = SupplierPaymentAllocator.totalDue(widget.pendingPurchases);

    if (widget.initialPurchase != null) {
      _mode = _PayMode.singleInvoice;
      _selectedPurchase = widget.initialPurchase;
    } else {
      _mode = _PayMode.allDues;
      _selectedPurchase = _payable.isNotEmpty ? _payable.first : null;
    }
    _resetAmount();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _maxAmount => _mode == _PayMode.allDues
      ? _totalDue
      : (_selectedPurchase?.remainingAmount ?? 0.0);

  void _resetAmount() {
    _amountController.text = _maxAmount > 0
        ? _maxAmount.toStringAsFixed(0)
        : '';
  }

  void _onModeChanged(_PayMode mode) {
    if (_isSaving || mode == _mode) return;
    setState(() {
      _mode = mode;
      _errorMessage = null;
      if (mode == _PayMode.singleInvoice && _selectedPurchase == null) {
        _selectedPurchase = _payable.isNotEmpty ? _payable.first : null;
      }
      _resetAmount();
    });
  }

  void _onPurchaseSelected(SupplierPurchaseEntity? purchase) {
    setState(() {
      _selectedPurchase = purchase;
      _errorMessage = null;
      _resetAmount();
    });
  }

  String _purchaseLabel(SupplierPurchaseEntity p) {
    final inv = p.invoiceNo != null && p.invoiceNo!.isNotEmpty
        ? ' (Inv: ${p.invoiceNo})'
        : '';
    final date = p.date != null
        ? ' · ${DateFormat('dd MMM').format(p.date!)}'
        : '';
    return '${p.itemName}$inv$date';
  }

  Future<void> _handleSave() async {
    if (_payable.isEmpty) {
      setState(() => _errorMessage = 'This supplier has no pending purchases.');
      return;
    }
    if (_mode == _PayMode.singleInvoice && _selectedPurchase == null) {
      setState(() => _errorMessage = 'Please select a purchase to settle.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Amount must be greater than zero.');
      return;
    }
    if (amount > _maxAmount + 0.0001) {
      setState(
        () => _errorMessage =
            'Payment exceeds the pending balance (Rs. ${_maxAmount.toStringAsFixed(0)}).',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    try {
      if (_mode == _PayMode.allDues) {
        await getIt<PaySupplierDues>()(
          supplierId: widget.supplierId,
          amount: amount,
          method: _selectedMethod,
          date: _selectedDate,
          notes: notes,
        );
      } else {
        await getIt<AddSupplierPayment>()(
          supplierId: widget.supplierId,
          purchaseId: _selectedPurchase!.id,
          amount: amount,
          method: _selectedMethod,
          date: _selectedDate,
          notes: notes,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Widget _buildModeToggle() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_PayMode>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(
            value: _PayMode.allDues,
            label: Text('All dues'),
            icon: Icon(Icons.account_balance_wallet_outlined, size: 16),
          ),
          ButtonSegment(
            value: _PayMode.singleInvoice,
            label: Text('One invoice'),
            icon: Icon(Icons.receipt_long_outlined, size: 16),
          ),
        ],
        selected: {_mode},
        onSelectionChanged: (s) => _onModeChanged(s.first),
      ),
    );
  }

  Widget _buildSummaryBar(String leftText, String rightText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              leftText,
              style: const TextStyle(fontSize: 12, color: AppTheme.darkGray),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rightText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.warningColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows which invoices the typed amount will be applied to.
  Widget _buildAllocationPreview() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) return const SizedBox.shrink();

    final capped = amount > _totalDue ? _totalDue : amount;
    final allocations = SupplierPaymentAllocator.allocate(_payable, capped);
    if (allocations.isEmpty) return const SizedBox.shrink();

    final byId = {for (final p in _payable) p.id: p};

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How this payment will be applied (oldest first)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (final a in allocations)
            Builder(
              builder: (context) {
                final p = byId[a.purchaseId]!;
                final clears = a.amount >= p.remainingAmount - 0.0001;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _purchaseLabel(p),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Rs. ${_currencyFormat.format(a.amount)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        clears ? 'Cleared' : 'Partial',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: clears
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: _isSaving || _payable.isEmpty ? null : _handleSave,
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

            if (_payable.isEmpty)
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
            else ...[
              _buildModeToggle(),
              const SizedBox(height: 14),

              if (_mode == _PayMode.allDues)
                _buildSummaryBar(
                  'Pending across ${_payable.length} '
                      '${_payable.length == 1 ? 'invoice' : 'invoices'}',
                  'Total due: Rs. ${_currencyFormat.format(_totalDue)}',
                )
              else ...[
                const Text(
                  'Select Purchase / Invoice',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<SupplierPurchaseEntity>(
                  isExpanded: true,
                  value: _payable.contains(_selectedPurchase)
                      ? _selectedPurchase
                      : (_payable.isNotEmpty ? _payable.first : null),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: _payable.map((p) {
                    return DropdownMenuItem(
                      value: p,
                      child: Text(
                        '${_purchaseLabel(p)} · Rem: Rs. ${_currencyFormat.format(p.remainingAmount)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: _isSaving ? null : _onPurchaseSelected,
                ),
                if (_selectedPurchase != null) ...[
                  const SizedBox(height: 12),
                  _buildSummaryBar(
                    'Total Billed: Rs. ${_currencyFormat.format(_selectedPurchase!.totalAmount)}',
                    'Remaining: Rs. ${_currencyFormat.format(_selectedPurchase!.remainingAmount)}',
                  ),
                ],
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
                onChanged: (_) => setState(() => _errorMessage = null),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) {
                    return 'Enter a valid positive amount';
                  }
                  if (n > _maxAmount + 0.0001) {
                    return 'Cannot exceed pending balance (Rs. ${_maxAmount.toStringAsFixed(0)})';
                  }
                  return null;
                },
              ),

              if (_mode == _PayMode.allDues) _buildAllocationPreview(),
            ],

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
