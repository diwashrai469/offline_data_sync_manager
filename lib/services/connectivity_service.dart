import 'dart:async';

import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  final InternetConnectionChecker _connectionChecker =
      InternetConnectionChecker();
  StreamSubscription<InternetConnectionStatus>? _subscription;

  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  ConnectivityService() {
    _initializeConnectivity();
  }

  void _initializeConnectivity() {
    _subscription = _connectionChecker.onStatusChange.listen((status) {
      final wasConnected = _isConnected;
      _isConnected = status == InternetConnectionStatus.connected;

      if (!wasConnected && _isConnected) {
        // Connection restored
        _connectivityController.add(true);
      } else if (wasConnected && !_isConnected) {
        // Connection lost
        _connectivityController.add(false);
      }
    });

    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    _isConnected = await _connectionChecker.hasConnection;
    _connectivityController.add(_isConnected);
  }

  Future<bool> checkConnectivity() async {
    _isConnected = await _connectionChecker.hasConnection;
    return _isConnected;
  }

  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
