import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'socket_service.dart';
import 'mock_mode.dart';
import 'package:flutter/foundation.dart';
import 'emergency_contact_service.dart';

class SOSService {
  static String? activeSosAlertId;
  static Timer? _liveLocationTimer;
  static final ValueNotifier<bool> isSharingLiveLocation = ValueNotifier(false);
  static final ValueNotifier<String?> lastLiveLocationText = ValueNotifier(null);

  // Step 1: Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Location error: $e');
      return null;
    }
  }

  // Step 2: Save SOS to backend
  Future<String?> saveSOSAlert({
    required String userId,
    String? rideId,
    double? lat,
    double? lng,
  }) async {
    if (kMockMode) {
      debugPrint('Mock SOS alert saved');
      activeSosAlertId = 'mock-alert-${DateTime.now().millisecondsSinceEpoch}';
      return activeSosAlertId;
    }
    try {
      final apiService = ApiService();
      final res = await apiService.post('/sos/trigger', {
        'lat': lat ?? 18.4624,
        'lng': lng ?? 73.8670,
        'rideId': rideId,
      });
      if (res is Map && res['data'] != null && res['data']['id'] != null) {
        activeSosAlertId = res['data']['id'].toString();
        return activeSosAlertId;
      }
    } catch (e) {
      debugPrint('SOS save error: $e');
    }
    return null;
  }

  // Continuous Live Location Sharing (Task 8)
  void startLiveLocationSharing(String alertId, {String? rideId, String? userId}) {
    stopLiveLocationSharing(notifyServer: false);
    activeSosAlertId = alertId;
    isSharingLiveLocation.value = true;

    _liveLocationTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        final position = await getCurrentLocation();
        if (position != null) {
          lastLiveLocationText.value =
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';

          // Emit via socket for instant reception
          SocketService().emit('sos_live_location', {
            'alert_id': alertId,
            'alertId': alertId,
            'ride_id': rideId,
            'rideId': rideId,
            'user_id': userId,
            'lat': position.latitude,
            'lng': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          });

          // Backup HTTP sync
          if (!kMockMode) {
            final apiService = ApiService();
            await apiService.post('/sos/$alertId/location', {
              'lat': position.latitude,
              'lng': position.longitude,
            });
          }
        }
      } catch (e) {
        debugPrint('SOS continuous location update error: $e');
      }
    });
  }

  Future<void> stopLiveLocationSharing({bool notifyServer = true}) async {
    _liveLocationTimer?.cancel();
    _liveLocationTimer = null;
    isSharingLiveLocation.value = false;
    lastLiveLocationText.value = null;

    final alertId = activeSosAlertId;
    activeSosAlertId = null;

    if (notifyServer && alertId != null && !kMockMode) {
      try {
        final apiService = ApiService();
        await apiService.post('/sos/$alertId/cancel', {});
      } catch (e) {
        debugPrint('Error cancelling SOS: $e');
      }
    }
  }

  // Step 3: Open WhatsApp with location
  Future<void> sendWhatsAppSOS({
    required String phoneNumber,
    required String userName,
    double? lat,
    double? lng,
    String? rideId,
  }) async {
    String locationText = lat != null && lng != null
        ? 'Location: https://maps.google.com/?q=$lat,$lng'
        : 'Location: Unable to get location';

    String message = '🚨 *EMERGENCY SOS ALERT* 🚨\n\n'
        'Student: $userName\n'
        '$locationText\n'
        'App: CampusLift\n'
        'Time: ${DateTime.now().toString()}\n\n'
        'Please respond immediately!';

    String cleanNumber = phoneNumber.replaceAll('+', '').replaceAll(' ', '');
    String encodedMessage = Uri.encodeComponent(message);
    String whatsappUrl = 'https://wa.me/$cleanNumber?text=$encodedMessage';

    try {
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      } else {
        String smsUrl = 'sms:$phoneNumber?body=$encodedMessage';
        if (await canLaunchUrl(Uri.parse(smsUrl))) {
          await launchUrl(Uri.parse(smsUrl));
        }
      }
    } catch (e) {
      debugPrint('WhatsApp error: $e');
    }
  }

  // Step 4: Open phone dialer
  Future<void> callEmergency() async {
    String emergencyNumber = 'tel:112';
    try {
      if (await canLaunchUrl(Uri.parse(emergencyNumber))) {
        await launchUrl(Uri.parse(emergencyNumber));
      }
    } catch (e) {
      debugPrint('Call error: $e');
    }
  }

  // Step 5: Main SOS trigger
  Future<void> triggerSOS({
    required String userName,
    required String userId,
    String? rideId,
  }) async {
    final position = await getCurrentLocation();

    // 1. Save to database & get alert ID
    final alertId = await saveSOSAlert(
      userId: userId,
      rideId: rideId,
      lat: position?.latitude,
      lng: position?.longitude,
    );

    // 2. Start continuous live location sharing
    if (alertId != null) {
      startLiveLocationSharing(alertId, rideId: rideId, userId: userId);
    }

    // 3. Get emergency contacts
    final contactService = EmergencyContactService();
    final numbers = await contactService.getPhoneNumbers();

    if (numbers.isEmpty) {
      throw Exception(
        'No emergency contacts found!\n'
        'Please add contacts in\n'
        'Settings → Emergency Contacts',
      );
    }

    // 4. Send WhatsApp/SMS to each contact
    for (String number in numbers) {
      await sendWhatsAppSOS(
        phoneNumber: number,
        userName: userName,
        lat: position?.latitude,
        lng: position?.longitude,
        rideId: rideId,
      );
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }
}
