import 'package:flutter/material.dart';
import 'package:nasr_isp/features/auth/data/models/user_model.dart';

// Colours for the redesigned Settings screen, private to this file.
const Color _kInk = Color(0xFF14213D);
const Color _kMuted = Color(0xFF5B6472);
const Color _kBorder = Color(0xFFE3E6EB);
const Color _kTeal = Color(0xFF0F766E);
const Color _kSoft = Color(0xFFF6F7F9);

// Column widths. The header and the rows read these same numbers.
const int _fName = 20;
const int _fEmail = 24;
const int _fRole = 14;
const int _fStatus = 16;

/// Full-width users table for desktop.
///
/// Pure UI - role and status changes are callbacks handled by the page (which
/// asks for confirmation first). The current user's own row is locked, so an
/// admin cannot demote or deactivate themselves.
class UserTable extends StatelessWidget {
  final List<UserModel> users;
  final String? currentUserId;
  final void Function(UserModel user, String newRole) onRoleChanged;
  final void Function(UserModel user, bool newActive) onStatusChanged;

  const UserTable({
    super.key,
    required this.users,
    required this.currentUserId,
    required this.onRoleChanged,
    required this.onStatusChanged,
  });

  /// Below this width the table scrolls sideways inside its card.
  static const double _minWidth = 820;

  @override
  Widget build(BuildContext context) {
    final table = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _HeaderRow(),
        ...users.map(
          (u) => _UserRow(
            user: u,
            isSelf: currentUserId == u.id,
            onRoleChanged: onRoleChanged,
            onStatusChanged: onStatusChanged,
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final Widget body = constraints.maxWidth >= _minWidth
            ? table
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: _minWidth, child: table),
              );
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: body,
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: _kInk,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFEEF2F6),
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: const Row(
        children: [
          Expanded(flex: _fName, child: Text('Name', style: style)),
          Expanded(flex: _fEmail, child: Text('Email', style: style)),
          Expanded(flex: _fRole, child: Text('Role', style: style)),
          Expanded(flex: _fStatus, child: Text('Status', style: style)),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserModel user;
  final bool isSelf;
  final void Function(UserModel user, String newRole) onRoleChanged;
  final void Function(UserModel user, bool newActive) onStatusChanged;

  const _UserRow({
    required this.user,
    required this.isSelf,
    required this.onRoleChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final role = user.role == 'admin' ? 'admin' : 'employee';

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          // Name (+ "You" tag on your own row)
          Expanded(
            flex: _fName,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                  ),
                ),
                if (isSelf) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _kSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kBorder),
                    ),
                    child: const Text(
                      'You',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Email
          Expanded(
            flex: _fEmail,
            child: Text(
              user.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: _kInk),
            ),
          ),
          // Role
          Expanded(
            flex: _fRole,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelf ? _kSoft : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _kBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: role,
                    style: const TextStyle(fontSize: 14, color: _kInk),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(
                        value: 'employee',
                        child: Text('Employee'),
                      ),
                    ],
                    // Your own role is locked.
                    onChanged: isSelf
                        ? null
                        : (newRole) {
                            if (newRole != null && newRole != user.role) {
                              onRoleChanged(user, newRole);
                            }
                          },
                  ),
                ),
              ),
            ),
          ),
          // Status: switch and its word together
          Expanded(
            flex: _fStatus,
            child: Row(
              children: [
                Switch(
                  value: user.isActive,
                  activeThumbColor: Colors.white,
                  activeTrackColor: _kTeal,
                  // You cannot switch yourself off.
                  onChanged: isSelf
                      ? null
                      : (value) => onStatusChanged(user, value),
                ),
                const SizedBox(width: 8),
                Text(
                  user.isActive ? 'Active' : 'Inactive',
                  style: const TextStyle(fontSize: 14, color: _kInk),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
