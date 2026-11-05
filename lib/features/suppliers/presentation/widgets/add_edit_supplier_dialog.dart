import 'package:flutter/material.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:nasr_isp/features/suppliers/domain/usecases/add_supplier.dart';
import 'package:nasr_isp/features/suppliers/domain/usecases/update_supplier.dart';
import 'package:nasr_isp/shared/widgets/adaptive_form_dialog.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class AddEditSupplierDialog extends StatefulWidget {
  final SupplierEntity? supplier;

  const AddEditSupplierDialog({super.key, this.supplier});

  static Future<String?> show(
    BuildContext context, {
    SupplierEntity? supplier,
  }) {
    return showAppFormDialog<String>(
      context: context,
      builder: (context) => AddEditSupplierDialog(supplier: supplier),
    );
  }

  @override
  State<AddEditSupplierDialog> createState() => _AddEditSupplierDialogState();
}

class _AddEditSupplierDialogState extends State<AddEditSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  bool _isActive = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _nameController = TextEditingController(text: s?.name ?? '');
    _phoneController = TextEditingController(text: s?.phone ?? '');
    _addressController = TextEditingController(text: s?.address ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (widget.supplier == null) {
        final newSupplier = SupplierEntity(
          id: '',
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          isActive: true,
          totalPurchased: 0.0,
          totalPaid: 0.0,
          pendingBalance: 0.0,
          createdAt: DateTime.now(),
        );

        final addUseCase = getIt<AddSupplier>();
        final newId = await addUseCase(newSupplier);

        if (mounted) {
          Navigator.of(context).pop(newId);
        }
      } else {
        final updatedSupplier = SupplierEntity(
          id: widget.supplier!.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          isActive: _isActive,
          totalPurchased: widget.supplier!.totalPurchased,
          totalPaid: widget.supplier!.totalPaid,
          pendingBalance: widget.supplier!.pendingBalance,
          createdAt: widget.supplier!.createdAt,
        );

        final updateUseCase = getIt<UpdateSupplier>();
        await updateUseCase(updatedSupplier);

        if (mounted) {
          Navigator.of(context).pop(widget.supplier!.id);
        }
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
    final isEditing = widget.supplier != null;
    final title = isEditing ? 'Edit Supplier' : 'Add Supplier';

    return AdaptiveFormDialog(
      title: title,
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
              : Text(isEditing ? 'Save Changes' : 'Add Supplier'),
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
            AppFormField(
              label: 'Supplier Name',
              controller: _nameController,
              hintText: 'e.g. Huawei Devices Pakistan',
              isRequired: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Supplier name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppFormField(
              label: 'Phone Number',
              controller: _phoneController,
              hintText: 'e.g. 03001234567',
              keyboardType: TextInputType.phone,
              isRequired: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppFormField(
              label: 'Address (Optional)',
              controller: _addressController,
              hintText: 'Office / Warehouse address',
            ),
            const SizedBox(height: 16),
            AppFormField(
              label: 'Notes (Optional)',
              controller: _notesController,
              hintText: 'Bank details, contacts, or agreements',
              maxLines: 2,
            ),
            if (isEditing) ...[
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active Supplier'),
                subtitle: Text(
                  _isActive
                      ? 'Available for new purchase orders'
                      : 'Inactive / Hidden from new orders',
                  style: const TextStyle(fontSize: 12),
                ),
                value: _isActive,
                onChanged: _isSaving
                    ? null
                    : (val) => setState(() => _isActive = val),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
