import 'package:flutter/foundation.dart';

class AppConfig {
  // Build-time configurable API URL via:
  //   flutter run --dart-define=API_URL=http://192.168.1.10:5000/api
  static const String _definedUrl = String.fromEnvironment('API_URL', defaultValue: '');

  // Optional LAN IP override via:
  //   flutter run --dart-define=LAN_IP=192.168.1.10
  static const String _lanIp = String.fromEnvironment('LAN_IP', defaultValue: '');

  static String get serverUrl {
    if (_definedUrl.isNotEmpty) {
      return _definedUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api';
    }
    if (_lanIp.isNotEmpty) {
      return 'http://$_lanIp:5000/api';
    }
    // Mobile fallback: Android emulator (10.0.2.2) or local LAN/desktop host
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:5000/api'
        : 'http://127.0.0.1:5000/api';
  }

  static String resolveUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final host = serverUrl.replaceAll(RegExp(r'/api/?$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$host$cleanPath';
  }
}
