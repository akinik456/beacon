import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'identity_service.dart';
import '../core/widgets/app_banner.dart';

class RequesterNameEditor {
  RequesterNameEditor._();

  static Future<bool> edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final currentName =
        await IdentityService.getRequesterName();

    final controller = TextEditingController(
      text: currentName ?? '',
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.enteryourname),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 20,
            decoration: const InputDecoration(
              hintText: 'Requester name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: Text(l10n.sva),
            ),
          ],
        );
      },
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
    AppBanner.info(
			context,
			l10n.saved,
		);
    return true;
  }
}