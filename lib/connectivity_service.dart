import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _connectivityController.stream;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    // Check initial connectivity
    _isOnline = await _checkConnectivity();
    _connectivityController.add(_isOnline);

    // Listen to connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(
              (ConnectivityResult result) async {
                    final wasOnline = _isOnline;
                    _isOnline = await _checkConnectivity();

                    if (wasOnline != _isOnline) {
                      _connectivityController.add(_isOnline);
                    }
                  }
                  as void Function(List<ConnectivityResult> event)?,
            )
            as StreamSubscription<ConnectivityResult>?;
  }

  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      // Additional check: try to reach a reliable server
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkConnectivity() async {
    _isOnline = await _checkConnectivity();
    return _isOnline;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}
