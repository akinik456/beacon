import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class SosService {
  SosService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<void> createSos({
		required String groupId,
		required String targetRequesterId,
	}) async {
		final locatorId = await IdentityService.getLocatorId();
		final locatorName = await IdentityService.getLocatorName();
		final locatorCode = await IdentityService.getLocatorCode();

		if (locatorId == null || targetRequesterId.isEmpty) {
			return;
		}

		final sosId = const Uuid().v4();

		await _firestore
				.collection('groups')
				.doc(groupId)
				.collection('sos')
				.doc(targetRequesterId)
				.collection('items')
				.doc(sosId)
				.set({
			'sosId': sosId,
			'groupId': groupId,
			'locatorId': locatorId,
			'locatorName': locatorName ?? 'Member',
			'locatorCode': locatorCode ?? '------',
			'targetRequesterId': targetRequesterId,
			'status': 'pending',
			'createdAt': FieldValue.serverTimestamp(),
		});

		Log.d(
			"BEACON SOS => created => $sosId => $targetRequesterId",
		);
	}
	static Future<void> sendSosToAll() async {
  final groupId = await IdentityService.getGroupId();
  final locatorId = await IdentityService.getLocatorId();

  if (groupId == null || locatorId == null) {
    Log.d("BEACON SOS => groupId/locatorId missing");
    return;
  }

  final locatorDoc = await _firestore
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(locatorId)
      .get();

  final data = locatorDoc.data();

  if (data == null) {
    Log.d("BEACON SOS => locator device missing");
    return;
  }

  final pairedRequesters = Map<String, dynamic>.from(
    data['pairedRequesters'] ?? {},
  );

  if (pairedRequesters.isEmpty) {
    Log.d("BEACON SOS => no paired requester");
    return;
  }

  for (final requesterId in pairedRequesters.keys) {
    await createSos(
      groupId: groupId,
      targetRequesterId: requesterId,
    );
  }

  Log.d(
    "BEACON SOS => sent to ${pairedRequesters.length} requester",
  );
}
}