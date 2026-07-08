import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/log.dart';

class LocatorListCard extends StatelessWidget {
  final String groupId;
  final bool isMaster;
	final VoidCallback? onChanged;
	
  const LocatorListCard({
    super.key,
    required this.groupId,
    required this.isMaster,
		required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('devices')
          .where('role', isEqualTo: 'locator')
          .where('active', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = [...(snapshot.data?.docs ?? [])];

        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        docs.sort((a, b) {
          final aName =
              (a.data()['name'] ?? '').toString().toLowerCase();
          final bName =
              (b.data()['name'] ?? '').toString().toLowerCase();

          return aName.compareTo(bName);
        });

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.members} ${docs.length}',
                  style: AppFonts.subtitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 2),

                ...docs.map((doc) {
									final locatorId = doc.id;
									final deviceData = doc.data();

									return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
										future: FirebaseFirestore.instance
												.collection('locators')
												.doc(locatorId)
												.get(),
										builder: (context, rootSnapshot) {
											final rootData = rootSnapshot.data?.data() ?? {};

											final name =
													rootData['locatorName'] ??
													rootData['name'] ??
													deviceData['name'] ??
													deviceData['locatorName'] ??
													'Member';

											final code =
													rootData['locatorCode'] ??
													deviceData['locatorCode'] ??
													'';

											return Padding(
												padding: const EdgeInsets.only(bottom: 0),
												child: SizedBox(
													height: 30,
													child: Row(
														children: [
															Icon(
																Icons.person_pin_circle_rounded,
																color: AppColors.primary,
																size: 18,
															),
															const SizedBox(width: 6),
															Expanded(
																child: RichText(
																	overflow: TextOverflow.ellipsis,
																	text: TextSpan(
																		children: [
																			TextSpan(
																				text: '$name',
																				style: AppFonts.subtitle.copyWith(
																					color: AppColors.textPrimary,
																					fontWeight: FontWeight.w700,
																				),
																			),
																			TextSpan(
																				text: code.toString().isNotEmpty
																						? ' - $code'
																						: '',
																				style: AppFonts.subtitle.copyWith(
																					color: AppColors.textSecondary,
																					fontSize: 12,
																				),
																			),
																		],
																	),
																),
															),

															if (isMaster)
																	TextButton.icon(
																	onPressed: () async {
																		final groupRef = FirebaseFirestore.instance
																				.collection('groups')
																				.doc(groupId);

																		final locatorDeviceRef = groupRef
																				.collection('devices')
																				.doc(locatorId);

																		final locatorRootRef = FirebaseFirestore.instance
																				.collection('locators')
																				.doc(locatorId);

																		final requesterDocs = await groupRef
																				.collection('devices')
																				.where('role', isEqualTo: 'requester')
																				.where('active', isEqualTo: true)
																				.get();

																		await FirebaseFirestore.instance.runTransaction((tx) async {
																			tx.delete(locatorDeviceRef);

																			for (final requesterDoc in requesterDocs.docs) {
																				final requesterDeviceRef = groupRef
																						.collection('devices')
																						.doc(requesterDoc.id);

																				tx.update(requesterDeviceRef, {
																					'pairedLocators.$locatorId': FieldValue.delete(),
																				});
																			}

																			tx.set(
																				locatorRootRef,
																				{
																					'groupId': FieldValue.delete(),
																					'updatedAt': FieldValue.serverTimestamp(),
																				},
																				SetOptions(merge: true),
																			);

																			tx.update(groupRef, {
																				'activeLocatorCount': FieldValue.increment(-1),
																				'updatedAt': FieldValue.serverTimestamp(),
																			});
																		});
																		await FirebaseDatabase.instance
																				.ref(
																					'presence/groups/$groupId/locators/$locatorId',
																				)
																				.remove();

																		Log.d(
																			"BEACON PRESENCE => locator node removed => $locatorId",
																		);
																		Log.d(
																			"BEACON LOCATOR REMOVED FROM GROUP => $locatorId",
																		);
																	onChanged?.call();
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
  }
}