import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class HomeDataService {
  HomeDataService._();

  static final _firestore = FirebaseFirestore.instance;

  static const _groupIdKey = 'group_id';
  static const _pendingGroupIdKey = 'pending_group_id';
  static const _joinStatusKey = 'join_status';

  static Future<Map<String, dynamic>> loadHomeData() async {
    Log.d("BEACON HOME => loadHomeData");

    String? requesterId;
    String? requesterName;

    try {
      requesterId = await IdentityService.getRequesterId();
      requesterName = await IdentityService.getRequesterName();
	Log.d("homedataservice");
      if (requesterId == null ||
          requesterId.isEmpty ||
          requesterName == null ||
          requesterName.isEmpty) {
        Log.d("BEACON HOME => requester identity missing");

        return _empty(
          hasIdentity: false,
          requesterId: requesterId,
          requesterName: requesterName,
        );
      }

      final prefs = await SharedPreferences.getInstance();

      final requesterRootDoc = await _firestore
          .collection('requesters')
          .doc(requesterId)
          .get();

      final requesterRootData = requesterRootDoc.data() ?? {};
      final rootGroupId = requesterRootData['groupId'] as String?;

      if (rootGroupId != null && rootGroupId.isNotEmpty) {
        Log.d("BEACON HOME => root groupId found");

        await prefs.setString(_groupIdKey, rootGroupId);
        await prefs.remove(_pendingGroupIdKey);
        await prefs.remove(_joinStatusKey);

        return _loadApprovedGroup(
          groupId: rootGroupId,
          requesterId: requesterId,
          requesterName: requesterName,
          prefs: prefs,
        );
      }

      Log.d("BEACON HOME => root groupId not found");

      final pendingGroupId = prefs.getString(_pendingGroupIdKey);

      if (pendingGroupId == null || pendingGroupId.isEmpty) {
        await prefs.remove(_groupIdKey);
        await prefs.remove(_joinStatusKey);

        return _empty(
          hasIdentity: true,
          requesterId: requesterId,
          requesterName: requesterName,
        );
      }

      return _loadPendingJoin(
        pendingGroupId: pendingGroupId,
        requesterId: requesterId,
        requesterName: requesterName,
        prefs: prefs,
      );
    } catch (e) {
      Log.e("BEACON HOME LOAD ERROR => $e");

      return _empty(
        hasIdentity: requesterId != null &&
            requesterId.isNotEmpty &&
            requesterName != null &&
            requesterName.isNotEmpty,
        requesterId: requesterId,
        requesterName: requesterName,
      );
    }
  }

  static Future<Map<String, dynamic>> _loadApprovedGroup({
    required String groupId,
    required String requesterId,
    required String requesterName,
    required SharedPreferences prefs,
  }) async {
    final groupDoc = await _firestore.collection('groups').doc(groupId).get();

    if (!groupDoc.exists) {
      Log.d("BEACON HOME => approved group not found");

      await _firestore.collection('requesters').doc(requesterId).set({
        'groupId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await prefs.remove(_groupIdKey);

      return _empty(
        hasIdentity: true,
        requesterId: requesterId,
        requesterName: requesterName,
      );
    }

    final groupData = groupDoc.data()!;

    final requesterDeviceDoc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(requesterId)
        .get();

    if (!requesterDeviceDoc.exists) {
      Log.d("BEACON HOME => requester removed from group");

      await _firestore.collection('requesters').doc(requesterId).set({
        'groupId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await prefs.remove(_groupIdKey);

      return _empty(
        hasIdentity: true,
        requesterId: requesterId,
        requesterName: requesterName,
      );
    }

    final requesterData = requesterDeviceDoc.data()!;

    final pairedLocators = Map<String, dynamic>.from(
      requesterData['pairedLocators'] ?? {},
    );

    return {
      'hasIdentity': true,
      'hasGroup': true,
      'isPending': false,
      'groupId': groupId,
      'pendingGroupId': null,
      'groupName': groupData['groupName'],
      'requesterId': requesterId,
      'requesterName': requesterName,
      'pairedLocators': pairedLocators,
    };
  }

  static Future<Map<String, dynamic>> _loadPendingJoin({
    required String pendingGroupId,
    required String requesterId,
    required String requesterName,
    required SharedPreferences prefs,
  }) async {
    final groupDoc =
        await _firestore.collection('groups').doc(pendingGroupId).get();

    if (!groupDoc.exists) {
      Log.d("BEACON HOME => pending group not found");

      await _clearPendingJoin(prefs);

      return _empty(
        hasIdentity: true,
        requesterId: requesterId,
        requesterName: requesterName,
      );
    }

    final groupData = groupDoc.data()!;

    final joinRequestDoc = await _firestore
        .collection('groups')
        .doc(pendingGroupId)
        .collection('join_requests')
        .doc(requesterId)
        .get();

    if (!joinRequestDoc.exists) {
      Log.d("BEACON HOME => pending join request not found");

      await _clearPendingJoin(prefs);

      return _empty(
        hasIdentity: true,
        requesterId: requesterId,
        requesterName: requesterName,
      );
    }

    final joinData = joinRequestDoc.data() ?? {};
    final status = joinData['status'] ?? 'pending';

    if (status == 'pending') {
      Log.d("BEACON HOME => requester join pending");

      return {
        'hasIdentity': true,
        'hasGroup': false,
        'isPending': true,
        'groupId': null,
        'pendingGroupId': pendingGroupId,
        'groupName': groupData['groupName'],
        'requesterId': requesterId,
        'requesterName': requesterName,
        'pairedLocators': <String, dynamic>{},
      };
    }

    if (status == 'approved') {
      Log.d("BEACON HOME => requester join approved");

      final requesterDeviceDoc = await _firestore
          .collection('groups')
          .doc(pendingGroupId)
          .collection('devices')
          .doc(requesterId)
          .get();

      if (!requesterDeviceDoc.exists) {
        Log.d("BEACON HOME => approved but requester device missing");

        return {
          'hasIdentity': true,
          'hasGroup': false,
          'isPending': true,
          'groupId': null,
          'pendingGroupId': pendingGroupId,
          'groupName': groupData['groupName'],
          'requesterId': requesterId,
          'requesterName': requesterName,
          'pairedLocators': <String, dynamic>{},
        };
      }

      await _firestore.collection('requesters').doc(requesterId).set({
        'groupId': pendingGroupId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await prefs.setString(_groupIdKey, pendingGroupId);
      await prefs.remove(_pendingGroupIdKey);
      await prefs.remove(_joinStatusKey);

      await joinRequestDoc.reference.delete();

      return _loadApprovedGroup(
        groupId: pendingGroupId,
        requesterId: requesterId,
        requesterName: requesterName,
        prefs: prefs,
      );
    }

    if (status == 'rejected') {
      Log.d("BEACON HOME => requester join rejected");

      await _clearPendingJoin(prefs);

      return {
        'hasIdentity': true,
        'hasGroup': false,
        'isPending': false,
        'isRejected': true,
        'groupId': null,
        'pendingGroupId': null,
        'groupName': groupData['groupName'],
        'requesterId': requesterId,
        'requesterName': requesterName,
        'pairedLocators': <String, dynamic>{},
      };
    }

    Log.d("BEACON HOME => unknown join status => $status");

    await _clearPendingJoin(prefs);

    return _empty(
      hasIdentity: true,
      requesterId: requesterId,
      requesterName: requesterName,
    );
  }

  static Future<void> _clearPendingJoin(
    SharedPreferences prefs,
  ) async {
    await prefs.remove(_pendingGroupIdKey);
    await prefs.remove(_groupIdKey);
    await prefs.remove(_joinStatusKey);
  }

  static Map<String, dynamic> _empty({
    required bool hasIdentity,
    required String? requesterId,
    required String? requesterName,
  }) {
    return {
      'hasIdentity': hasIdentity,
      'hasGroup': false,
      'isPending': false,
      'isRejected': false,
      'groupId': null,
      'pendingGroupId': null,
      'groupName': null,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'pairedLocators': <String, dynamic>{},
    };
  }
}