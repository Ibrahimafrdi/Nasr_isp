import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/theme/app_colors.dart';
import 'package:nasr_isp/core/theme/app_fonts.dart';

class Breadcrumbs extends StatelessWidget {
  final String rootLabel = 'Dashboard';
  final bool capitalizeSegments = true;

  const Breadcrumbs({super.key});

  @override
  Widget build(BuildContext context) {
    final (labels, targetRoutes) = _buildFromCurrentLocation(context);

    return Row(
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            for (int index = 0; index < labels.length; index++) ...[
              _buildCrumb(
                context,
                labels[index],
                index == labels.length - 1,
                (targetRoutes.isNotEmpty &&
                        index < targetRoutes.length &&
                        targetRoutes[index].isNotEmpty
                    ? () => context.go(targetRoutes[index])
                    : null),
              ),
              if (index != labels.length - 1)
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCrumb(
    BuildContext context,
    String label,
    bool isLast,
    VoidCallback? onTap,
  ) {
    final text = Text(
      label,
      style: (isLast ? AppFonts.labelLarge : AppFonts.bodySmall).copyWith(
        color: isLast ? AppColors.primary : Colors.grey[700],
        fontWeight: isLast ? AppFonts.semiBold : AppFonts.medium,
      ),
    );

    if (isLast || onTap == null) return text;

    return InkWell(onTap: onTap, child: text);
  }

  (List<String> labels, List<String> routes) _buildFromCurrentLocation(
    BuildContext context,
  ) {
    final String location = GoRouterState.of(context).uri.toString();
    final String pathOnly = location.split('?').first.split('#').first;
    final List<String> segments = pathOnly
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();

    final List<String> labels = <String>[rootLabel];
    final List<String> paths = <String>['/'];

    String cumulative = '';
    for (final seg in segments) {
      cumulative += '/$seg';
      paths.add(cumulative);
      labels.add(_formatSegment(seg));
    }

    return (labels, paths);
  }

  String _formatSegment(String segment) {
    final String cleaned = segment.replaceAll('-', ' ').replaceAll('_', ' ');
    if (capitalizeSegments) {
      return cleaned
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => w[0].toUpperCase() + w.substring(1))
          .join(' ');
    }
    return cleaned.toLowerCase();
  }
}
