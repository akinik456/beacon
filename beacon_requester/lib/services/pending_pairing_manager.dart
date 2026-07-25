import 'dart:async';

import '../utils/log.dart';
import 'pairing_response_service.dart';
import 'pending_pairing_service.dart';
import 'group_service.dart';

class PendingPairingManager {
  PendingPairingManager._();

  static StreamSubscription? _subscription;

  static Future<void> start({
		Future<void> Function()? onApproved,
		Future<void> Function()? onRejected,
	}) async {
    await stop();

    final pending =
        await PendingPairingService.load();

    if (pending == null) {
      Log.d(
        "BEACON PAIRING => "
        "no pending pairing",
      );
      return;
    }

    final locatorId =
        pending['locatorId']!;

    final requestId =
        pending['requestId']!;

    Log.d(
      "BEACON PAIRING => "
      "resume locator=$locatorId "
      "request=$requestId",
    );

    _subscription = PairingResponseService
        .watchPairingResponse(
          locatorId: locatorId,
          requestId: requestId,
        )
        .listen((snapshot) async {
      final data = snapshot.data();

      if (data == null) return;

      final status =
          data['status'] ?? 'pending';

      if (status == 'pending') return;

			Log.d(
				"BEACON PAIRING => "
				"MANAGER status=$status",
			);

			await stop();

			if (status == 'approved') {
				await GroupService.addPairedLocatorToRequester(
					locatorId: locatorId,
				);

				await GroupService.addPairedRequesterToLocator(
					locatorId: locatorId,
				);

				await GroupService.ensureLocatorDefaultSettings(
					locatorId: locatorId,
				);

				await GroupService.ensureRequesterNotifySettings(
					locatorId: locatorId,
				);
			}

			await PairingResponseService.deletePairingRequest(
				locatorId: locatorId,
				requestId: requestId,
			);

			await PendingPairingService.clear();
			
			if (status == 'approved') {
				if (onApproved != null) {
					await onApproved();
				}
			} else {
				if (onRejected != null) {
					await onRejected();
				}
			}

			Log.d(
				"BEACON PAIRING => "
				"MANAGER completed status=$status",
			);
    });
  }

  static Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}