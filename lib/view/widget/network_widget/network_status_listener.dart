import 'package:flutter/material.dart';
import 'package:phonkers/data/service/network_status_service.dart';
import 'dart:async';

class NetworkStatusListener extends StatefulWidget {
  final Widget child;
  final bool showInitialStatus; // Whether to show status on app start

  const NetworkStatusListener({
    super.key,
    required this.child,
    this.showInitialStatus = false, // Default to false to avoid spam
  });

  @override
  State<NetworkStatusListener> createState() => _NetworkStatusListenerState();
}

class _NetworkStatusListenerState extends State<NetworkStatusListener> {
  late final NetworkStatusService _networkStatusService;
  NetworkStatus? _currentStatus;
  StreamSubscription? _subscription;
  bool _hasShownInitialStatus = false;

  @override
  void initState() {
    super.initState();
    _networkStatusService = NetworkStatusService();
    _initializeNetworkListener();
  }

  Future<void> _initializeNetworkListener() async {
    // Initialize the service
    await _networkStatusService.initialize();

    // Listen to network status changes
    _subscription = _networkStatusService.networkStatusStream.listen((status) {
      if (!mounted) return;

      final bool shouldShowNotification =
          _currentStatus != status &&
          (_hasShownInitialStatus ||
              widget.showInitialStatus ||
              _currentStatus != null);

      setState(() {
        _currentStatus = status;
      });

      if (shouldShowNotification) {
        _showNetworkSnackBar(status);
      }

      _hasShownInitialStatus = true;
    });
  }

  void _showNetworkSnackBar(NetworkStatus status) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    String message;
    Color bgColor;
    IconData icon;

    switch (status) {
      case NetworkStatus.offline:
        message = "No internet connection";
        bgColor = Colors.red;
        icon = Icons.signal_wifi_off;
        break;
      case NetworkStatus.unstable:
        message = "Network is unstable";
        bgColor = Colors.orange;
        icon = Icons.wifi_protected_setup;
        break;
      case NetworkStatus.online:
        message = "Back online";
        bgColor = Colors.green;
        icon = Icons.wifi;
        break;
    }

    // Clear any existing snackbars first
    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        duration: Duration(seconds: status == NetworkStatus.online ? 3 : 5),
        backgroundColor: bgColor.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: status == NetworkStatus.offline
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () async {
                  await _networkStatusService.refreshStatus();
                },
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
