import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import 'group_service.dart';
import 'identity_service.dart';

class LocatorListService {
  LocatorListService._();

  static final _firestore = FirebaseFirestore.instance;
	static final _rtdb = FirebaseDatabase.instance;
	
  static Future<List<Map<String, dynamic>>> loadLocators() async {
    try {
      final groupId = await GroupService.getLocalGroupId();
      final requesterId = await IdentityService.getRequesterId();

      if (groupId == null || requesterId == null) {
        return [];
      }

      final requesterDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('devices')
          .doc(requesterId)
          .get();

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

        final presenceSnapshot = await _rtdb
						.ref('presence/groups/$groupId/locators/$locatorId')
						.get();

				final presenceData = presenceSnapshot.value is Map
						? Map<String, dynamic>.from(presenceSnapshot.value as Map)
						: <String, dynamic>{};

				result.add({
					'locatorId': locatorId,
					'address': 'Resolving address...',
					...locatorDoc.data()!,
					...presenceData,
				});
      }

      return result;

    } catch (e) {
      print("BEACON LOCATOR LIST ERROR => $e");
      return [];
    }
  }
}