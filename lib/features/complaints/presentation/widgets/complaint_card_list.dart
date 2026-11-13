import 'package:flutter/material.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/core/utils/whatsapp_launcher.dart';
import 'package:nasr_isp/features/complaints/domain/entities/complaint_entity.dart';

Color complaintPriorityColor(ComplaintPriority priority) {
  switch (priority) {
    case ComplaintPriority.low:
      return const Color(0xFF2563EB);
    case ComplaintPriority.medium:
      return const Color(0xFFD97706);
    case ComplaintPriority.high:
      return const Color(0xFFEA580C);
    case ComplaintPriority.urgent:
      return const Color(0xFFDC2626);
  }
}

Color complaintStatusColor(ComplaintStatus status) {
  switch (status) {
    case ComplaintStatus.open:
      return const Color(0xFF2563EB);
    case ComplaintStatus.inProgress:
      return const Color(0xFFD97706);
    case ComplaintStatus.resolved:
      return const Color(0xFF10B981);
    case ComplaintStatus.closed:
      return const Color(0xFF4B5563);
  }
}

class ComplaintCardList extends StatelessWidget {
  final List<ComplaintEntity> complaints;
  final bool isAdmin;
  final String? currentUserId;
  final void Function(ComplaintEntity complaint) onEdit;
  final void Function(ComplaintEntity complaint) onDelete;

  const ComplaintCardList({
    super.key,
    required this.complaints,
    required this.isAdmin,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: complaints
          .map(
            (c) => _ComplaintCard(
              complaint: c,
              isAdmin: isAdmin,
              currentUserId: currentUserId,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          )
          .toList(),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  final ComplaintEntity complaint;
  final bool isAdmin;
  final String? currentUserId;
  final void Function(ComplaintEntity complaint) onEdit;
  final void Function(ComplaintEntity complaint) onDelete;

  const _ComplaintCard({
    required this.complaint,
    required this.isAdmin,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });

  static const _ink = Color(0xFF14213D);
  static const _muted = Color(0xFF5B6472);
  static const _border = Color(0xFFE3E6EB);

  @override
  Widget build(BuildContext context) {
    final bool canEdit = isAdmin ||
        (complaint.assignedEmployeeId != null &&
            complaint.assignedEmployeeId == currentUserId);

    final priorityColor = complaintPriorityColor(complaint.priority);
    final statusColor = complaintStatusColor(complaint.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      complaint.customerPhone.isNotEmpty
                          ? complaint.customerPhone
                          : 'No phone',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF25D366),
                  size: 20,
                ),
                tooltip: 'Chat on WhatsApp',
                onPressed: () {
                  if (complaint.customerPhone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No phone number recorded for customer'),
                      ),
                    );
                    return;
                  }
                  final msg =
                      'Assalam o Alaikum ${complaint.customerName}, regarding your complaint (${complaint.type.label}): ';
                  WhatsAppLauncher.send(
                    phone: complaint.customerPhone,
                    message: msg,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  complaint.type.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  complaint.priority.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  complaint.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            complaint.description,
            style: const TextStyle(fontSize: 14, color: _ink),
          ),
          if (complaint.resolutionNotes != null &&
              complaint.resolutionNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Resolution: ${complaint.resolutionNotes}',
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned: ${complaint.assignedEmployeeName ?? "Unassigned"}',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Created: ${DateTimeUtils.formatDate(complaint.createdAt)}${complaint.isResolvedOrClosed ? "" : " (${complaint.ageInDays}d old)"}',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit Ticket',
                      onPressed: () => onEdit(complaint),
                    ),
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.errorRed,
                      ),
                      tooltip: 'Delete Ticket',
                      onPressed: () => onDelete(complaint),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

