import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';

class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Apps to Block'),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          final filteredApps = provider.installedApps.where((app) {
            return app.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                app.packageName.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              if (provider.isBlockingEnabled) _buildLockedBanner(),
              _buildSearchBar(),
              _buildHeader(provider),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredApps.length,
                  itemBuilder: (context, index) {
                    final app = filteredApps[index];
                    return _buildAppTile(app, provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLockedBanner() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.orange.withOpacity(0.2),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Blocking is active. Disable friedn to remove apps from the blocklist.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search apps...',
          hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search, color: theme.iconTheme.color?.withOpacity(0.5)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: theme.iconTheme.color?.withOpacity(0.5)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: theme.cardTheme.color,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppStateProvider provider) {
    final blockedCount = provider.blockedApps.length;
    final totalCount = provider.installedApps.length;
    final isLocked = provider.isBlockingEnabled;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.cardTheme.color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$blockedCount of $totalCount apps blocked',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          if (blockedCount > 0 && !isLocked)
            TextButton(
              onPressed: () => _confirmClearAll(provider),
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppTile(app, AppStateProvider provider) {
    final isLocked = provider.isBlockingEnabled;
    final canToggle = !isLocked || !app.isBlocked; // Can only add apps when locked, not remove
    final theme = Theme.of(context);

    return ListTile(
      leading: app.icon != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                app.icon!,
                width: 48,
                height: 48,
              ),
            )
          : Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.android, color: Colors.grey),
            ),
      title: Text(
        app.appName,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: canToggle ? null : theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        app.packageName,
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLocked && app.isBlocked)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.lock, color: Colors.orange, size: 16),
            ),
          Checkbox(
            value: app.isBlocked,
            onChanged: canToggle
                ? (value) {
                    provider.toggleAppBlocked(app.packageName);
                  }
                : null,
            activeColor: Colors.red,
            checkColor: Colors.white,
          ),
        ],
      ),
      onTap: canToggle
          ? () {
              provider.toggleAppBlocked(app.packageName);
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Disable friedn to remove apps from blocklist'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
    );
  }

  void _confirmClearAll(AppStateProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('Are you sure you want to unblock all apps?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              for (final app in provider.installedApps.where((a) => a.isBlocked).toList()) {
                provider.toggleAppBlocked(app.packageName);
              }
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
