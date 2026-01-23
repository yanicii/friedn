import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_info.dart';
import '../providers/app_state_provider.dart';
import '../services/native_service.dart';
import 'app_selection_screen.dart';
import 'nfc_setup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isWaitingForNfc = false;
  bool _pendingBlockingState = false;
  Duration? _pendingTimerDuration;
  bool _isTimerActivation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupNfcCallback();
    // Check for pending NFC tag after Flutter is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNfcTag();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NativeService.setNfcTagScannedCallback(null);
    super.dispose();
  }

  void _setupNfcCallback() {
    NativeService.setNfcTagScannedCallback((tagInfo) {
      if (_isWaitingForNfc) {
        _verifyNfcAndToggle(tagInfo.tagId);
      } else {
        // Handle NFC tag scanned when not explicitly waiting (e.g., app opened via NFC)
        _handleNfcTagFromLaunch(tagInfo.tagId);
      }
    });
  }

  Future<void> _checkPendingNfcTag() async {
    // Wait for provider to finish loading
    final provider = context.read<AppStateProvider>();
    while (provider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final pendingTagId = await NativeService.getPendingNfcTagId();
    if (pendingTagId != null) {
      _handleNfcTagFromLaunch(pendingTagId);
    }
  }

  void _handleNfcTagFromLaunch(String scannedTagId) {
    final provider = context.read<AppStateProvider>();
    final registeredTagId = provider.registeredTagId;
    final isBlocking = provider.isBlockingEnabled;

    // Only handle if blocking is enabled and tag matches
    if (isBlocking && registeredTagId != null && scannedTagId == registeredTagId) {
      provider.setBlockingEnabled(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('friedn is disabled'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _verifyNfcAndToggle(String scannedTagId) async {
    final provider = context.read<AppStateProvider>();
    final registeredTagId = provider.registeredTagId;

    final isTimerMode = _isTimerActivation;
    final timerDuration = _pendingTimerDuration;

    setState(() {
      _isWaitingForNfc = false;
      _isTimerActivation = false;
      _pendingTimerDuration = null;
    });

    Navigator.of(context).pop(); // Close the dialog

    if (registeredTagId != null && scannedTagId == registeredTagId) {
      // Correct tag!
      if (isTimerMode && timerDuration != null) {
        // Start blocking with timer
        await provider.setBlockingWithTimer(timerDuration);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Blocking enabled for ${_formatDuration(timerDuration)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Toggle blocking normally
        await provider.setBlockingEnabled(_pendingBlockingState);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_pendingBlockingState
                ? 'friedn is enabled'
                : 'friedn is disabled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Wrong tag
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wrong NFC tag. Please use your registered tag.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppStateProvider>().refreshPermissionStates();
      _checkPendingNfcTag();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.asset(
              theme.brightness == Brightness.dark
                  ? 'assets/friedn-full-tp-black.png'
                  : 'assets/friedn-full-tp-white.png',
              height: 28,
            ),
          ),
        ),
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(provider),
                const SizedBox(height: 16),
                _buildBlockingToggle(provider),
                const SizedBox(height: 16),
                _buildBlockedAppsSection(provider),
                const SizedBox(height: 16),
                _buildSetupSection(provider),
                const SizedBox(height: 16),
                _buildStatsSection(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(AppStateProvider provider) {
    final isReady = provider.isSetupComplete;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            isReady
                ? Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      theme.brightness == Brightness.dark
                          ? 'assets/friedn-logo-v2-black.png'
                          : 'assets/friedn-logo-v2-white.png',
                    ),
                  )
                : const Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: Colors.orange,
                  ),
            const SizedBox(height: 12),
            Text(
              isReady ? 'Ready to Block' : 'Setup Required',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isReady
                  ? 'Your NFC tag is registered and apps are selected.'
                  : 'Complete the setup steps below to start blocking apps.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupSection(AppStateProvider provider) {
    final isComplete = provider.isSetupComplete;
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: !isComplete,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Text(
                'Setup',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isComplete) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
            ],
          ),
          children: [
            _buildSetupItem(
              icon: Icons.nfc,
              title: 'NFC Tag',
              subtitle: provider.registeredTagId != null
                  ? 'Tag registered: ${provider.registeredTagId!.substring(0, 8)}...'
                  : 'No tag registered',
              isComplete: provider.registeredTagId != null,
              onTap: () => _navigateToNfcSetup(),
            ),
            Divider(color: theme.dividerColor),
            _buildSetupItem(
              icon: Icons.accessibility_new,
              title: 'Accessibility Service',
              subtitle: provider.isAccessibilityEnabled
                  ? 'Enabled'
                  : 'Required to detect app launches',
              isComplete: provider.isAccessibilityEnabled,
              onTap: () => provider.openAccessibilitySettings(),
            ),
            Divider(color: theme.dividerColor),
            _buildSetupItem(
              icon: Icons.layers,
              title: 'Overlay Permission',
              subtitle: provider.isOverlayPermissionGranted
                  ? 'Granted'
                  : 'Required to show lock screen',
              isComplete: provider.isOverlayPermissionGranted,
              onTap: () => provider.requestOverlayPermission(),
            ),
            Divider(color: theme.dividerColor),
            _buildSetupItem(
              icon: Icons.apps,
              title: 'Blocked Apps',
              subtitle: provider.blockedApps.isEmpty
                  ? 'No apps selected'
                  : '${provider.blockedApps.length} apps selected',
              isComplete: provider.blockedApps.isNotEmpty,
              onTap: () => _navigateToAppSelection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isComplete,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isComplete
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isComplete ? Colors.green : Colors.orange,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
      ),
      trailing: Icon(
        isComplete ? Icons.check_circle : Icons.chevron_right,
        color: isComplete ? Colors.green : Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildStatsSection(AppStateProvider provider) {
    final stats = provider.getBlockingStats();
    final theme = Theme.of(context);
    final hasStats = stats.totalMinutes > 0 || provider.blockingSessions.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Text(
                'Statistics',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.bar_chart,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
          children: [
            if (!hasStats)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No blocking sessions yet. Enable blocking to start tracking.',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              _buildStatItem(
                icon: Icons.hourglass_full,
                label: 'Total time blocked',
                value: _formatMinutes(stats.totalMinutes),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              _buildStatItem(
                icon: Icons.calendar_view_week,
                label: 'This week',
                value: _formatMinutes(stats.weekMinutes),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 12),
              _buildStatItem(
                icon: Icons.today,
                label: 'Today',
                value: _formatMinutes(stats.todayMinutes),
                color: Colors.green,
              ),
              if (stats.topBlockedApps.isNotEmpty) ...[
                const SizedBox(height: 20),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 12),
                Text(
                  'Most Blocked Apps',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...stats.topBlockedApps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final appStats = entry.value;
                  final appInfo = provider.installedApps.firstWhere(
                    (app) => app.packageName == appStats.packageName,
                    orElse: () => AppInfo(
                      packageName: appStats.packageName,
                      appName: appStats.appName,
                      icon: null,
                      isBlocked: false,
                    ),
                  );
                  return _buildTopAppItem(
                    rank: index + 1,
                    appInfo: appInfo,
                    minutes: appStats.totalMinutes,
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTopAppItem({
    required int rank,
    required AppInfo appInfo,
    required int minutes,
  }) {
    final theme = Theme.of(context);
    final rankColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (appInfo.icon != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.memory(
                appInfo.icon!,
                width: 32,
                height: 32,
              ),
            )
          else
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.android, color: Colors.grey, size: 20),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              appInfo.appName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatMinutes(minutes),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }

  Widget _buildBlockingToggle(AppStateProvider provider) {
    final canEnable = provider.isSetupComplete;
    final theme = Theme.of(context);
    final remainingTime = provider.remainingTime;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Blocking',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.isBlockingEnabled
                            ? 'Blocking is active - scan NFC to disable'
                            : canEnable
                                ? 'Scan NFC tag to enable'
                                : 'Complete setup to enable',
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: provider.isBlockingEnabled,
                  onChanged: canEnable
                      ? (value) => _showNfcScanDialog(value)
                      : null,
                ),
              ],
            ),
            if (provider.isBlockingEnabled && remainingTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Remaining: ${_formatDuration(remainingTime)}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!provider.isBlockingEnabled && canEnable) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showTimerPickerDialog(),
                icon: const Icon(Icons.timer),
                label: const Text('Set Timer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void _showTimerPickerDialog() {
    int selectedHours = 1;
    int selectedMinutes = 0;
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Blocking Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Block apps for a specific duration. You can end it early by scanning your NFC tag.',
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hours picker
                  Column(
                    children: [
                      Text(
                        'Hours',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 80,
                        height: 120,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setDialogState(() {
                              selectedHours = index;
                            });
                          },
                          controller: FixedExtentScrollController(initialItem: selectedHours),
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 24,
                            builder: (context, index) {
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: selectedHours == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selectedHours == index
                                        ? theme.colorScheme.primary
                                        : theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                  // Minutes picker
                  Column(
                    children: [
                      Text(
                        'Minutes',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 80,
                        height: 120,
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          perspective: 0.005,
                          diameterRatio: 1.2,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setDialogState(() {
                              selectedMinutes = index;
                            });
                          },
                          controller: FixedExtentScrollController(initialItem: selectedMinutes),
                          childDelegate: ListWheelChildBuilderDelegate(
                            childCount: 60,
                            builder: (context, index) {
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: selectedMinutes == index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selectedMinutes == index
                                        ? theme.colorScheme.primary
                                        : theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (selectedHours > 0 || selectedMinutes > 0)
                  ? () {
                      Navigator.of(dialogContext).pop();
                      _startTimerWithNfcVerification(
                        Duration(hours: selectedHours, minutes: selectedMinutes),
                      );
                    }
                  : null,
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  void _startTimerWithNfcVerification(Duration duration) {
    _pendingTimerDuration = duration;
    setState(() {
      _isWaitingForNfc = true;
      _isTimerActivation = true;
    });

    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enable Timer Blocking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.nfc,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Scan your NFC tag to start ${_formatDuration(duration)} timer',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hold your tag near the back of your phone',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isWaitingForNfc = false;
                _isTimerActivation = false;
                _pendingTimerDuration = null;
              });
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showNfcScanDialog(bool enableBlocking) {
    _pendingBlockingState = enableBlocking;
    setState(() {
      _isWaitingForNfc = true;
    });

    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          enableBlocking ? 'Enable Blocking' : 'Disable Blocking',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.nfc,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Scan your NFC tag to ${enableBlocking ? 'enable' : 'disable'} blocking',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hold your tag near the back of your phone',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isWaitingForNfc = false;
              });
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAppsSection(AppStateProvider provider) {
    if (provider.blockedApps.isEmpty) return const SizedBox.shrink();

    final blockedAppInfos =
        provider.installedApps.where((app) => app.isBlocked).toList();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Blocked Apps',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToAppSelection(),
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: blockedAppInfos.map((app) {
                return Chip(
                  avatar: app.icon != null
                      ? CircleAvatar(
                          backgroundImage: MemoryImage(app.icon!),
                        )
                      : null,
                  label: Text(
                    app.appName,
                  ),
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToNfcSetup() async {
    // Clear callback before navigating (NfcSetupScreen will set its own)
    NativeService.setNfcTagScannedCallback(null);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NfcSetupScreen()),
    );

    // Re-setup NFC callback after returning from NFC setup screen
    if (mounted) {
      _setupNfcCallback();
    }
  }

  void _navigateToAppSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AppSelectionScreen()),
    );
  }
}
