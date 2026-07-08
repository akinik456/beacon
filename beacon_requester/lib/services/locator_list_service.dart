import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import 'group_service.dart';
import 'identity_service.dart';
import '../utils/log.dart';


class LocatorListService {
  LocatorListService._();

  static final _firestore = FirebaseFirestore.instance;
	static final _rtdb = FirebaseDatabase.instance;
	
  static Future<List<Map<String, dynamic>>> loadLocators() async {
    try {
      final groupId = await GroupService.getLocalGroupId();
      final requesterId = await IdentityService.getRequesterId();
			Log.d("BEACON LOCATOR LIST => groupId=$groupId requesterId=$requesterId");

      if (groupId == null || requesterId == null) {
        return [];
      }

      final requesterDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('devices')
          .doc(requesterId)
          .get();
			Log.d(
				"BEACON LOCATOR LIST => requesterDoc exists=${requesterDoc.exists}",
			);
      if (!requesterDoc.exists) {
        return [];
      }

      final requesterData = requesterDoc.data()!;

      final pairedLocators =
          Map<String, dynamic>.from(
        requesterData['pairedLocators'] ?? {},
      );

      final List<Map<String, dynamic>> result = [];

      for (final locatorId in pairedLocators.keys) {
			final pairData =
			pairedLocators[locatorId] is Map
        ? Map<String, dynamic>.from(
            pairedLocators[locatorId],
          )
        : <String, dynamic>{};
        final locatorDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('devices')
            .doc(locatorId)
            .get();

        if (!locatorDoc.exists) continue;
				
				final rootLocatorDoc = await _firestore
						.collection('locators')
						.doc(locatorId)
						.get();

				final rootLocatorData = rootLocatorDoc.data() ?? {};

				final locatorName =
						rootLocatorData['locatorName'] ??
						locatorDoc.data()?['locatorName'] ??
						pairData['locatorName'] ??
						'-';

        final presenceSnapshot = await _rtdb
						.ref('presence/groups/$groupId/locators/$locatorId')
						.get();

				final presenceData = presenceSnapshot.value is Map
						? Map<String, dynamic>.from(presenceSnapshot.value as Map)
						: <String, dynamic>{};
						
				final settingsDoc = await _firestore
						.collection('groups')
						.doc(groupId)
						.collection('devices')
						.doc(locatorId)
						.collection('settings')
						.doc('config')
						.get();

				final settingsData = settingsDoc.data() ?? {};

				final notifyDoc = await _firestore
						.collection('groups')
						.doc(groupId)
						.collection('devices')
						.doc(locatorId)
						.collection('notify')
						.doc(requesterId)
						.get();

				final notifyData = notifyDoc.data() ?? {};		

				result.add({
					'locatorId': locatorId,
					'locatorName': locatorName,
					'address': '',
					...locatorDoc.data()!,
					...pairData,
					...presenceData,
					'movementAlert': settingsData['movementAlert'] ?? true,
					'movement': notifyData['movement'] ?? true,
					'locatorName': locatorName,
				});
			Log.d("BEACON LOCATOR LIST => loading locatorId=$locatorId");
			
			

Log.d(
  "BEACON LOCATOR LIST => deviceDoc exists=${locatorDoc.exists}",
);	
      }
			Log.d("BEACON LOCATOR LIST => result=${result.length}");

      return result;

    } catch (e) {
      Log.e("BEACON LOCATOR LIST ERROR => $e");
      return [];
    }
  }
}