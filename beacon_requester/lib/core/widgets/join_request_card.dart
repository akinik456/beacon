import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';
import '../../services/join_request_service.dart';
import '../../l10n/app_localizations.dart';


class JoinRequestCard extends StatelessWidget {
  final String groupId;

  const JoinRequestCard({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;
    return StreamBuilder(
      stream: JoinRequestService.watchPendingJoinRequests(
        groupId: groupId,
      ),
      builder: (context, snapshot) {

      if (!snapshot.hasData ||
          snapshot.data!.docs.isEmpty) {
        return const SizedBox.shrink();
      }

      final doc = snapshot.data!.docs.first;
      final data = doc.data();

      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: AppCard(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                l10n.joinRequest,
                style: AppFonts.subtitle,
              ),

              const SizedBox(height: 8),

              Text(
                data['requesterName'] ?? '-',
                style: AppFonts.body,
              ),

              Text(
                data['requesterCode'] ?? '-',
                style: AppFonts.caption,
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
												final joinData = doc.data();

												final requesterId = joinData['requesterId'];

												if (requesterId == null || groupId == null) {
													return;
												}

												final firestore = FirebaseFirestore.instance;

												final groupRef = firestore
														.collection('groups')
														.doc(groupId);

												final requesterRef = groupRef
														.collection('devices')
														.doc(requesterId);

												final joinRequestRef = doc.reference;

												try {
													await firestore.runTransaction((tx) async {
														final freshGroup = await tx.get(groupRef);

														final groupData = freshGroup.data() ?? {};

														final maxRequesters =
																groupData['maxRequesters'] ?? 1;

														final activeRequesterCount =
																groupData['activeRequesterCount'] ?? 0;

														if (activeRequesterCount >= maxRequesters) {
															throw Exception('requester_capacity_reached');
														}

														tx.set(requesterRef, {
															'requesterId': joinData['requesterId'],
															'requesterCode': joinData['requesterCode'],
															'role': 'requester',
															'requesterName': joinData['requesterName'],
															'isMaster': false,
															'active': true,
															'pairedLocators': {},
															'joinedAt': FieldValue.serverTimestamp(),
															'createdAt': FieldValue.serverTimestamp(),
														});

														tx.update(groupRef, {
															'activeRequesterCount':
																	FieldValue.increment(1),
															'updatedAt':
																	FieldValue.serverTimestamp(),
														});

														tx.delete(joinRequestRef);
													});

													print(
														"BEACON JOIN APPROVED => $requesterId",
													);
												} catch (e) {
  await doc.reference.update({
    'status': 'rejected',
    'rejectedAt': FieldValue.serverTimestamp(),
  });

  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
				l10n.maxFamilyMembersReached,
      ),
    ),
  );
}
											},
                      child: Text(
											l10n.approve,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
												await doc.reference.update({
													'status': 'rejected',
													'rejectedAt': FieldValue.serverTimestamp(),
												});

												print(
													"BEACON JOIN REJECTED => ${doc.id}",
												);
											},
                      child: Text(
                        l10n.reject,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
	
	 }
  }
