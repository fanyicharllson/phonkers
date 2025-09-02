import 'package:flutter/material.dart';
import 'package:phonkers/data/service/network_status_service.dart';

class NetworkStatusListener extends StatefulWidget {
  final Widget child;

  const NetworkStatusListener({super.key, required this.child});

  @override
  State<NetworkStatusListener> createState() => _NetworkStatusListenerState();
}

class _NetworkStatusListenerState extends State<NetworkStatusListener> {
  late final NetworkStatusService _networkStatusService;
  NetworkStatus _currentStatus = NetworkStatus.online;

  @override
  void initState() {
    super.initState();
    _networkStatusService = NetworkStatusService();

    _networkStatusService.networkStatusStream.listen((status) {
      if (mounted && status != _currentStatus) {
        setState(() {
          _currentStatus = status;
        });
        _showNetworkSnackBar(status);
      }
    });
  }

  void _showNetworkSnackBar(NetworkStatus status) {
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

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        backgroundColor: bgColor.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _networkStatusService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Just return the child — no overlay needed now
    return widget.child;
  }
}
