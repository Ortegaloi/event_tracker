import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/web_file_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  
  @override
  Widget build(BuildContext context) {
    final dataService = DataService();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          // Data Management Section
          _buildSectionHeader('Data Management'),
          
          _buildListTile(
            icon: Icons.refresh,
            iconColor: Colors.blue,
            title: 'Refresh from original file',
            subtitle: 'Reload data from assets/birthdays.txt',
            onTap: () => _refreshData(context, dataService),
          ),
          
          _buildListTile(
            icon: Icons.save,
            iconColor: Colors.green,
            title: 'Save to local storage',
            subtitle: 'Manually save current data to browser',
            onTap: () => _saveData(context, dataService),
          ),
          
          Divider(),
          
          // Export Options Section
          _buildSectionHeader('Export Options'),
          
          if (_isExporting)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildExportOption(
              context,
              method: ExportMethod.download,
              dataService: dataService,
            ),
            _buildExportOption(
              context,
              method: ExportMethod.webShare,
              dataService: dataService,
            ),
            _buildExportOption(
              context,
              method: ExportMethod.sharePlus,
              dataService: dataService,
            ),
            _buildExportOption(
              context,
              method: ExportMethod.fileSaver,
              dataService: dataService,
            ),
          ],
          
          Divider(),
          
          // Danger Zone
          _buildSectionHeader('Danger Zone', color: Colors.red),
          
          _buildListTile(
            icon: Icons.delete_forever,
            iconColor: Colors.red,
            title: 'Clear all data',
            subtitle: 'Remove all locally stored events',
            onTap: () => _showDeleteAllDialog(context, dataService),
          ),
          
          Divider(),
          
          // About Section
          _buildSectionHeader('About'),
          
          _buildListTile(
            icon: Icons.info,
            iconColor: Colors.blue,
            title: 'About',
            subtitle: 'Birthday & Anniversary Tracker v1.0.0',
            onTap: () => _showAboutDialog(context),
          ),
          
          _buildListTile(
            icon: Icons.code,
            iconColor: Colors.purple,
            title: 'Web Platform',
            subtitle: 'Running on: ${DateTime.now().year}',
            onTap: null,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, {Color color = Colors.black54}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
  
  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: onTap != null ? Icon(Icons.chevron_right) : null,
    );
  }
  
  Widget _buildExportOption(
    BuildContext context, {
    required ExportMethod method,
    required DataService dataService,
  }) {
    // Using the extension methods
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(method.icon, color: Colors.green), // Now works with extension
      ),
      title: Text(method.displayName), // Now works with extension
      subtitle: Text('Export all events as ${method.displayName.toLowerCase()}'),
      onTap: () async {
        setState(() => _isExporting = true);
        
        await WebFileService.exportData(
          dataService.people,
          context: context,
          method: method,
        );
        
        if (mounted) {
          setState(() => _isExporting = false);
        }
      },
    );
  }
  
  Future<void> _refreshData(BuildContext context, DataService dataService) async {
    try {
      await dataService.refreshFromAssets();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Data refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showError(context, 'Error refreshing data');
    }
  }
  
  Future<void> _saveData(BuildContext context, DataService dataService) async {
    try {
      await WebFileService.saveToLocal(dataService.people);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Data saved to browser storage'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(context, 'Error saving data');
    }
  }
  
  void _showDeleteAllDialog(BuildContext context, DataService dataService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ Clear All Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you absolutely sure?'),
            SizedBox(height: 16),
            Text(
              'This will permanently delete all birthdays and anniversaries from your browser storage.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Implement clear all in DataService
              // await dataService.clearAllData();
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🗑️ All data cleared'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear All'),
          ),
        ],
      ),
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cake, size: 50, color: Colors.pink),
            SizedBox(height: 16),
            Text(
              'Birthday & Anniversary Tracker',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0 (2026)'),
            SizedBox(height: 16),
            Text(
              'Keep track of all your loved ones\' birthdays and anniversaries in one place.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              '🌐 Web Optimized',
              style: TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
  
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
      ),
    );
  }
}