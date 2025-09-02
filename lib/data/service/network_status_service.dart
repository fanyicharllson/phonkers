import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

enum NetworkStatus { online, offline, unstable }

class NetworkStatusService {
  static final NetworkStatusService _instance =
      NetworkStatusService._internal();
  factory NetworkStatusService() => _instance;
  NetworkStatusService._internal();

  final _connectivity = Connectivity();
  final _internetChecker = InternetConnectionChecker.createInstance(
    checkInterval: const Duration(seconds: 3),
    checkTimeout: const Duration(seconds: 5),
  );

  final StreamController<NetworkStatus> _controller =
      StreamController.broadcast();
  Stream<NetworkStatus> get networkStatusStream => _controller.stream;

  NetworkStatus? _currentStatus;
  NetworkStatus? get currentStatus => _currentStatus;

  bool _isInitialized = false;
  StreamSubscription? _connectivitySubscription;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      _updateStatus(result);
    });

    // Do initial check and emit immediately
    await _checkInitialStatus();
    _isInitialized = true;
  }

  Future<void> _checkInitialStatus() async {
    final results = await _connectivity.checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    await _updateStatus(result);
  }

  Future<void> _updateStatus(ConnectivityResult result) async {
    NetworkStatus newStatus;

    if (result == ConnectivityResult.none) {
      newStatus = NetworkStatus.offline;
    } else {
      try {
        final hasInternet = await _internetChecker.hasConnection;
        newStatus = hasInternet ? NetworkStatus.online : NetworkStatus.unstable;
      } catch (e) {
        // If we can't check internet, assume unstable
        newStatus = NetworkStatus.unstable;
      }
    }

    // Only emit if status actually changed or it's the first check
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _controller.add(newStatus);
    }
  }

  // Method to manually refresh network status
  Future<NetworkStatus> refreshStatus() async {
    await _checkInitialStatus();
    return _currentStatus ?? NetworkStatus.offline;
  }

  // Utility method to check if we have internet connection
  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;

      if (result == ConnectivityResult.none) {
        return false;
      }

      return await _internetChecker.hasConnection;
    } catch (e) {
      return false;
    }
  }

  // Quick check without async - uses cached status
  bool get isOnline => _currentStatus == NetworkStatus.online;
  bool get isOffline => _currentStatus == NetworkStatus.offline;

  void dispose() {
    _connectivitySubscription?.cancel();
    _controller.close();
    _isInitialized = false;
  }
}
