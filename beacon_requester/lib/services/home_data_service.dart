import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'identity_service.dart';

class HomeDataService {
  HomeDataService._();

  static final _firestore = FirebaseFirestore.instance;

  static const _groupIdKey = 'group_id';

  static Future<Map<String, dynamic>?> loadHomeData() async {
    try {
      // requesterId
      final requesterId =
          await IdentityService.getRequesterId();
					
			final requesterName =
          await IdentityService.getRequesterName();		

      // local groupId
      final prefs = await SharedPreferences.getInstance();

      final groupId = prefs.getString(_groupIdKey);

      if (groupId == null || groupId.isEmpty) {
				print("BEACON HOME => groupId not found");

				return {
					'hasGroup': false,
					'requesterId': requesterId,
					'groupId': null,
					'groupName': null,
					'requesterName': requesterName,
					'pairedLocators': <String, dynamic>{},
				};
			}

      // group doc
      final groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        print("BEACON HOME => group not found");
        return null;
      }

      final groupData = groupDoc.data()!;

      // requester device doc
      final requesterDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('devices')
          .doc(requesterId)
          .get();

      if (!requesterDoc.exists) {
				return {
					'hasGroup': true,
					'isPending': true,
					'groupId': groupId,
					'groupName': groupData['groupName'],
					'requesterId': requesterId,
					'requesterName': requesterName,
					'pairedLocators': <String, dynamic>{},
				};
			}

      final requesterData = requesterDoc.data()!;

      // paired locators
      final pairedLocators =
          Map<String, dynamic>.from(
        requesterData['pairedLocators'] ?? {},
      );

      return {
				'hasGroup': true,
        'groupId': groupId,
        'groupName': groupData['groupName'],
        'requesterId': requesterId,
        'requesterName': requesterName,
        'pairedLocators': pairedLocators,
      };
    } catch (e) {
      print("BEACON HOME LOAD ERROR => $e");
      return null;
    }
  }
}