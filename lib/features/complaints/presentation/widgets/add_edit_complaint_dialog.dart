import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';
import 'package:uuid/uuid.dart';

class AddEditComplaintDialog extends StatefulWidget {
  final ComplaintEntity? existingComplaint;
  final bool isAdmin;
  final String? currentUserId;
  final String? currentUserName;
  final List<CustomerEntity> allCustomers;
  final List<Map<String, dynamic>> employeesList;
  final Future<void> Function(ComplaintEntity complaint) onSave;

  const AddEditComplaintDialog({
    super.key,
    this.existingComplaint,
    required this.isAdmin,
    this.currentUserId,
    this.currentUserName,
    required this.allCustomers,
    required this.employeesList,
    required this.onSave,
  });

  @override
  State<AddEditComplaintDialog> createState() => _AddEditComplaintDialogState();
}

class _AddEditComplaintDialogState extends State<AddEditComplaintDialog> {
  final _formKey = GlobalKey<FormState>();

  CustomerEntity? _selectedCustomer;
  late TextEditingController _customerSearchController;
  late TextEditingController _descriptionController;
  late TextEditingController _resolutionNotesController;

  late ComplaintType _type;
  late ComplaintPriority _priority;
  late ComplaintStatus _status;
  String? _assignedEmployeeId;
  String? _assignedEmployeeName;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingComplaint;

    _customerSearchController = TextEditingController(
      text: existing?.customerName ?? '',
    );
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _resolutionNotesController = TextEditingController(
      text: existing?.resolutionNotes ?? '',
    );

    _type = existing?.type ?? ComplaintType.noConnection;
    _priority = existing?.priority ?? ComplaintPriority.medium;
    _status = existing?.status ?? ComplaintStatus.open;
    _assignedEmployeeId = existing?.assignedEmployeeId;
    _assignedEmployeeName = existing?.assignedEmployeeName;

    if (existing != null) {
      final matches = widget.allCustomers
          .where((c) => c.id == existing.customerId)
          .toList();
      if (matches.isNotEmpty) {
        _selectedCustomer = matches.first;
      }
    }
  }

  @override
  void dispose() {
    _customerSearchController.dispose();
    _descriptionController.dispose();
    _resolutionNotesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.existingComplaint == null && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer from the search options'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final isResolvedOrClosed =
        _status == ComplaintStatus.resolved || _status == ComplaintStatus.closed;
    final notes = _resolutionNotesController.text.trim();
    if (isResolvedOrClosed && notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Resolution notes are required when setting status to Resolved or Closed',
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final existing = widget.existingComplaint;

      final customerId =
          _selectedCustomer?.id ?? existing?.customerId ?? '';
      final customerName =
          _selectedCustomer?.name ?? existing?.customerName ?? '';
      final customerPhone =
          _selectedCustomer?.phone ?? existing?.customerPhone ?? '';

      DateTime? resolvedAt;
      if (isResolvedOrClosed) {
        resolvedAt = existing?.resolvedAt ?? now;
      } else {
        resolvedAt = null;
      }

      final ComplaintEntity entity = existing == null
          ? ComplaintEntity(
              id: const Uuid().v4(),
              customerId: customerId,
              customerName: customerName,
              customerPhone: customerPhone,
              type: _type,
              priority: _priority,
              status: _status,
              description: _descriptionController.text.trim(),
              assignedEmployeeId: _assignedEmployeeId,
              assignedEmployeeName: _assignedEmployeeName,
              resolutionNotes: notes.isNotEmpty ? notes : null,
              createdAt: now,
              updatedAt: now,
              resolvedAt: resolvedAt,
              createdById: widget.currentUserId,
              createdByName: widget.currentUserName,
            )
          : existing.copyWith(
              customerId: customerId,
              customerName: customerName,
              customerPhone: customerPhone,
              type: widget.isAdmin ? _type : existing.type,
              priority: widget.isAdmin ? _priority : existing.priority,
              status: _status,
              description: widget.isAdmin
                  ? _descriptionController.text.trim()
                  : existing.description,
              assignedEmployeeId: widget.isAdmin
                  ? _assignedEmployeeId
                  : existing.assignedEmployeeId,
              assignedEmployeeName: widget.isAdmin
                  ? _assignedEmployeeName
                  : existing.assignedEmployeeName,
              resolutionNotes: notes.isNotEmpty ? notes : null,
              updatedAt: now,
              resolvedAt: resolvedAt,
            );

      await widget.onSave(entity);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save complaint: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingComplaint != null;
    final canReassign = widget.isAdmin;
    final canEditDetails = widget.isAdmin || !isEdit;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Support Ticket' : 'Create Support Ticket',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF14213D),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (!isEdit) ...[
                  // Customer autocomplete
                  Autocomplete<CustomerEntity>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return widget.allCustomers;
                      }
                      final query =
                          textEditingValue.text.trim().toLowerCase();
                      return widget.allCustomers.where((CustomerEntity c) {
                        final name = c.name.toLowerCase();
                        final phone = c.phone.toLowerCase();
                        final uid = (c.userId ?? '').toLowerCase();
                        final cnic = c.cnic.toLowerCase();
                        return name.contains(query) ||
                            uid.contains(query) ||
                            phone.contains(query) ||
                            cnic.contains(query);
                      });
                    },
                    displayStringForOption: (CustomerEntity option) =>
                        (option.userId != null && option.userId!.isNotEmpty)
                            ? '${option.name} (${option.userId}) - ${option.phone}'
                            : '${option.name} - ${option.phone}',
                    fieldViewBuilder:
                        (context, textController, focusNode, onFieldSubmitted) {
                      if (textController.text.isEmpty &&
                          _customerSearchController.text.isNotEmpty) {
                        textController.text = _customerSearchController.text;
                      }
                      return TextFormField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Search Customer *',
                          hintText: 'Type Name, Phone or User ID...',
                          prefixIcon: Icon(Icons.search, size: 20),
                        ),
                        validator: (v) {
                          if (_selectedCustomer == null) {
                            return 'Please select a subscriber from suggestions';
                          }
                          return null;
                        },
                      );
                    },
                    onSelected: (CustomerEntity selection) {
                      setState(() {
                        _selectedCustomer = selection;
                        _customerSearchController.text = selection.name;
                      });
                    },
                  ),
                  if (_selectedCustomer != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: Color(0xFF5B6472),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Phone: ${_selectedCustomer!.phone.isNotEmpty ? _selectedCustomer!.phone : "N/A"}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF14213D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ] else ...[
                  // Readonly customer display in edit mode
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer: ${widget.existingComplaint!.customerName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF14213D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phone: ${widget.existingComplaint!.customerPhone.isNotEmpty ? widget.existingComplaint!.customerPhone : "N/A"}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5B6472),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ComplaintType>(
                        value: _type,
                        decoration: const InputDecoration(labelText: 'Type *'),
                        items: ComplaintType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.label),
                              ),
                            )
                            .toList(),
                        onChanged: canEditDetails
                            ? (val) {
                                if (val != null) setState(() => _type = val);
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<ComplaintPriority>(
                        value: _priority,
                        decoration:
                            const InputDecoration(labelText: 'Priority *'),
                        items: ComplaintPriority.values
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.label),
                              ),
                            )
                            .toList(),
                        onChanged: canEditDetails
                            ? (val) {
                                if (val != null) setState(() => _priority = val);
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isEdit) ...[
                  DropdownButtonFormField<ComplaintStatus>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status *'),
                    items: ComplaintStatus.values
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _status = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (canReassign || !isEdit) ...[
                  DropdownButtonFormField<String?>(
                    value: _assignedEmployeeId,
                    decoration: const InputDecoration(
                      labelText: 'Assign To (Technician/Staff)',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...widget.employeesList.map(
                        (e) => DropdownMenuItem(
                          value: e['id'] as String,
                          child: Text(e['name'] as String),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _assignedEmployeeId = val;
                        if (val != null) {
                          final match = widget.employeesList
                              .firstWhere((e) => e['id'] == val);
                          _assignedEmployeeName = match['name'] as String;
                        } else {
                          _assignedEmployeeName = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Read-only assignee display for non-admin in edit mode
                  TextFormField(
                    initialValue: _assignedEmployeeName ?? 'Unassigned',
                    decoration: const InputDecoration(
                      labelText: 'Assigned Technician',
                    ),
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Complaint Description *',
                    hintText: 'Describe the problem in detail...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                  enabled: canEditDetails,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (isEdit || _status == ComplaintStatus.resolved || _status == ComplaintStatus.closed) ...[
                  TextFormField(
                    controller: _resolutionNotesController,
                    decoration: InputDecoration(
                      labelText: (_status == ComplaintStatus.resolved ||
                              _status == ComplaintStatus.closed)
                          ? 'Resolution Notes *'
                          : 'Resolution Notes',
                      hintText:
                          'Explain how the issue was resolved or current progress...',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    validator: (v) {
                      final isResolved = _status == ComplaintStatus.resolved ||
                          _status == ComplaintStatus.closed;
                      if (isResolved && (v == null || v.trim().isEmpty)) {
                        return 'Resolution notes are required when status is Resolved or Closed';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEdit ? 'Update Ticket' : 'Save Ticket'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

