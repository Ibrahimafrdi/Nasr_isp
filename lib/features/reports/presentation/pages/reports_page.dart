import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _selectedReportType = 'Collections Ledger';
  String _selectedPeriod = 'This Month';
  String _selectedFormat = 'PDF Document';
  bool _isGenerating = false;

  final List<Map<String, dynamic>> _downloadableReports = [
    {
      'name': 'Collections_Ledger_May_2026.pdf',
      'type': 'Collections Ledger',
      'date': '2026-05-19',
      'size': '2.4 MB',
      'format': 'PDF',
    },
    {
      'name': 'Operational_Expenses_Audit_Q1.xlsx',
      'type': 'Expense Audit',
      'date': '2026-04-10',
      'size': '840 KB',
      'format': 'Excel',
    },
    {
      'name': 'Subscriber_Contracts_Status.csv',
      'type': 'Contracts Status',
      'date': '2026-05-01',
      'size': '120 KB',
      'format': 'CSV',
    },
  ];

  void _generateReport() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final name = '${_selectedReportType.replaceAll(' ', '_')}_${_selectedPeriod.replaceAll(' ', '_')}.${_selectedFormat.contains('PDF') ? 'pdf' : (_selectedFormat.contains('Excel') ? 'xlsx' : 'csv')}';

    setState(() {
      _isGenerating = false;
      _downloadableReports.insert(0, {
        'name': name,
        'type': _selectedReportType,
        'date': DateTime.now().toString().split(' ')[0],
        'size': '1.2 MB',
        'format': _selectedFormat.contains('PDF') ? 'PDF' : (_selectedFormat.contains('Excel') ? 'Excel' : 'CSV'),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report "$name" compiled successfully!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: Text('Not authenticated')));
        }

        return Scaffold(
          appBar: DashboardTopBar(
            title: 'Audit & Financial Intelligence Reports',
            currentUser: authState.user,
          ),
          body: Row(
            children: [
              DashboardSidebar(
                currentUser: authState.user,
                currentRoute: RoutePaths.reports,
                onLogout: () {
                  context.read<AuthBloc>().add(const LogoutEvent());
                  context.go(RoutePaths.login);
                },
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Breadcrumb(
                        items: [
                          BreadcrumbItem(label: 'Home', onTap: () => context.go(RoutePaths.dashboard)),
                          BreadcrumbItem(label: 'Reports'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Layout: Config form on left, visual preview on right
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 800;
                          return isDesktop
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 3, child: _buildGeneratorPanel()),
                                    const SizedBox(width: 24),
                                    Expanded(flex: 2, child: _buildFinancialTrendsCard()),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildGeneratorPanel(),
                                    const SizedBox(height: 24),
                                    _buildFinancialTrendsCard(),
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Download table
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Archived Compiled Reports Registry',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              _buildDownloadsTable(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeneratorPanel() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Compile Custom Audit Report',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Audit Report Focus Area', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.mediumGray)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedReportType,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: 'Collections Ledger', child: Text('Monthly Collections Ledger')),
                          DropdownMenuItem(value: 'Expense Audit', child: Text('Operating Expense Audit')),
                          DropdownMenuItem(value: 'Contracts Status', child: Text('Subscriber Contracts Status')),
                          DropdownMenuItem(value: 'Installation Margins', child: Text('Installation Cost/Profit Margins')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedReportType = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date / Chronological Bounds', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.mediumGray)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedPeriod,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: 'Today', child: Text('Today')),
                          DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                          DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                          DropdownMenuItem(value: 'Q1 (Jan - Mar)', child: Text('Q1 (Jan - Mar)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPeriod = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Export Document Format', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.mediumGray)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedFormat,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: 'PDF Document', child: Text('PDF Document (Formatted print-ready)')),
                          DropdownMenuItem(value: 'Microsoft Excel', child: Text('Microsoft Excel (.xlsx Worksheet)')),
                          DropdownMenuItem(value: 'Comma Separated Values', child: Text('Comma Separated Values (.csv Table)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedFormat = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generateReport,
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.print),
                  label: Text(_isGenerating ? 'Compiling Ledger...' : 'Compile & Export Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialTrendsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppTheme.lightGray.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Margin Analytics Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, meta) {
                          const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
                          if (v.toInt() >= 0 && v.toInt() < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(labels[v.toInt()], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 80000, color: AppTheme.primaryColor, width: 14)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 100000, color: AppTheme.primaryColor, width: 14)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 115000, color: AppTheme.primaryColor, width: 14)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 110000, color: AppTheme.primaryColor, width: 14)]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 160000, color: AppTheme.primaryColor, width: 14)]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, color: AppTheme.successColor, size: 14),
                SizedBox(width: 4),
                Text('Realized +32% margin increment Q1 vs Q2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successColor)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadsTable() {
    return DataTableWrapper(
      columns: const [
        DataColumn(label: Text('Report Filename')),
        DataColumn(label: Text('Type')),
        DataColumn(label: Text('Date Compiled')),
        DataColumn(label: Text('Document Size')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Action')),
      ],
      rows: _downloadableReports.map((report) {
        final ext = report['format'] as String;
        IconData docIcon = Icons.picture_as_pdf;
        Color iconColor = AppTheme.errorColor;
        if (ext == 'Excel') {
          docIcon = Icons.table_chart;
          iconColor = AppTheme.successColor;
        } else if (ext == 'CSV') {
          docIcon = Icons.article;
          iconColor = AppTheme.primaryColor;
        }

        return DataRow(
          cells: [
            DataCell(
              Row(
                children: [
                  Icon(docIcon, color: iconColor, size: 18),
                  const SizedBox(width: 10),
                  Text(report['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            DataCell(Text(report['type'] as String)),
            DataCell(Text(DateTimeUtils.formatDate(DateTime.parse(report['date'] as String)))),
            DataCell(Text(report['size'] as String)),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Ready', style: TextStyle(fontSize: 10, color: AppTheme.successColor, fontWeight: FontWeight.bold)),
              ),
            ),
            DataCell(
              IconButton(
                icon: const Icon(Icons.file_download, color: AppTheme.primaryColor),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading file "${report['name']}"...')),
                  );
                },
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
