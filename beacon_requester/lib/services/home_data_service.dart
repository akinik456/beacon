import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'identity_service.dart';

class HomeDataService {
  HomeDataService._();

  static final _firestore = FirebaseFirestore.instance;

  static const _groupIdKey = 'group_id';

  static Future<Map<String, dynamic>> loadHomeData() async {
    String? requesterId;
    String? requesterName;

    try {
      requesterId = await IdentityService.getRequesterId();
      requesterName = await IdentityService.getRequesterName();

      if (requesterId == null ||
          requesterId.isEmpty ||
          requesterName == null ||
          requesterName.isEmpty) {
        print("BEACON HOME => requester identity missing");

        return {
          'hasIdentity': false,
          'hasGroup': false,
          'isPending': false,
          'requesterId': requesterId,
          'requesterName': requesterName,
          'groupId': null,
          'groupName': null,
          'pairedLocators': <String, dynamic>{},
        };
      }

      final prefs = await SharedPreferences.getInstance();
      final groupId = prefs.getString(_groupIdKey);

      if (groupId == null || groupId.isEmpty) {
        print("BEACON HOME => groupId not found");

        return {
          'hasIdentity': true,
          'hasGroup': false,
          'isPending': false,
          'requesterId': requesterId,
          'requesterName': requesterName,
          'groupId': null,
          'groupName': null,
          'pairedLocators': <String, dynamic>{},
        };
      }

      final groupDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        print("BEACON HOME => group not found");

        return {
          'hasIdentity': true,
          'hasGroup': false,
          'isPending': false,
          'requesterId': requesterId,
          'requesterName': requesterName,
          'groupId': null,
          'groupName': null,
          'pairedLocators': <String, dynamic>{},
        };
      }

      final groupData = groupDoc.data()!;

      final requesterDoc = await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('devices')
          .doc(requesterId)
          .get();

      if (!requesterDoc.exists) {
        final joinRequestDoc = await _firestore
            .collection('groups')
            .doc(groupId)
            .collection('join_requests')
            .doc(requesterId)
            .get();

        if (joinRequestDoc.exists) {
          print("BEACON HOME => requester join pending");

          return {
            'hasIdentity': true,
            'hasGroup': true,
            'isPending': true,
            'groupId': groupId,
            'groupName': groupData['groupName'],
            'requesterId': requesterId,
            'requesterName': requesterName,
            'pairedLocators': <String, dynamic>{},
          };
        }

        print("BEACON HOME => requester removed from group");

        return {
          'hasIdentity': true,
          'hasGroup': false,
          'isPending': false,
          'requesterId': requesterId,
          'requesterName': requesterName,
          'groupId': null,
          'groupName': null,
          'pairedLocators': <String, dynamic>{},
        };
      }

      final requesterData = requesterDoc.data()!;

      final pairedLocators = Map<String, dynamic>.from(
        requesterData['pairedLocators'] ?? {},
      );

      return {
        'hasIdentity': true,
        'hasGroup': true,
        'isPending': false,
        'groupId': groupId,
        'groupName': groupData['groupName'],
        'requesterId': requesterId,
        'requesterName': requesterName,
        'pairedLocators': pairedLocators,
      };
    } catch (e) {
      print("BEACON HOME LOAD ERROR => $e");

      return {
        'hasIdentity': requesterId != null &&
            requesterId.isNotEmpty &&
            requesterName != null &&
            requesterName.isNotEmpty,
        'hasGroup': false,
        'isPending': false,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'groupId': null,
        'groupName': null,
        'pairedLocators': <String, dynamic>{},
      };
    }
  }
}