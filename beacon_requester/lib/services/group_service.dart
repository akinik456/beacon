import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'identity_service.dart';
import 'code_service.dart';


class GroupService {
  GroupService._();

  static final _firestore = FirebaseFirestore.instance;

  static const _groupIdKey = 'group_id';

  static Future<String> createGroup({
    required String groupName,
    required String requesterName,
  }) async {
    final requesterId = await IdentityService.getRequesterId();
		final requesterCode = await IdentityService.getRequesterCode();
    final groupId = const Uuid().v4();
		final groupCode = CodeService.generateShortCode();
		
    final groupRef = _firestore.collection('groups').doc(groupId);
    final requesterRef = groupRef.collection('devices').doc(requesterId);

    final now = FieldValue.serverTimestamp();

    await _firestore.runTransaction((tx) async {
      tx.set(groupRef, {
        'groupId': groupId,
        'groupName': groupName.trim(),
				'groupCode': groupCode,
        'masterRequesterId': requesterId,
        'planStatus': 'trial',
        'maxRequesters': 1,
        'maxLocators': 1,
        'createdAt': now,
        'trialStartedAt': now,
      });

      tx.set(requesterRef, {
				'requesterId': requesterId,
				'requesterCode': requesterCode,
				'role': 'requester',
				'name': requesterName.trim(),
				'isMaster': true,
				'active': true,
				'pairedLocators': {},
				'joinedAt': now,
				'createdAt': now,
			});
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groupIdKey, groupId);
		await prefs.setString('group_code', groupCode);
		
    print("BEACON GROUP => CREATE SUCCESS => $groupId");

    return groupId;
  }

  static Future<String?> getLocalGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_groupIdKey);
  }

	static Future<String?> getLocalGroupCode() async {
		final prefs = await SharedPreferences.getInstance();

		final groupCode = prefs.getString('group_code');

		if (groupCode != null && groupCode.isNotEmpty) {

			print(
				"BEACON GROUP => groupCode found => "
				"$groupCode",
			);

			return groupCode;
		}

		print("BEACON GROUP => groupCode not found");

		return null;
	}	
	
}