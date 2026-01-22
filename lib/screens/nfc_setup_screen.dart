import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../services/native_service.dart';

class NfcSetupScreen extends StatefulWidget {
  const NfcSetupScreen({super.key});

  @override
  State<NfcSetupScreen> createState() => _NfcSetupScreenState();
}

class _NfcSetupScreenState extends State<NfcSetupScreen> with WidgetsBindingObserver {
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupNfcCallback();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Don't set callback to null here - let the parent screen (HomeScreen)
    // re-setup its callback after this screen is popped
    super.dispose();
  }

  void _setupNfcCallback() {
    NativeService.setNfcTagScannedCallback((tagInfo) {
      if (_isScanning) {
        setState(() {
          _isScanning = false;
        });
        _showRegisterTagDialog(tagInfo);
      }
    });
  }

  void _showRegisterTagDialog(NfcTagInfo tagInfo) {
    final provider = context.read<AppStateProvider>();
    final hasExistingTag = provider.registeredTagId != null;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tag Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasExistingTag
                  ? 'Do you want to replace your existing tag with this one?'
                  : 'Do you want to register this tag as your unlock key?',
            ),
            const SizedBox(height: 12),
            Text(
              'Tag ID: ${tagInfo.tagId}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _doRegisterTag(provider, tagInfo.tagId);
            },
            child: Text(
              hasExistingTag ? 'Replace' : 'Register',
              style: TextStyle(
                color: hasExistingTag ? Colors.orange : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppStateProvider>().refreshPermissionStates();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NFC Tag Setup'),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCurrentTagCard(provider),
                const SizedBox(height: 24),
                _buildNfcStatusCard(provider),
                const SizedBox(height: 24),
                _buildScanSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentTagCard(AppStateProvider provider) {
    final hasTag = provider.registeredTagId != null;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              hasTag ? Icons.nfc : Icons.nfc_rounded,
              size: 64,
              color: hasTag ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              hasTag ? 'Tag Registered' : 'No Tag Registered',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasTag) ...[
              const SizedBox(height: 8),
              Text(
                'ID: ${provider.registeredTagId}',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _confirmClearTag(provider),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Remove Tag',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNfcStatusCard(AppStateProvider provider) {
    final theme = Theme.of(context);

    if (!provider.isNfcAvailable) {
      return Card(
        color: Colors.red.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'NFC is not available on this device',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!provider.isNfcEnabled) {
      return Card(
        color: Colors.orange.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'NFC is disabled. Enable it to scan tags.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: () => provider.openNfcSettings(),
                child: const Text('Enable'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.green.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Text(
              'NFC is enabled and ready',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanSection() {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              _isScanning ? 'Scanning...' : 'Register New Tag',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isScanning
                  ? 'Hold your NFC tag near the back of your phone'
                  : 'Tap the button below and hold any NFC tag near your phone to register it as your unlock key.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
            ),
            if (!_isScanning) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'No data will ever be written to your tag',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            if (_isScanning)
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                  strokeWidth: 3,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isScanning = true;
                  });
                },
                icon: const Icon(Icons.nfc),
                label: const Text('Start Scanning'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            if (_isScanning) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isScanning = false;
                  });
                },
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _doRegisterTag(AppStateProvider provider, String tagId) async {
    await provider.registerNfcTag(tagId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NFC tag registered successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _confirmClearTag(AppStateProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Tag?'),
        content: const Text(
          'Are you sure you want to remove the registered NFC tag? You will need to register a new tag to unlock blocked apps.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearRegisteredTag();
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
