import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:battery_plus/battery_plus.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class AlertService {
  AlertService._();

  static final _firestore = FirebaseFirestore.instance;

	static Future<void> sendGpsOffAlert() async {
		await _sendAlertToPairedRequesters(
			type: 'gps_off',
		);

		Log.d("BEACON ALERT => gps_off sent");
	}
	
	static Future<void> sendBatteryLowAlert({
		required int batteryLevel,
	}) async {
		await _sendAlertToPairedRequesters(
			type: 'battery_low',
			extraData: {
				'battery': batteryLevel,
			},
		);

		Log.d("BEACON ALERT => battery_low sent");
	}
	
	static Future<void> sendPlaceAlert({
		required String type, // place_enter / place_exit
		required String placeName,
	}) async {
		await _sendAlertToPairedRequesters(
			type: type,
			extraData: {
				'placeName': placeName,
			},
		);

		Log.d("BEACON ALERT => $type sent => $placeName");
	}

	static Future<void> sendMovementAlert({
		required double movedMeters,
		bool detectedWhileOffline = false,
	}) async {
	Log.d("sendMovementAlert is called");
		await _sendAlertToPairedRequesters(
			type: 'movement',
			extraData: {
				'movedMeters': movedMeters.round(),
				'detectedWhileOffline': detectedWhileOffline,
			},
		);

		Log.d(
			"BEACON ALERT => movement sent "
			"moved=${movedMeters.toStringAsFixed(1)}m "
			"offline=$detectedWhileOffline",
		);
	}
	

  static Future<void> _sendAlertToPairedRequesters({
  required String type,
  Map<String, dynamic> extraData = const {},
}) async {
  final groupId = await IdentityService.getGroupId();
  final locatorId = await IdentityService.getLocatorId();
  final locatorName = await IdentityService.getLocatorName();
  final locatorCode = await IdentityService.getLocatorCode();

  if (groupId == null || locatorId == null) {
    Log.d("BEACON ALERT => missing group/locator");
    return;
  }

  final notifyField = _notifyFieldForType(type);

  if (notifyField.isEmpty) {
    Log.d("BEACON ALERT => unknown notify field for type=$type");
    return;
  }

  final locatorDeviceDoc = await _firestore
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(locatorId)
      .get();

  final data = locatorDeviceDoc.data();

  if (data == null) {
    Log.d("BEACON ALERT => locator device doc not found");
    return;
  }

  final pairedRequesters = Map<String, dynamic>.from(
    data['pairedRequesters'] ?? {},
  );

  if (pairedRequesters.isEmpty) {
    Log.d("BEACON ALERT => no paired requesters");
    return;
  }

  int sentCount = 0;

  for (final requesterId in pairedRequesters.keys) {
    final notifyDoc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(locatorId)
        .collection('notifyRequesters')
        .doc(requesterId)
        .get();

    final notifyData = notifyDoc.data() ?? {};

    if (notifyData[notifyField] != true) {
      Log.d(
        "BEACON ALERT => skipped $requesterId "
        "type=$type notifyField=$notifyField",
      );
      continue;
    }

    final alertId = const Uuid().v4();

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('alerts')
        .doc(requesterId)
        .collection('items')
        .doc(alertId)
        .set({
      'alertId': alertId,
      'groupId': groupId,
      'type': type,
      'locatorId': locatorId,
      'locatorName': locatorName ?? 'Locator',
      'locatorCode': locatorCode ?? '------',
      'targetRequesterId': requesterId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      ...extraData,
    });

    sentCount++;
  }

  Log.d(
    "BEACON ALERT => $type sentCount=$sentCount",
  );
}
	

	
	static String _notifyFieldForType(String type) {
		switch (type) {
			
			case 'call_me':
      return 'callMe';
			
			case 'gps_off':
				return 'gpsOff';

			case 'battery_low':
				return 'batteryLow';

			case 'place_enter':
			case 'place_exit':
				return 'geofence';
				
			case 'movement':
				return 'movement';	

			default:
				return '';
		}
	}	


}