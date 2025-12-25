import 'package:flutter/material.dart';
import '../services/config_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ConfigService _config = ConfigService();
  bool _hasPassword = false;
  List<String> _blockedSites = [];
  List<String> _blockedApps = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _config.init();
    setState(() {
      _hasPassword = _config.hasPassword;
      _blockedSites = List<String>.from(_config.blockedSites);
      _blockedApps = List<String>.from(_config.blockedApps);
    });
  }

  Future<void> _setPassword() async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_hasPassword ? 'Change Password' : 'Set Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text != confirmController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              Navigator.pop(context, controller.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (password != null && password.isNotEmpty) {
      await _config.setPassword(password);
      setState(() => _hasPassword = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password set')),
      );
    }
  }

  Future<void> _addBlockedSite() async {
    final controller = TextEditingController();
    final site = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Blocked Site'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'netflix.com',
            labelText: 'Domain',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (site != null && site.isNotEmpty) {
      setState(() => _blockedSites.add(site));
      await _config.setBlockedSites(_blockedSites);
    }
  }

  Future<void> _removeBlockedSite(String site) async {
    setState(() => _blockedSites.remove(site));
    await _config.setBlockedSites(_blockedSites);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Password section
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Password'),
            subtitle: Text(_hasPassword ? 'Password is set' : 'No password set'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _setPassword,
          ),
          const Divider(),

          // Blocked sites section
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Sites'),
            subtitle: Text('${_blockedSites.length} sites'),
            trailing: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addBlockedSite,
            ),
          ),
          ..._blockedSites.map((site) => ListTile(
                contentPadding: const EdgeInsets.only(left: 56, right: 16),
                title: Text(site),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeBlockedSite(site),
                ),
              )),
          const Divider(),

          // Default blocked sites info
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Default Blocked'),
            subtitle: Text(
              'Netflix, YouTube, Prime Video, Disney+, Hulu, HBO Max, '
              'Twitch, TikTok, and more are blocked by default.',
            ),
          ),
          const Divider(),

          // About section
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('About'),
            subtitle: Text('Total Control v1.0\nBy Rhodes AI'),
          ),
        ],
      ),
    );
  }
}
