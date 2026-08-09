import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class HomeDataService {
  HomeDataService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> loadHomeData() async {
    Log.d("BEACON HOME => loadHomeData");

    String? requesterId;
    String? requesterName;

    try {
      requesterId = await IdentityService.getRequesterId();
      requesterName = await IdentityService.getRequesterName();

      if (requesterId == null ||
          requesterId.isEmpty ||
          requesterName == null ||
          requesterName.isEmpty) {
        Log.d(
          "BEACON HOME => requester identity missing",
        );

        return _empty(
          hasIdentity: false,
          requesterId: requesterId,
          requesterName: requesterName,
        );
      }

      final requesterDoc = await _firestore
          .collection('requesters')
          .doc(requesterId)
          .get();

      final requesterData = requesterDoc.data() ?? {};
      final pairedLocators =
          Map<String, dynamic>.from(
        requesterData['pairedLocators'] ?? {},
      );

      return {
        'hasIdentity': true,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'pairedLocators': pairedLocators,
        ...requesterData,
      };
    } catch (e) {
      Log.e(
        "BEACON HOME => loadHomeData error => $e",
      );

      return _empty(
        hasIdentity: requesterId != null &&
            requesterId.isNotEmpty,
        requesterId: requesterId,
        requesterName: requesterName,
      );
    }
  }

  static Map<String, dynamic> _empty({
    required bool hasIdentity,
    required String? requesterId,
    required String? requesterName,
  }) {
    return {
      'hasIdentity': hasIdentity,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'pairedLocators': <String, dynamic>{},
    };
  }
}