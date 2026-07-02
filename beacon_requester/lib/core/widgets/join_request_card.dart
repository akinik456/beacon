import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'app_card.dart';
import '../../services/join_request_service.dart';
import '../../l10n/app_localizations.dart';
import 'app_banner.dart';
import '../../services/firebase_authentication_service.dart';


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
												child: OutlinedButton(
													onPressed: () async {
															await doc.reference.update({
																'status': 'rejected',
																'rejectedAt': FieldValue.serverTimestamp(),
															});

															await Future.delayed(
																const Duration(seconds: 2),
															);

															await doc.reference.delete();

															print(
																"BEACON JOIN REJECTED => ${doc.id}",
															);
														},
													child: Text(
														l10n.reject,
													),
												),
											),
										const SizedBox(width: 12),	
										Expanded(
											child: ElevatedButton(
												onPressed: () async {
													final joinData = doc.data();

													final requesterId = doc.id;

													print(
														"BEACON JOIN APPROVE TAP => "
														"groupId=$groupId requesterId=$requesterId",
													);

													if (requesterId == null || requesterId.isEmpty) {
														print("BEACON JOIN APPROVE => missing requesterId");
														return;
													}

													final firestore = FirebaseFirestore.instance;

													final groupRef = firestore
															.collection('groups')
															.doc(groupId);

													final requesterRef = groupRef
															.collection('devices')
															.doc(requesterId);

													final requesterRefroot = firestore
															.collection('requesters')
															.doc(requesterId);

													final joinRequestRef = doc.reference;

													try {
														await firestore.runTransaction((tx) async {
															final freshJoinRequest = await tx.get(joinRequestRef);

															if (!freshJoinRequest.exists) {
																throw Exception('join_request_not_found');
															}

															final freshGroup = await tx.get(groupRef);
															final groupData = freshGroup.data() ?? {};

															final maxRequesters = groupData['maxRequesters'] ?? 1;
															final activeRequesterCount =
																	groupData['activeRequesterCount'] ?? 0;

															if (activeRequesterCount >= maxRequesters) {
																throw Exception('requester_capacity_reached');
															}

															tx.set(requesterRef, {
																'requesterCode': joinData['requesterCode'],
																'requesterName': joinData['requesterName'],
																'name': joinData['requesterName'],
																'role': 'requester',
																'isMaster': false,
																'active': true,
																'authUid': AuthService.uid,
																'pairedLocators': {},
																'joinedAt': FieldValue.serverTimestamp(),
																'createdAt': FieldValue.serverTimestamp(),
															});

															tx.update(groupRef, {
																'activeRequesterCount': FieldValue.increment(1),
																'updatedAt': FieldValue.serverTimestamp(),
															});

															tx.set(requesterRefroot, {
																'groupId': groupId,
																'updatedAt': FieldValue.serverTimestamp(),
															}, SetOptions(merge: true));

															tx.delete(joinRequestRef);
														});

														print("BEACON JOIN APPROVED => $requesterId");
													} catch (e) {
														if (!context.mounted) return;
														AppBanner.error(
															context,
															e.toString().contains('requester_capacity_reached')
																	? l10n.maxFamilyMembersReached
																	: l10n.joinRequestCouldNotBeApproved,
														);
													}
												},
												child: Text(
												l10n.approve,
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
