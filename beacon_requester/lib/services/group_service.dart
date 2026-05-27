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
    final groupCode = CodeService.shortCodeFromId(groupId);

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

  static Future<String?> joinGroup({
    required String groupCode,
    required String requesterName,
  }) async {
    final requesterId = await IdentityService.getRequesterId();

    final requesterCode = await IdentityService.getRequesterCode();

    if (requesterId == null) {
      print("BEACON GROUP => requesterId not found");

      return null;
    }

    // groupCode normalize
    final normalizedCode = CodeService.normalizeCode(groupCode);

    // group bul
    final query = await _firestore
        .collection('groups')
        .where('groupCode', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      print("BEACON GROUP => group not found");

      return null;
    }

    final groupDoc = query.docs.first;

    final groupId = groupDoc.id;

    final groupRef = _firestore.collection('groups').doc(groupId);

    final requesterRef = groupRef.collection('devices').doc(requesterId);

    final result = await _firestore.runTransaction<String>((tx) async {
      final freshGroup = await tx.get(groupRef);

      final groupData = freshGroup.data() ?? {};

      final maxRequesters = groupData['maxRequesters'] ?? 1;

      final activeRequesterCount = groupData['activeRequesterCount'] ?? 0;

      if (activeRequesterCount >= maxRequesters) {
        return 'rejected_capacity';
      }

      final now = FieldValue.serverTimestamp();

      tx.set(requesterRef, {
        'requesterId': requesterId,
        'requesterCode': requesterCode,
        'role': 'requester',
        'name': requesterName.trim(),
        'isMaster': false,
        'active': true,
        'pairedLocators': {},
        'joinedAt': now,
        'createdAt': now,
      });

      tx.update(groupRef, {
        'activeRequesterCount': FieldValue.increment(1),

        'updatedAt': FieldValue.serverTimestamp(),
      });

      return groupId;
    });

    if (result == 'rejected_capacity') {
      return 'rejected_capacity';
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_groupIdKey, groupId);

    await prefs.setString('group_code', normalizedCode);

    print(
      "BEACON GROUP => JOIN SUCCESS "
      "=> $groupId",
    );

    return groupId;
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
