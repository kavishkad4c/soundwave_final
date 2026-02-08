 import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                _buildSettingsTile(
                  context,
                  Icons.notifications,
                  'Notifications',
                  Icons.arrow_forward_ios,
                  () {},
                ),
                _buildSettingsTile(
                  context,
                  Icons.lock,
                  'Privacy & Security',
                  Icons.arrow_forward_ios,
                  () {},
                ),
                _buildSettingsTile(
                  context,
                  Icons.language,
                  'Language',
                  Icons.arrow_forward_ios,
                  () {},
                ),
                _buildSettingsTile(
                  context,
                  Icons.help,
                  'Help & Support',
                  Icons.arrow_forward_ios,
                  () {},
                ),
                _buildSettingsTile(
                  context,
                  Icons.info,
                  'About',
                  Icons.arrow_forward_ios,
                  () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildThemeOption(
                          context,
                          'Light',
                          Icons.light_mode,
                          false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildThemeOption(
                          context,
                          'Dark',
                          Icons.dark_mode,
                          false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildThemeOption(
                          context,
                          'System',
                          Icons.settings,
                          true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData leadingIcon, String title,
      IconData trailingIcon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(leadingIcon),
      title: Text(title),
      trailing: Icon(trailingIcon, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildThemeOption(BuildContext context, String title, IconData icon, bool isSelected) {
    return Card(
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}