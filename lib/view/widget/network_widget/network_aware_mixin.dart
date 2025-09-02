import 'package:flutter/material.dart';
import 'package:phonkers/data/service/network_status_service.dart';

// Mixin to make any widget network-aware
mixin NetworkAwareMixin<T extends StatefulWidget> on State<T> {
  final NetworkStatusService _networkService = NetworkStatusService();

  // Check if we have internet connection
  Future<bool> hasInternetConnection() async {
    return await _networkService.hasInternetConnection();
  }

  // Quick check using cached status
  bool get isOnline => _networkService.isOnline;
  bool get isOffline => _networkService.isOffline;
  NetworkStatus? get currentNetworkStatus => _networkService.currentStatus;

  // Show a standardized "no internet" error widget
  Widget buildNoInternetError({
    VoidCallback? onRetry,
    String message = 'No internet connection',
    String retryText = 'Retry',
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, color: Colors.orange[300], size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: Text(retryText),
            ),
          ],
        ],
      ),
    );
  }

  // Execute a function only if we have internet, show error otherwise
  Future<T?> executeWithNetworkCheck<T>({
    required Future<T> Function() action,
    VoidCallback? onNoInternet,
    bool showSnackBar = true,
  }) async {
    if (!await hasInternetConnection()) {
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 12),
                Text('No internet connection'),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      onNoInternet?.call();
      return null;
    }

    return await action();
  }
}
