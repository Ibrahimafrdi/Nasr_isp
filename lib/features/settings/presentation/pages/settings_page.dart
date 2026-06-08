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

    _companyController = TextEditingController(text: 'NASR ISP Network Pvt Ltd');
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                          Expanded(child: _buildLeft()),
                          const SizedBox(width: 24),
                          Expanded(child: _buildPackages()),
                        ],
                      )
                    : Column(
                        children: [
                          _buildLeft(),
                          const SizedBox(height: 24),
                          _buildPackages(),
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeft() {
    return Column(
      children: [
        _buildCompanyCard(),
        const SizedBox(height: 20),
        _buildNetworkCard(),
        const SizedBox(height: 20),
        Align(
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
            label: Text(_isSaving ? "Saving..." : "Save Settings"),
          ),
        )
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
            const Text("Company Info",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            AppFormField(label: "Company Name", controller: _companyController),
            const SizedBox(height: 10),
            AppFormField(label: "Helpline", controller: _helplineController),
            const SizedBox(height: 10),
            AppFormField(label: "Email", controller: _emailController),
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
            const Text("Network Settings",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            AppFormField(label: "Gateway", controller: _gatewayController),
            const SizedBox(height: 10),
            AppFormField(label: "DNS", controller: _dnsController),
          ],
        ),
      ),
    );
  }

  Widget _buildPackages() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Packages",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _packages.length,
              itemBuilder: (context, i) {
                final p = _packages[i];
                return ListTile(
                  leading: const Icon(Icons.speed),
                  title: Text(p['name']),
                  subtitle: Text("${p['speed']} Mbps"),
                  trailing: Text(
                    DateTimeUtils.formatCurrency(p['rate']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _addPackage,
              icon: const Icon(Icons.add),
              label: const Text("Add Package"),
            )
          ],
        ),
      ),
    );
  }

  void _addPackage() {
    final name = TextEditingController();
    final speed = TextEditingController();
    final rate = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Package"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name),
            TextField(controller: speed),
            TextField(controller: rate),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _packages.add({
                  "name": name.text,
                  "speed": int.parse(speed.text),
                  "rate": double.parse(rate.text),
                });
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }
}