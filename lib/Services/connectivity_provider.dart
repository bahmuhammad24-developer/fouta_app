import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// A ChangeNotifier that exposes the current connectivity status of the device.
/// It listens to connectivity changes and notifies listeners when the online state changes.
class ConnectivityProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  StreamSubscription? _subscription;

  ConnectivityProvider() {
    _init();
  }

  void _init() {
    // Check initial connectivity state (handles both single and list results)
    Connectivity().checkConnectivity().then((dynamic result) {
      bool online;
      if (result is List<ConnectivityResult>) {
        online = result.isNotEmpty && !result.contains(ConnectivityResult.none);
      } else if (result is ConnectivityResult) {
        online = result != ConnectivityResult.none;
      } else {
        online = true;
      }
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });

    // Listen for connectivity changes
    _subscription = Connectivity().onConnectivityChanged.listen((dynamic result) {
      bool online;
      if (result is List<ConnectivityResult>) {
        online = result.isNotEmpty && !result.contains(ConnectivityResult.none);
      } else if (result is ConnectivityResult) {
        online = result != ConnectivityResult.none;
      } else {
        online = true;
      }
      if (online != _isOnline) {
        _isOnline = online;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
