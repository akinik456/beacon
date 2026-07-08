import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';
import '../../l10n/app_localizations.dart';
import '../../services/identity_service.dart';
import '../../utils/log.dart';


class RequesterListCard extends StatelessWidget {
  final String groupId;

  const RequesterListCard({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
	final l10n = AppLocalizations.of(context)!;
	
	
    return FutureBuilder<Map<String, String?>>(
  future: () async {
    return {
      'id': await IdentityService.getRequesterId(),
      'name': await IdentityService.getRequesterName(),
    };
  }(),
  builder: (context, mySnapshot) {
    final myRequesterId = mySnapshot.data?['id'];
    final myRequesterName = mySnapshot.data?['name'];

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('devices')
          .where('role', isEqualTo: 'requester')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = [...(snapshot.data?.docs ?? [])];

        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        docs.sort((a, b) {
          final aData = a.data();
          final bData = b.data();

          final aMaster = aData['isMaster'] == true;
          final bMaster = bData['isMaster'] == true;

          if (aMaster && !bMaster) return -1;
          if (!aMaster && bMaster) return 1;

          final aName =
              (aData['name'] ?? '').toString().toLowerCase();
          final bName =
              (bData['name'] ?? '').toString().toLowerCase();

          return aName.compareTo(bName);
        });

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
								  '${l10n.requesters} ${docs.length}',
                  style: AppFonts.subtitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 2),

                ...docs.map((doc) {
  final data = doc.data();
  final requesterId = doc.id;

  final isMasterMember = data['isMaster'] == true;

  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    future: FirebaseFirestore.instance
        .collection('requesters')
        .doc(requesterId)
        .get(),
    builder: (context, rootSnapshot) {
      final rootData = rootSnapshot.data?.data() ?? {};

      final name = rootData['name'] ??
          rootData['requesterName'] ??
          data['requesterName'] ??
          'Requester';

      final code = rootData['requesterCode'] ??
          data['requesterCode'] ??
          '';

      return Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: SizedBox(
          height: 30,
          child: Row(
            children: [
              Icon(
                isMasterMember
                    ? Icons.workspace_premium_rounded
                    : Icons.person_rounded,
                color: AppColors.primary,
                size: 18,
              ),

              const SizedBox(width: 6),

              Expanded(
                /*child: Text(
                  '$name - $code',
                  style: AppFonts.body.copyWith(
                    height: 1.0,
                  ),
                ),*/
								
								child: RichText(
									overflow: TextOverflow.ellipsis,
									text: TextSpan(
										children: [
											TextSpan(
												text: '$name',
												style: AppFonts.subtitle.copyWith(
													color: AppColors.textPrimary,
													fontWeight: FontWeight.w700
												),
											),

											TextSpan(
												text: ' - $code',
												style: AppFonts.subtitle.copyWith(
													color: AppColors.textSecondary,
													fontSize:12,
												),
											),
										],
									),
								),
								
              ),

              if (isMasterMember)
                Text(
                  l10n.master,
                  style: AppFonts.caption.copyWith(
                    color: AppColors.primary,
                    height: 1.0,
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () async {
                    final groupRef = FirebaseFirestore.instance
                        .collection('groups')
                        .doc(groupId);

                    final requesterRef = groupRef
                        .collection('devices')
                        .doc(requesterId);

                    await FirebaseFirestore.instance
                        .runTransaction((tx) async {
                      tx.delete(requesterRef);

                      tx.update(groupRef, {
                        'activeRequesterCount':
                            FieldValue.increment(-1),
                        'updatedAt':
                            FieldValue.serverTimestamp(),
                      });
                    });

                    Log.d(
                      "BEACON REQUESTER REMOVED => $requesterId",
                    );
                  },
									style: TextButton.styleFrom(
										padding: const EdgeInsets.symmetric(horizontal: 6),
										minimumSize: const Size(0, 30),
										tapTargetSize: MaterialTapTargetSize.shrinkWrap,
									),
                  icon: Icon(
                    Icons.person_remove_rounded,
                    color: AppColors.danger,
                    size: 18,
                  ),
									label: Text(
										l10n.removeFromGroup,
										style: AppFonts.caption.copyWith(
											color: AppColors.danger,
											fontWeight: FontWeight.w600,
										),
									),
                ),
            ],
          ),
        ),
      );
    },
  );
}),
              ],
            ),
          ),
        );
      },
    );
		},
);
		
  }
}