import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/identity_service.dart';
import '../services/pairing_request_service.dart';
import '../services/pairing_approval_service.dart';
import '../services/pairing_reject_service.dart';


class LocatorHomePage extends StatelessWidget {
  const LocatorHomePage({super.key});

  Future<Map<String, String>> _loadLocatorCodeData() async {
    final locatorId =
        await IdentityService.getLocatorId() ?? '';

    final locatorCode =
        await IdentityService.getLocatorCode() ??
            '------';

    final locatorName =
        await IdentityService.getLocatorName() ??
            'Locator';

    return {
      'locatorId': locatorId,
      'locatorCode': locatorCode,
      'locatorName': locatorName,
    };
  }

  void _showLocatorQrDialog({
    required BuildContext context,
    required String locatorId,
    required String locatorCode,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Locator QR Code',
                style: AppFonts.title,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: QrImageView(
                  data: locatorId,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Locator code',
                style: AppFonts.caption,
              ),
              const SizedBox(height: 6),
              Text(
                locatorCode,
                style: AppFonts.title.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locatorCodeHeader(
    BuildContext context,
    String locatorId,
    String locatorCode,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (locatorId.isEmpty) return;

        _showLocatorQrDialog(
          context: context,
          locatorId: locatorId,
          locatorCode: locatorCode,
        );
      },
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Locator Code',
                style: AppFonts.caption,
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            locatorCode,
            style: AppFonts.subtitle.copyWith(
              color: AppColors.primary,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
	
Widget _waitingPairingCard() {
  return AppCard(
    child: Row(
      children: [
        const Icon(
          Icons.location_searching_rounded,
          color: AppColors.primary,
          size: 28,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Waiting for pairing request',
            style: AppFonts.subtitle,
          ),
        ),
      ],
    ),
  );
}	

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<Map<String, String>>(
          future: _loadLocatorCodeData(),
          builder: (context, snapshot) {
            final locatorId =
                snapshot.data?['locatorId'] ?? '';

            final locatorCode =
                snapshot.data?['locatorCode'] ??
                    '------';

            final locatorName =
                snapshot.data?['locatorName'] ??
                    'Ready to pair';

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'Locator',
                              style:
                                  AppFonts.title
                                      .copyWith(
                                fontSize: 28,
                              ),
                            ),
                            const SizedBox(
                                height: 6),
                            Text(
                              locatorName,
                              style:
                                  AppFonts.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _locatorCodeHeader(
                        context,
                        locatorId,
                        locatorCode,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  FutureBuilder(
										future: PairingRequestService.watchPendingPairingRequests(),
										builder: (context, futureSnapshot) {
											if (!futureSnapshot.hasData) {
												return _waitingPairingCard();
											}

											return StreamBuilder(
												stream: futureSnapshot.data,
												builder: (context, streamSnapshot) {
													final docs = streamSnapshot.data?.docs ?? [];

													if (docs.isEmpty) {
														return _waitingPairingCard();
													}

													final data = docs.first.data();

													final requesterName =
															data['requesterName'] ?? 'Unknown requester';

													final requesterCode =
															data['requesterCode'] ?? '------';

													return AppCard(
														child: Column(
															crossAxisAlignment: CrossAxisAlignment.start,
															children: [
																Row(
																	children: [
																		Container(
																			width: 46,
																			height: 46,
																			decoration: BoxDecoration(
																				color: AppColors.primary.withValues(alpha: 0.12),
																				borderRadius: BorderRadius.circular(15),
																			),
																			child: const Icon(
																				Icons.person_add_alt_1_rounded,
																				color: AppColors.primary,
																				size: 26,
																			),
																		),
																		const SizedBox(width: 14),
																		Expanded(
																			child: Column(
																				crossAxisAlignment: CrossAxisAlignment.start,
																				children: [
																					Text('Pairing request', style: AppFonts.caption),
																					const SizedBox(height: 4),
																					Text(requesterName, style: AppFonts.subtitle),
																					const SizedBox(height: 2),
																					Text(
																						'Requester code: $requesterCode',
																						style: AppFonts.caption,
																					),
																				],
																			),
																		),
																	],
																),
																const SizedBox(height: 18),
																Row(
																	children: [
																		Expanded(
																			child: OutlinedButton(
																				onPressed: () async {
																					await PairingRejectService
																							.rejectPairingRequest(
																						requestId: docs.first.id,
																					);

																					if (!context.mounted) return;

																					ScaffoldMessenger.of(context)
																							.showSnackBar(
																						const SnackBar(
																							content: Text(
																								'Pairing request rejected',
																							),
																						),
																					);
																				},
																				child: Text(
																					'Reject',
																					style: AppFonts.button.copyWith(
																						color: AppColors.danger,
																					),
																				),
																			),
																		),
																		const SizedBox(width: 12),

																		Expanded(
																			child: ElevatedButton(
																				onPressed: () async {
																					final result =
																							await PairingApprovalService
																									.approvePairingRequest(
																						requestId: docs.first.id,
																						requestData: data,
																					);

																					if (!context.mounted) return;

																					String message;

																					switch (result) {

																						case 'approved':
																							message = 'Locator paired successfully';
																							break;

																						case 'rejected_capacity':
																							message =
																									'Group locator limit reached';
																							break;

																						case 'rejected_group_not_found':
																							message = 'Group not found';
																							break;

																						case 'error_locator_not_found':
																							message = 'Locator not found';
																							break;

																						default:
																							message =
																									'Failed to approve request';
																					}

																					ScaffoldMessenger.of(context)
																							.showSnackBar(
																						SnackBar(
																							content: Text(message),
																						),
																					);
																				},
																				child: Text(
																					'Approve',
																					style: AppFonts.button.copyWith(
																						color: AppColors.background,
																					),
																				),
																			),
																		),
																	],
																),
															],
														),
													);
												},
											);
										},
									),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: AppCard(
                          child: Column(
                            children: [
                              const Icon(
                                Icons
                                    .gps_fixed_rounded,
                                color:
                                    AppColors
                                        .success,
                                size: 28,
                              ),
                              const SizedBox(
                                  height: 10),
                              Text(
                                'GPS ON',
                                style: AppFonts
                                    .subtitle,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppCard(
                          child: Column(
                            children: [
                              const Icon(
                                Icons
                                    .battery_5_bar_rounded,
                                color:
                                    AppColors
                                        .primary,
                                size: 28,
                              ),
                              const SizedBox(
                                  height: 10),
                              Text(
                                '87%',
                                style: AppFonts
                                    .subtitle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton(
                      onPressed: () {},
                      style:
                          OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.danger
                              .withValues(
                            alpha: 0.35,
                          ),
                        ),
                        backgroundColor:
                            AppColors.danger
                                .withValues(
                          alpha: 0.08,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(18),
                        ),
                      ),
                      child: Text(
                        'Stop Sharing',
                        style:
                            AppFonts.button
                                .copyWith(
                          color:
                              AppColors.danger,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}