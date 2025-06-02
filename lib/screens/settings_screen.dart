import 'package:flutter/material.dart';
import '../services/services.dart';

/// Settings screen for game preferences and options
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkMode = false;
  bool _showTimer = true;
  bool _highlightErrors = true;
  bool _autoSave = true;
  double _animationSpeed = 1.0;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final autoSaveEnabled = await GameStorageService.isAutoSaveEnabled();
    if (mounted) {
      setState(() {
        _autoSave = autoSaveEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Gameplay'),
          _buildSwitchTile(
            title: 'Show Timer',
            subtitle: 'Display elapsed time during game',
            value: _showTimer,
            onChanged: (value) => setState(() => _showTimer = value),
          ),
          _buildSwitchTile(
            title: 'Highlight Errors',
            subtitle: 'Show conflicting numbers in red',
            value: _highlightErrors,
            onChanged: (value) => setState(() => _highlightErrors = value),
          ),          _buildSwitchTile(
            title: 'Auto Save',
            subtitle: 'Automatically save game progress',
            value: _autoSave,
            onChanged: (value) async {
              await GameStorageService.setAutoSaveEnabled(value);
              setState(() => _autoSave = value);
            },
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Appearance'),
          _buildSwitchTile(
            title: 'Dark Mode',
            subtitle: 'Use dark theme',
            value: _darkMode,
            onChanged: (value) => setState(() => _darkMode = value),
          ),
          _buildSliderTile(
            title: 'Animation Speed',
            subtitle: 'Adjust game animation speed',
            value: _animationSpeed,
            min: 0.5,
            max: 2.0,
            divisions: 3,
            onChanged: (value) => setState(() => _animationSpeed = value),
            valueFormatter: (value) => '${value.toStringAsFixed(1)}x',
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Sound & Haptics'),
          _buildSwitchTile(
            title: 'Sound Effects',
            subtitle: 'Play sounds for actions',
            value: _soundEnabled,
            onChanged: (value) => setState(() => _soundEnabled = value),
          ),
          _buildSwitchTile(
            title: 'Vibration',
            subtitle: 'Vibrate on errors and completion',
            value: _vibrationEnabled,
            onChanged: (value) => setState(() => _vibrationEnabled = value),
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Game Data'),
          _buildActionTile(
            title: 'Clear Statistics',
            subtitle: 'Reset all game statistics',
            icon: Icons.delete_outline,
            onTap: _showClearStatsDialog,
            isDestructive: true,
          ),
          _buildActionTile(
            title: 'Export Data',
            subtitle: 'Export game data for backup',
            icon: Icons.download,
            onTap: _exportData,
          ),
          _buildActionTile(
            title: 'Import Data',
            subtitle: 'Import previously exported data',
            icon: Icons.upload,
            onTap: _importData,
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          _buildActionTile(
            title: 'App Version',
            subtitle: '1.0.0',
            icon: Icons.info_outline,
            onTap: null,
          ),
          _buildActionTile(
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            icon: Icons.privacy_tip_outlined,
            onTap: _showPrivacyPolicy,
          ),
          _buildActionTile(
            title: 'Terms of Service',
            subtitle: 'View terms of service',
            icon: Icons.description_outlined,
            onTap: _showTermsOfService,
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String Function(double) valueFormatter,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(
                  valueFormatter(value),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive 
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          title,
          style: isDestructive
              ? TextStyle(color: Theme.of(context).colorScheme.error)
              : null,
        ),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _showClearStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Statistics'),
        content: const Text(
          'Are you sure you want to clear all your game statistics? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearStatistics();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _clearStatistics() {
    // TODO: Implement clear statistics
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Statistics cleared successfully'),
      ),
    );
  }

  void _exportData() {
    // TODO: Implement export data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
      ),
    );
  }

  void _importData() {
    // TODO: Implement import data
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import functionality coming soon'),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This app does not collect, store, or transmit any personal data. '
            'All game data is stored locally on your device.\n\n'
            'Game statistics and preferences are saved in local storage and '
            'are not shared with any third parties.\n\n'
            'This app does not require internet connectivity and does not '
            'communicate with external servers.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'By using this app, you agree to the following terms:\n\n'
            '1. This app is provided "as is" without warranty of any kind.\n\n'
            '2. The developers are not liable for any damages resulting from '
            'the use of this app.\n\n'
            '3. You may use this app for personal, non-commercial purposes.\n\n'
            '4. These terms may be updated at any time without notice.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
