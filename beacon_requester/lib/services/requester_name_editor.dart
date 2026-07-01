import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'identity_service.dart';
import '../core/widgets/app_banner.dart';
import '../core/widgets/dialogs/app_input_dialog.dart';


class RequesterNameEditor {
  RequesterNameEditor._();

  static Future<bool> edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final currentName =
        await IdentityService.getRequesterName();

    final controller = TextEditingController(
      text: currentName ?? '',
    );

    final newName = await AppInputDialog.show(
			context: context,
			title: l10n.enteryourname,
			hintText: l10n.requesterName,
			confirmText: l10n.sva,
			cancelText: l10n.cancel,
			autofocus: true,
			maxLength: 20,
		);

    if (newName == null || newName.isEmpty) {
      return false;
    }

    if (newName == currentName) {
      return false;
    }

    final requesterId =
        await IdentityService.getRequesterId();

    if (requesterId == null ||
        requesterId.isEmpty) {
      return false;
    }

    await FirebaseFirestore.instance
				.collection('requesters')
				.doc(requesterId)
				.set({
			'requesterId': requesterId,
			'name': newName,
			'requesterName': newName,
			'updatedAt': FieldValue.serverTimestamp(),
		}, SetOptions(merge: true));

    await IdentityService.setRequesterName(
      newName,
    );

    if (!context.mounted) {
      return false;
    }
    AppBanner.success(
			context,
			l10n.saved,
		);
    return true;
  }
}