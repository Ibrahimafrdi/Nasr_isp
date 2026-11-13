import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nasr_isp/config/service_locator.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/core/utils/whatsapp_launcher.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/features/customers/domain/entities/customer_entity.dart';
import 'package:nasr_isp/features/customers/domain/usecases/get_customers.dart';
import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';
import 'package:nasr_isp/features/complaints/presentation/bloc/complaint_bloc.dart';
import 'package:nasr_isp/features/complaints/presentation/widgets/add_edit_complaint_dialog.dart';
import 'package:nasr_isp/features/complaints/presentation/widgets/complaint_card_list.dart';
import 'package:nasr_isp/features/complaints/presentation/widgets/complaint_filter_panel.dart';
import 'package:nasr_isp/features/complaints/presentation/widgets/complaint_metric_cards.dart';
import 'package:nasr_isp/shared/utils/responsive.dart';

class ComplaintsPage extends StatefulWidget {
  const ComplaintsPage({super.key});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  late TextEditingController _searchController;

  String? _selectedStatus;
  String? _selectedPriority;
  String? _selectedType;
  String? _selectedEmployeeId;
  bool _mineOnly = false;

  List<CustomerEntity> _allCustomers = [];
  List<Map<String, dynamic>> _employeesList = [];
  bool _isLoadingDropdowns = true;

  ComplaintLoaded? _lastLoaded;

  static const _ink = Color(0xFF14213D);
  static const _muted = Color(0xFF5B6472);
  static const _line = Color(0xFFE3E6EB);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadDropdownData();
    _triggerLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    List<CustomerEntity> customers = _allCustomers;
    try {
      customers = await getIt<GetCustomers>()();
    } catch (_) {}

    // Assignees must be LOGIN accounts: the complaint stores this id and the
    // employee's rules and queries match it against their Firebase Auth uid.
    // Only admins can list `users`, and only admins assign, so a permission
    // error for an employee is expected and harmless.
    var employees = <Map<String, dynamic>>[];
    try {
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .get();
      employees = usersSnap.docs
          .where((doc) {
            final data = doc.data();
            final role = (data['role'] as String? ?? '').toLowerCase();
            final active = data['isActive'] as bool? ?? true;
            return role == 'employee' && active;
          })
          .map(
            (doc) => {
              'id': doc.id,
              'name': doc.data()['name'] as String? ?? 'Unnamed',
            },
          )
          .toList();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _allCustomers = customers;
        _employeesList = employees;
        _isLoadingDropdowns = false;
      });
    }
  }

  void _triggerLoad() {
    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : null;

    context.read<ComplaintBloc>().add(
      LoadComplaintsEvent(
        status: _selectedStatus,
        priority: _selectedPriority,
        type: _selectedType,
        employeeId: _selectedEmployeeId,
        currentUserId: currentUserId,
        isAdmin: isAdmin,
        mineOnly: _mineOnly,
        searchQuery: _searchController.text.trim(),
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedStatus != null) count++;
    if (_selectedPriority != null) count++;
    if (_selectedType != null) count++;
    if (_selectedEmployeeId != null) count++;
    if (_mineOnly) count++;
    return count;
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedPriority = null;
      _selectedType = null;
      _selectedEmployeeId = null;
      _mineOnly = false;
      _searchController.clear();
    });
    _triggerLoad();
  }

  void _openAddEditDialog([ComplaintEntity? existing]) {
    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : null;
    final currentUserName = authState is AuthAuthenticated
        ? authState.user.name
        : null;

    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEditComplaintDialog(
        existingComplaint: existing,
        isAdmin: isAdmin,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
        allCustomers: _allCustomers,
        employeesList: _employeesList,
        onSave: (entity) async {
          final bloc = context.read<ComplaintBloc>();
          if (existing == null) {
            bloc.add(
              CreateComplaintEvent(
                entity,
                status: _selectedStatus,
                priority: _selectedPriority,
                type: _selectedType,
                employeeId: _selectedEmployeeId,
                currentUserId: currentUserId,
                isAdmin: isAdmin,
                mineOnly: _mineOnly,
                searchQuery: _searchController.text.trim(),
              ),
            );
          } else {
            bloc.add(
              UpdateComplaintEvent(
                entity,
                status: _selectedStatus,
                priority: _selectedPriority,
                type: _selectedType,
                employeeId: _selectedEmployeeId,
                currentUserId: currentUserId,
                isAdmin: isAdmin,
                mineOnly: _mineOnly,
                searchQuery: _searchController.text.trim(),
              ),
            );
          }

          final result = await bloc.stream.firstWhere(
            (s) => s is ComplaintLoaded || s is ComplaintError,
          );

          if (result is ComplaintError) {
            throw Exception(result.message);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  existing == null
                      ? 'Complaint ticket created successfully'
                      : 'Complaint ticket updated successfully',
                ),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(ComplaintEntity complaint) {
    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Complaint Ticket'),
        content: Text(
          'Are you sure you want to permanently delete ticket for ${complaint.customerName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            onPressed: () {
              Navigator.pop(dCtx);
              final authState = context.read<AuthBloc>().state;
              final isAdmin =
                  authState is AuthAuthenticated && authState.user.isAdmin;
              final currentUserId = authState is AuthAuthenticated
                  ? authState.user.id
                  : null;

              context.read<ComplaintBloc>().add(
                DeleteComplaintEvent(
                  complaint.id,
                  status: _selectedStatus,
                  priority: _selectedPriority,
                  type: _selectedType,
                  employeeId: _selectedEmployeeId,
                  currentUserId: currentUserId,
                  isAdmin: isAdmin,
                  mineOnly: _mineOnly,
                  searchQuery: _searchController.text.trim(),
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openWhatsApp(ComplaintEntity c) {
    if (c.customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number recorded for customer')),
      );
      return;
    }
    WhatsAppLauncher.send(
      phone: c.customerPhone,
      message:
          'Assalam o Alaikum ${c.customerName}, regarding your complaint (${c.type.label}): ',
    );
  }

  /// One tap: open -> in progress. Resolving needs notes, so that still goes
  /// through the edit dialog.
  void _startWork(ComplaintEntity c) {
    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : null;

    context.read<ComplaintBloc>().add(
      UpdateComplaintEvent(
        c.copyWith(status: ComplaintStatus.inProgress),
        status: _selectedStatus,
        priority: _selectedPriority,
        type: _selectedType,
        employeeId: _selectedEmployeeId,
        currentUserId: currentUserId,
        isAdmin: isAdmin,
        mineOnly: _mineOnly,
        searchQuery: _searchController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final authState = context.read<AuthBloc>().state;
    final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.id
        : null;

    return SingleChildScrollView(
      padding: Responsive.pagePaddingFor(Responsive.deviceTypeOf(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          LayoutBuilder(
            builder: (context, constraints) {
              final titleWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complaints & Tickets',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Manage, assign, and track customer support requests',
                    style: TextStyle(fontSize: 14, color: _muted),
                  ),
                ],
              );

              // Only admins create complaints (Firestore rules enforce it too).
              final Widget? newButton = !isAdmin
                  ? null
                  : ElevatedButton.icon(
                      onPressed: _isLoadingDropdowns
                          ? null
                          : () => _openAddEditDialog(),
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('New Complaint'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );

              if (constraints.maxWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleWidget,
                    if (newButton != null) ...[
                      const SizedBox(height: 16),
                      newButton,
                    ],
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [titleWidget, if (newButton != null) newButton],
              );
            },
          ),
          const SizedBox(height: 24),

          // BLoC State Consumer
          BlocConsumer<ComplaintBloc, ComplaintState>(
            listener: (context, state) {
              if (state is ComplaintLoaded) {
                _lastLoaded = state;
              } else if (state is ComplaintError && _lastLoaded != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            },
            builder: (context, rawState) {
              final state = rawState is ComplaintLoaded
                  ? rawState
                  : _lastLoaded;

              if (state == null) {
                if (rawState is ComplaintError) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.errorRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          rawState.message,
                          style: const TextStyle(color: AppColors.errorRed),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _triggerLoad,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                );
              }

              final list = state.complaints;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ComplaintMetricCards(complaints: list, isMobile: isMobile),
                  const SizedBox(height: 24),
                  ComplaintFilterPanel(
                    searchController: _searchController,
                    selectedStatus: _selectedStatus,
                    selectedPriority: _selectedPriority,
                    selectedType: _selectedType,
                    selectedEmployeeId: _selectedEmployeeId,
                    mineOnly: _mineOnly,
                    isAdmin: isAdmin,
                    employeesList: _employeesList,
                    activeFilterCount: _activeFilterCount,
                    onSearchChanged: (_) => _triggerLoad(),
                    onStatusChanged: (val) {
                      setState(() => _selectedStatus = val);
                      _triggerLoad();
                    },
                    onPriorityChanged: (val) {
                      setState(() => _selectedPriority = val);
                      _triggerLoad();
                    },
                    onTypeChanged: (val) {
                      setState(() => _selectedType = val);
                      _triggerLoad();
                    },
                    onEmployeeChanged: (val) {
                      setState(() => _selectedEmployeeId = val);
                      _triggerLoad();
                    },
                    onMineOnlyChanged: (val) {
                      setState(() => _mineOnly = val);
                      _triggerLoad();
                    },
                    onClearFilters: _clearFilters,
                  ),
                  const SizedBox(height: 20),
                  if (list.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _line),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.support_agent_outlined,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No complaints found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isAdmin
                                ? 'Try clearing filters or log a new ticket.'
                                : 'Nothing assigned to you right now.',
                            style: const TextStyle(fontSize: 13, color: _muted),
                          ),
                        ],
                      ),
                    )
                  else if (isMobile)
                    ComplaintCardList(
                      complaints: list,
                      isAdmin: isAdmin,
                      currentUserId: currentUserId,
                      onEdit: _openAddEditDialog,
                      onDelete: _confirmDelete,
                    )
                  else
                    _buildTicketList(context, list, isAdmin, currentUserId),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTicketList(
    BuildContext context,
    List<ComplaintEntity> complaints,
    bool isAdmin,
    String? currentUserId,
  ) {
    return Column(
      children: [
        for (final c in complaints)
          _buildTicketRow(context, c, isAdmin, currentUserId),
      ],
    );
  }

  Widget _buildTicketRow(
    BuildContext context,
    ComplaintEntity c,
    bool isAdmin,
    String? currentUserId,
  ) {
    final priorityColor = complaintPriorityColor(c.priority);
    final statusColor = complaintStatusColor(c.status);
    final canEdit =
        isAdmin ||
        (c.assignedEmployeeId != null && c.assignedEmployeeId == currentUserId);
    final done = c.isResolvedOrClosed;
    final lateColor = c.ageInDays > 2 ? AppColors.errorRed : _ink;

    return Opacity(
      opacity: done ? 0.7 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _line),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                color: done ? const Color(0xFFCBD5E1) : priorityColor,
              ),
              Expanded(
                child: InkWell(
                  onTap: canEdit ? () => _openAddEditDialog(c) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        // Customer
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.customerPhone.isNotEmpty
                                    ? c.customerPhone
                                    : 'No phone',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // What the problem is
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.type.label,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _ink,
                                ),
                              ),
                              if (c.description.trim().isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  c.description.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Priority + status
                        SizedBox(
                          width: 130,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _pill(c.priority.label, priorityColor),
                              _pill(c.status.label, statusColor),
                            ],
                          ),
                        ),
                        // Assignee (admin only)
                        if (isAdmin) ...[
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 110,
                            child: Text(
                              c.assignedEmployeeName ?? 'Unassigned',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: c.assignedEmployeeName == null
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: c.assignedEmployeeName == null
                                    ? AppColors.errorRed
                                    : _ink,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 16),
                        // Age
                        SizedBox(
                          width: 84,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                done
                                    ? 'Resolved'
                                    : (c.ageInDays == 0
                                          ? 'Today'
                                          : '${c.ageInDays}d open'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: done ? _muted : lateColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateTimeUtils.formatDate(c.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canEdit && c.status == ComplaintStatus.open)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: FilledButton.tonal(
                                  onPressed: () => _startWork(c),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                  ),
                                  child: const Text('Start'),
                                ),
                              ),
                            IconButton(
                              tooltip: 'WhatsApp customer',
                              onPressed: () => _openWhatsApp(c),
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: Color(0xFF25D366),
                                size: 20,
                              ),
                            ),
                            if (canEdit)
                              IconButton(
                                tooltip: done ? 'View ticket' : 'Update ticket',
                                onPressed: () => _openAddEditDialog(c),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                              ),
                            if (isAdmin)
                              IconButton(
                                tooltip: 'Delete ticket',
                                onPressed: () => _confirmDelete(c),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.errorRed,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
