import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';

class LocatorSettingsService {
  LocatorSettingsService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> loadSettings() async {
    final locatorId = await IdentityService.getLocatorId();
    final groupId = await IdentityService.getGroupId();

    if (locatorId == null || groupId == null) {
      return _defaultSettings();
    }

    final doc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(locatorId)
        .collection('settings')
        .doc('config')
        .get();

    if (!doc.exists) {
      return _defaultSettings();
    }

    final data = doc.data() ?? {};

    return {
      'gpsOffAlert': data['gpsOffAlert'] ?? true,
      'batteryLowAlert': data['batteryLowAlert'] ?? true,
      'batteryLowLevel': data['batteryLowLevel'] ?? 20,
      'geofenceAlert': data['geofenceAlert'] ?? false,
    };
  }

  static Map<String, dynamic> _defaultSettings() {
    return {
      'gpsOffAlert': true,
      'batteryLowAlert': true,
      'batteryLowLevel': 20,
      'geofenceAlert': false,
    };
  }
}