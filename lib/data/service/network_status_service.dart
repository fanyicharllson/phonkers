import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

enum NetworkStatus { online, offline, unstable }

class NetworkStatusService {
  final _connectivity = Connectivity();
  final _internetChecker = InternetConnectionChecker.createInstance();

  final StreamController<NetworkStatus> _controller =
      StreamController.broadcast();
  Stream<NetworkStatus> get networkStatusStream => _controller.stream;

  NetworkStatusService() {
    // Listen for connectivity changes (now returns a List<ConnectivityResult>)
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      _updateStatus(result);
    });

    // Do initial check
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final results = await _connectivity.checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    await _updateStatus(result);
  }

  Future<void> _updateStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      _controller.add(NetworkStatus.offline);
    } else {
      final hasInternet = await _internetChecker.hasConnection;
      if (hasInternet) {
        _controller.add(NetworkStatus.online);
      } else {
        _controller.add(NetworkStatus.unstable);
      }
    }
  }

  void dispose() {
    _controller.close();
  }
}
