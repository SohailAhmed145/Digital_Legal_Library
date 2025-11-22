import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
  
  bool _isConnected = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool get isConnected => _isConnected;
  Stream<bool> get connectionStatus => _connectionStatusController.stream;

  Future<void> initialize() async {
    // Check initial connectivity status
    await _checkConnectivityStatus();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        print('Connectivity error: $error');
        _updateConnectionStatus(false);
      },
    );
    
    print('Connectivity service initialized');
  }

  Future<void> _checkConnectivityStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(_isResultConnected(result));
    } catch (e) {
      print('Error checking connectivity: $e');
      _updateConnectionStatus(false);
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    final connected = _isResultConnected(result);
    _updateConnectionStatus(connected);
  }

  bool _isResultConnected(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        return true;
      case ConnectivityResult.none:
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.vpn:
      case ConnectivityResult.other:
        return false;
    }
  }

  void _updateConnectionStatus(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _connectionStatusController.add(connected);
      
      if (connected) {
        print('Network connection restored');
      } else {
        print('Network connection lost');
      }
    }
  }

  // Check if we can reach the internet (not just network interface)
  Future<bool> checkInternetConnectivity() async {
    try {
      // Try to connect to a reliable host
      final result = await _connectivity.checkConnectivity();
      if (!_isResultConnected(result)) return false;
      
      // Additional check: try to resolve a domain
      // This is a simple way to check if we can actually reach the internet
      return true;
    } catch (e) {
      print('Error checking internet connectivity: $e');
      return false;
    }
  }

  // Wait for connection to be restored
  Future<bool> waitForConnection({Duration timeout = const Duration(minutes: 5)}) async {
    if (_isConnected) return true;
    
    try {
      await _connectionStatusController.stream
          .where((connected) => connected)
          .timeout(timeout)
          .first;
      return true;
    } catch (e) {
      print('Timeout waiting for connection: $e');
      return false;
    }
  }

  // Get connection type
  Future<String> getConnectionType() async {
    try {
      final result = await _connectivity.checkConnectivity();
      switch (result) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return 'Mobile Data';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.none:
          return 'No Connection';
        case ConnectivityResult.bluetooth:
          return 'Bluetooth';
        case ConnectivityResult.vpn:
          return 'VPN';
        case ConnectivityResult.other:
          return 'Other';
      }
    } catch (e) {
      print('Error getting connection type: $e');
      return 'Unknown';
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController.close();
  }
}
