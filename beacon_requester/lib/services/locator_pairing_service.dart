import 'package:cloud_firestore/cloud_firestore.dart';
import 'code_service.dart';
import 'identity_service.dart';
import 'group_service.dart';

class LocatorPairingService {
  LocatorPairingService._();

  static final _firestore =
      FirebaseFirestore.instance;
			

		
		static Future<void> sendPairingRequest({
		required String locatorInput,

	}) async {
		try {
		
			final requesterId =
			await IdentityService.getRequesterId();
			
			final requesterName =
    await IdentityService.getRequesterName();
			
			final groupId =
			await GroupService.getLocalGroupId();	
			
			final normalized =
					CodeService.normalizeCode(locatorInput);

			String locatorId;

			// SHORT CODE
			if (CodeService.isValidCode(normalized)) {
				final query = await _firestore
						.collection('locators')
						.where(
							'locatorCode',
							isEqualTo: normalized,
						)
						.limit(1)
						.get();

				if (query.docs.isEmpty) {
					print(
						"BEACON PAIRING => "
						"LOCATOR NOT FOUND",
					);
					return;
				}

				locatorId = query.docs.first.id;
			}

			// FULL LOCATOR ID
			else {
				locatorId = locatorInput.trim();
			}

			await _firestore
					.collection('locators')
					.doc(locatorId)
					.collection('pairing_requests')
					.doc()
					.set({
				'requesterId': requesterId,
				'requesterName': requesterName,
				'groupId': groupId,
				'status': 'pending',
				'createdAt':
						FieldValue.serverTimestamp(),
			});

			print(
				"BEACON PAIRING => REQUEST SENT "
				"=> locator:$locatorId",
			);
		} catch (e) {
			print(
				"BEACON PAIRING ERROR => $e",
			);
		}
	}
}