import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/material.dart';

class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final Connectivity _connectivity = Connectivity();
  final Battery _battery = Battery();

  // Network connectivity
  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged;

  Future<ConnectivityResult> checkConnectivity() async {
    return await _connectivity.checkConnectivity();
  }

  Future<bool> isConnected() async {
    final result = await checkConnectivity();
    return result != ConnectivityResult.none;
  }

  String getConnectionType(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      return 'No Connection';
    }
    if (result == ConnectivityResult.wifi) {
      return 'WiFi';
    }
    if (result == ConnectivityResult.mobile) {
      return 'Mobile Data';
    }
    if (result == ConnectivityResult.ethernet) {
      return 'Ethernet';
    }
    return 'Connected';
  }

  // Battery status
  Future<int> getBatteryLevel() async {
    return await _battery.batteryLevel;
  }

  Stream<BatteryState> get batteryStateStream => _battery.onBatteryStateChanged;

  Future<BatteryState> getBatteryState() async {
    return await _battery.batteryState;
  }

  bool isLowBattery(int level) {
    return level <= 20;
  }

  String getBatteryIcon(int level) {
    if (level >= 90) return '🔋';
    if (level >= 60) return '🔋';
    if (level >= 30) return '🔋';
    if (level >= 10) return '🪫';
    return '🪫';
  }

  // Vibration and haptics
  Future<void> vibrateLight() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 50);
      }
    }
  }

  Future<void> vibrateMedium() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 100);
      }
    }
  }

  Future<void> vibrateSuccess() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 50);
        await Future.delayed(const Duration(milliseconds: 100));
        Vibration.vibrate(duration: 50);
      }
    }
  }

  Future<void> vibrateError() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 200);
      }
    }
  }

  // Show a quick connectivity status
  void showConnectivitySnackbar(BuildContext context, ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;
    final connectionType = getConnectionType(result);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(isOnline ? 'Connected via $connectionType' : 'No Internet Connection'),
          ],
        ),
        backgroundColor: isOnline ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show a low-battery warning
  void showBatteryWarning(BuildContext context, int level) {
    if (isLowBattery(level)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.battery_alert, color: Colors.white),
              const SizedBox(width: 8),
              Text('Low Battery: $level%'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }
}

