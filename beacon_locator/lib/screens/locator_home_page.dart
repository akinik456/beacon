import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/identity_service.dart';
import 'locator_permission_page.dart';
import '../services/locator_permission_service.dart';
import '../services/smart_presence_scheduler.dart';
import '../services/pairing_request_service.dart';
import '../services/pairing_approval_service.dart';
import '../services/call_me_service.dart';
import '../services/alert_service.dart';
import '../services/alert_monitor_service.dart';
import '../services/geofence_service.dart';
import '../services/motion_service.dart';
import '../services/active_watcher_service.dart';
import '../services/locator_settings_service.dart';
import '../l10n/app_localizations.dart';
import 'language_select_page.dart';


class LocatorHomePage extends StatefulWidget {
  const LocatorHomePage({super.key});

  @override
  State<LocatorHomePage> createState() => _LocatorHomePageState();
}

class _LocatorHomePageState extends State<LocatorHomePage>
    with WidgetsBindingObserver {
  bool hasAllPermissions = false;
  Timer? _presenceTimer;
	
	//MotionService.start();

  @override
  void initState() {
    super.initState();
		LocatorSettingsService.startListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndWarn();
    });

    SmartPresenceScheduler.start();
		MotionService.start();
		ActiveWatcherService.start();
		
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
		LocatorSettingsService.stopListeners();
		MotionService.stop();
		SmartPresenceScheduler.stop();
		ActiveWatcherService.stop();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  Future<void> _checkPermissionsAndWarn() async {
    final result = await LocatorPermissionService.hasAllRequiredPermissions();

    if (!mounted) return;

    setState(() {
      hasAllPermissions = result;
    });

    if (!result) {
      _showMissingPermissionsDialog();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsAndWarn();
    }
  }

  void _showMissingPermissionsDialog() {
		final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(l10n.permissionsRequired, style: AppFonts.title),
        content: Text(
          l10n.somePermissions,
          style: AppFonts.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.ok,
              style: AppFonts.button.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, String>> _loadLocatorCodeData() async {
    final locatorId = await IdentityService.getLocatorId() ?? '';
    final locatorCode = await IdentityService.getLocatorCode() ?? '------';
    final locatorName = await IdentityService.getLocatorName() ?? 'Member';

    return {
      'locatorId': locatorId,
      'locatorCode': locatorCode,
      'locatorName': locatorName,
    };
  }

Stream<List<Map<String, String>>> _watchPairedRequesterData() async* {
  final groupId = await IdentityService.getGroupId();
  final locatorId = await IdentityService.getLocatorId();

  if (groupId == null || locatorId == null) {
    yield [];
    return;
  }

  yield* FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(locatorId)
      .snapshots()
      .map((doc) {
    final data = doc.data();

    if (data == null) {
      return <Map<String, String>>[];
    }

    final pairedRequesters = Map<String, dynamic>.from(
      data['pairedRequesters'] ?? {},
    );

    if (pairedRequesters.isEmpty) {
      return <Map<String, String>>[];
    }

    final result = <Map<String, String>>[];

    for (final requesterId in pairedRequesters.keys) {
      final requesterData = Map<String, dynamic>.from(
        pairedRequesters[requesterId] ?? {},
      );

      result.add({
        'requesterId': requesterId,
        'requesterName':
            requesterData['requesterName'] ?? 'Requester',
        'requesterCode':
            requesterData['requesterCode'] ?? '------',
      });
    }

    result.sort((a, b) {
      final aName =
          (a['requesterName'] ?? '').toLowerCase();
      final bName =
          (b['requesterName'] ?? '').toLowerCase();

      return aName.compareTo(bName);
    });

    return result;
  });
}

  void _showLocatorQrDialog({
    required String locatorId,
    required String locatorCode,
  }) {
      builder: (dialogContext){
			final l10n =
					AppLocalizations.of(dialogContext)!;

			return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.memberQRCode, style: AppFonts.title),
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
              Text(l10n.memberCode, style: AppFonts.caption),
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
      );
			};
  }

  Widget _locatorCodeHeader(String locatorId, String locatorCode) {
	final l10n = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (locatorId.isEmpty) return;

        _showLocatorQrDialog(locatorId: locatorId, locatorCode: locatorCode);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
							    '${l10n.member}\n'
									'${l10n.code}',
								textAlign: TextAlign.center,
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

  Widget _permissionsButton() {
    final color = hasAllPermissions ? AppColors.primary : AppColors.danger;
		final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () async {
          final color = hasAllPermissions
              ? AppColors.primary
              : AppColors.danger;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LocatorPermissionPage()),
          );
          if (result != null) {
            setState(() {
              hasAllPermissions = result;
            });
          }
        },

        icon: Icon(Icons.privacy_tip_outlined, color: color),
        label: Text(
          l10n.permissions,
          style: AppFonts.button.copyWith(color: color),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.25)),
          backgroundColor: color.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

Widget _pairedRequesterCard() {
  return StreamBuilder<List<Map<String, String>>>(
    stream: _watchPairedRequesterData(),
    builder: (context, snapshot) {
      final requesters = snapshot.data ?? [];
			final l10n = AppLocalizations.of(context)!;
      if (requesters.isEmpty) {
        return AppCard(
          child: Text(
            l10n.noPairedRequester,
            style: AppFonts.subtitle,
          ),
        );
      }

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.pairedRequesters,
              style: AppFonts.caption,
            ),

            const SizedBox(height: 12),

            ...requesters.map((requester) {
              final requesterId =
                  requester['requesterId'] ?? '';
              final requesterName =
                  requester['requesterName'] ?? 'Requester';
              final requesterCode =
                  requester['requesterCode'] ?? '------';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$requesterName - $requesterCode',
                        style: AppFonts.subtitle,
                      ),
                    ),

                    OutlinedButton.icon(
                      onPressed: requesterId.isEmpty
                          ? null
                          : () async {
                              final groupId =
                                  await IdentityService.getGroupId();

                              if (groupId == null) return;

                              await CallMeService.createCallMe(
                                groupId: groupId,
                                targetRequesterId: requesterId,
                              );
                            },
                      icon: const Icon(
                        Icons.call_rounded,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        l10n.callme,
                        style: AppFonts.button.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 4),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final groupId =
                      await IdentityService.getGroupId();

                  if (groupId == null) return;

                  for (final requester in requesters) {
                    final requesterId =
                        requester['requesterId'] ?? '';

                    if (requesterId.isEmpty) continue;

                    await CallMeService.createCallMe(
                      groupId: groupId,
                      targetRequesterId: requesterId,
                    );
                  }

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.callMeSentAll,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.campaign_outlined,
                  color: AppColors.primary,
                ),
                label: Text(
                  l10n.askEverybody,
                  style: AppFonts.button.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildPairingArea() {
    return FutureBuilder<String?>(
      future: IdentityService.getLocatorId(),
      builder: (context, idSnapshot) {
        final locatorId = idSnapshot.data;
				final l10n = AppLocalizations.of(context)!;
        if (locatorId == null || locatorId.isEmpty) {
          return _pairedRequesterCard();
        }

        return StreamBuilder(
          stream: PairingRequestService.watchPendingPairingRequests(
            locatorId: locatorId,
          ),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return _pairedRequesterCard();
            }

            final doc = docs.first;
            final data = doc.data();

            final requesterName = data['requesterName'] ?? 'Requester';

            final requesterCode = data['requesterCode'] ?? '------';

            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.pairingRequest, style: AppFonts.caption),
                  const SizedBox(height: 6),
                  Text(
                    '$requesterName - $requesterCode',
                    style: AppFonts.subtitle,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
														await PairingApprovalService.rejectPairingRequest(
															requestId: doc.id,
															requestData: data,
														);

														if (!context.mounted) return;

														ScaffoldMessenger.of(context).showSnackBar(
															SnackBar(
																content: Text(l10n.pairingRejected),
															),
														);
													},
                          child: Text(
                            l10n.reject,
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
                                await PairingApprovalService.approvePairingRequest(
                                  requestId: doc.id,
                                  requestData: data,
                                );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(result)));
                          },
                          child: Text(
                            l10n.approve,
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
    );
  }
	
Widget _activeWatchersCard() {
  return ValueListenableBuilder<List<Map<String, dynamic>>>(
    valueListenable: ActiveWatcherService.activeWatchers,
    builder: (context, watchers, _) {
			final l10n = AppLocalizations.of(context)!;
      if (watchers.isEmpty) {
        return AppCard(
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.primary,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.memberReady,
                style: AppFonts.subtitle,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.noActiveWatchers,
                style: AppFonts.caption,
              ),
            ],
          ),
        );
      }

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.activeWatchers} (${watchers.length})',
              style: AppFonts.subtitle,
            ),

            const SizedBox(height: 16),

            Column(
							children: List.generate(
								watchers.length,
								(index) {
									final watcher = watchers[index];

									final requesterName =
											watcher['requesterName'] ?? 'Requester';

									final requesterCode =
											watcher['requesterCode'] ?? '------';

									return Column(
										children: [
											Row(
												children: [
													const Icon(
														Icons.visibility_rounded,
														color: AppColors.primary,
														size: 20,
													),

													const SizedBox(width: 12),

													Expanded(
														child: Column(
															crossAxisAlignment:
																	CrossAxisAlignment.start,
															children: [
																Text(
																	requesterName,
																	style: AppFonts.subtitle,
																),
																const SizedBox(height: 2),
																Text(
																	requesterCode,
																	style: AppFonts.caption,
																),
															],
														),
													),
												],
											),

											if (index != watchers.length - 1) ...[
												const SizedBox(height: 12),
												Divider(
													color: Colors.white.withValues(
														alpha: 0.08,
													),
													height: 1,
												),
												const SizedBox(height: 12),
											],
										],
									);
								},
							),
						),						
          ],
        ),
      );			
    },
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
            final locatorId = snapshot.data?['locatorId'] ?? '';
            final locatorCode = snapshot.data?['locatorCode'] ?? '------';
            final locatorName = snapshot.data?['locatorName'] ?? 'Member';
						final l10n = AppLocalizations.of(context)!;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LynraFamily\nMember',
                              style: AppFonts.title.copyWith(fontSize: 28,color: AppColors.primary,),
                            ),
                            const SizedBox(height: 6),
                            Text(locatorName, 
														style: AppFonts.caption),
                          ],
                        ),
                      ),
											Align(
												alignment: Alignment.centerRight,
												child: TextButton.icon(
													onPressed: () async {
														await Navigator.push(
															context,
															MaterialPageRoute(
																builder: (_) =>
																		const LanguageSelectPage(),
															),
														);
														if (!mounted) return;
														setState(() {});
													},
													icon: const Icon(
														Icons.language_rounded,
														size: 18,
														color: AppColors.primary,
													),
													label: Text(
														Localizations.localeOf(context).languageCode == 'tr'
															? 'Türkçe'
															: 'English',
															style: AppFonts.caption.copyWith(
																color: AppColors.primary,
															),
													),
												),
											),
                      const SizedBox(width: 16),
                      _locatorCodeHeader(locatorId, locatorCode),									
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildPairingArea(),
									const SizedBox(height: 12),
									_activeWatchersCard(),						
                  const Spacer(),
									const SizedBox(height: 12),
                  _permissionsButton(),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
