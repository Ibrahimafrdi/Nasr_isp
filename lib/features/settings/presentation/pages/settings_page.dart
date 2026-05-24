import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nasr_isp/core/constants/app_constants.dart';
import 'package:nasr_isp/core/theme/app_theme.dart';
import 'package:nasr_isp/core/utils/utils.dart';
import 'package:nasr_isp/shared/widgets/layout_widgets.dart';
import 'package:nasr_isp/shared/widgets/shared_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _companyController;
  late TextEditingController _helplineController;
  late TextEditingController _emailController;
  late TextEditingController _dnsController;
  late TextEditingController _gatewayController;

  bool _isSaving = false;

  final List<Map<String, dynamic>> _packages = [
    {'name': '10 Mbps Fiber', 'speed': 10, 'rate': 999.0},
    {'name': '25 Mbps Fiber', 'speed': 25, 'rate': 1499.0},
    {'name': '50 Mbps Fiber', 'speed': 50, 'rate': 2499.0},
    {'name': '100 Mbps Ultra', 'speed': 100, 'rate': 4499.0},
  ];

  @override
  void initState() {
    super.initState();

    _companyController = TextEditingController(
      text: 'NASR ISP Network Pvt Ltd',
    );
    _helplineController = TextEditingController(text: '021-111-999-888');
    _emailController = TextEditingController(text: 'noc@nasr_isp.com');
    _dnsController = TextEditingController(text: '8.8.8.8, 1.1.1.1');
    _gatewayController = TextEditingController(text: '10.0.0.1');
  }

  @override
  void dispose() {
    _companyController.dispose();
    _helplineController.dispose();
    _emailController.dispose();
    _dnsController.dispose();
    _gatewayController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() => _isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Breadcrumb(
            items: [
              BreadcrumbItem(
                label: 'Home',
                onTap: () => context.go('/dashboard'),
              ),
              BreadcrumbItem(label: 'Settings'),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'Administrative System Control Panel',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),

          Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;

                return isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildLeftPanel()),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildPackagesPanel()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildLeftPanel(),
                          const SizedBox(height: 24),
                          _buildPackagesPanel(),
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Column(
      children: [
        _buildCompanyCard(),
        const SizedBox(height: 24),
        _buildNetworkCard(),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildCompanyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ISP Company Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),

            AppFormField(
              label: 'Company Name',
              controller: _companyController,
              isRequired: true,
            ),

            const SizedBox(height: 12),

            AppFormField(
              label: 'Helpline',
              controller: _helplineController,
              isRequired: true,
            ),

            const SizedBox(height: 12),

            AppFormField(
              label: 'Email',
              controller: _emailController,
              isRequired: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Configuration',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),

            AppFormField(
              label: 'Gateway',
              controller: _gatewayController,
              isRequired: true,
            ),

            const SizedBox(height: 12),

            AppFormField(
              label: 'DNS Servers',
              controller: _dnsController,
              isRequired: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _saveSettings,
        icon: _isSaving
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
      ),
    );
  }

  Widget _buildPackagesPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bandwidth Packages',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _packages.length,
              itemBuilder: (context, index) {
                final pkg = _packages[index];

                return ListTile(
                  leading: const Icon(Icons.speed),
                  title: Text(pkg['name']),
                  subtitle: Text('${pkg['speed']} Mbps'),
                  trailing: Text(
                    DateTimeUtils.formatCurrency(pkg['rate']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _showAddPackageDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Package'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPackageDialog() {
    final name = TextEditingController();
    final speed = TextEditingController();
    final rate = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Package'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: speed,
              decoration: const InputDecoration(labelText: 'Speed'),
            ),
            TextField(
              controller: rate,
              decoration: const InputDecoration(labelText: 'Rate'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _packages.add({
                  'name': name.text,
                  'speed': int.parse(speed.text),
                  'rate': double.parse(rate.text),
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
