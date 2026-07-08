// https://www.youtube.com/shorts/uz_d2RcNNc0
//FGS(location) başlatan her yeni kod yolu
//önce locationAlways kontrol edecek.

import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import '../core/widgets/call_me_overlay.dart';
import '../services/alert_service.dart';
import '../services/alert_monitor_service.dart';
import '../services/geofence_service.dart';
import '../services/motion_service.dart';
import '../services/active_watcher_service.dart';
import '../services/locator_settings_service.dart';
import '../l10n/app_localizations.dart';
import 'language_select_page.dart';
import '../services/native_presence_service.dart';
import '../services/locator_fcm_service.dart';
import '../services/motion_service.dart';
import '../services/subscription_service.dart';
import '../core/widgets/locator_subscription_expired_overlay.dart';
import '../services/notification_service.dart';
import '../core/widgets/group_info_panel.dart';
import '../services/locator_name_editor.dart';
import '../core/widgets/guide_panel.dart';
import '../core/widgets/app_banner.dart';
import '../services/theme_service.dart';
import '../services/rtdb_auth_mapping_service.dart';
import '../utils/log.dart';


class LocatorHomePage extends StatefulWidget {
  const LocatorHomePage({super.key});

  @override
  State<LocatorHomePage> createState() => _LocatorHomePageState();
}

class _LocatorHomePageState extends State<LocatorHomePage>
    with WidgetsBindingObserver {
  bool hasAllPermissions = false;
  Timer? _presenceTimer;
	String _appVersion = '';
	Map<String, dynamic>? _callMeData;
	List<Map<String, dynamic>> _pendingCallMeQueue = [];
	final List<StreamSubscription> _subscriptions = [];
	bool _hasGroup = false;
	bool _hasFullAccess = true;
	bool _showGroupInfo = false;
	bool _showGuide = false;
	bool _isDarkTheme = true;
	bool _clearingGroupAfterUnpair = false;
	bool _hadPairedRequester = false;
	
 @override
void initState() {
  super.initState();
	_loadTheme();
	//MotionService.start();
  unawaited(_startLocatorHome());

  unawaited(_loadVersion());
  unawaited(_checkForUpdate());
	

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkPermissionsAndWarn();
  });
}
Future<void> _startLocatorHome() async {
  final locatorId = await IdentityService.getLocatorId();

  if (locatorId != null && locatorId.isNotEmpty) {
    try {
      final locatorDoc = await FirebaseFirestore.instance
          .collection('locators')
          .doc(locatorId)
          .get();

      final serverGroupId = locatorDoc.data()?['groupId'];

      await _syncLocalGroupWithServer();
    } catch (e) {
      Log.e(
        "BEACON LOCATOR HOME => "
        "group sync error => $e",
      );
    }
  }

  final groupId = await IdentityService.getGroupId();

  final hasGroup =
      groupId != null && groupId.isNotEmpty;

  final hasFullAccess = hasGroup
      ? await SubscriptionService.hasFullAccess()
      : true;

  if (!mounted) return;

  setState(() {
    _hasGroup = hasGroup;
    _hasFullAccess = hasFullAccess;
  });

  if (!hasFullAccess) {
    Log.d(
      "BEACON SUBSCRIPTION => inactive, skip locator services",
    );
    return;
  }

  if (hasGroup) {
    await RtdbAuthMappingService.syncLocatorAuth();
  }

  await FCMService.initialize();

  _startNativePresenceIfAllowed();
	
	await cleanupInvalidPairedRequesters();

  LocatorSettingsService.startListeners();
	
	final prefs = await SharedPreferences.getInstance();
	ActiveWatcherService.setLangCode(
		prefs.getString('languageCode') ?? 'en',
	);

  ActiveWatcherService.startUiOnly();

  _listenCallMe();
}
  @override
  void dispose() {
    _presenceTimer?.cancel();
		LocatorSettingsService.stopListeners();
		ActiveWatcherService.stop();
		WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
	
	Future<void> _loadTheme() async {
		final isDark = await ThemeService.isDarkTheme();

		AppColors.isDark = isDark;

		if (!mounted) return;

		setState(() {
			_isDarkTheme = isDark;
		});
	_applySystemBars();
	}
	
	void _applySystemBars() {
		SystemChrome.setSystemUIOverlayStyle(
			SystemUiOverlayStyle(
				statusBarColor: AppColors.background,
				statusBarIconBrightness:
						AppColors.isDark ? Brightness.light : Brightness.dark,
				systemNavigationBarColor: AppColors.background,
				systemNavigationBarIconBrightness:
						AppColors.isDark ? Brightness.light : Brightness.dark,
			),
		);
	}
	
Future<void> _startNativePresenceIfAllowed() async {
  final locationAlways =
      await Permission.locationAlways.status;

  if (!locationAlways.isGranted) {
    Log.d(
      "BEACON NATIVE SERVICE => locationAlways missing, skip start",
    );
    return;
  }

  final groupId = await IdentityService.getGroupId();
  final locatorId = await IdentityService.getLocatorId();

  if (groupId == null || locatorId == null) {
    Log.d(
      "BEACON NATIVE SERVICE => missing ids, skip start "
      "group=$groupId locator=$locatorId",
    );
    return;
  }

  await NativePresenceService.start(
    groupId: groupId,
    locatorId: locatorId,
  );
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
	
	static Future<void> cleanupInvalidPairedRequesters() async {
  final groupId = await IdentityService.getGroupId();
  final locatorId = await IdentityService.getLocatorId();

  if (groupId == null || locatorId == null) {
    Log.d("BEACON CLEANUP => missing group/locator");
    return;
  }

  final locatorDeviceRef = FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(locatorId);

  final locatorDeviceSnap = await locatorDeviceRef.get();
  final locatorDeviceData = locatorDeviceSnap.data();

  if (locatorDeviceData == null) {
    Log.d("BEACON CLEANUP => locator device doc not found");
    return;
  }

  final pairedRequesters = Map<String, dynamic>.from(
    locatorDeviceData['pairedRequesters'] ?? {},
  );

  if (pairedRequesters.isEmpty) {
    Log.d("BEACON CLEANUP => no paired requesters");
    return;
  }

  final batch = FirebaseFirestore.instance.batch();
  int removedCount = 0;

  for (final requesterId in pairedRequesters.keys) {
    final requesterDeviceRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(requesterId);

    final requesterDeviceSnap = await requesterDeviceRef.get();
    final requesterData = requesterDeviceSnap.data();

    final isValidRequester =
        requesterDeviceSnap.exists &&
        requesterData?['active'] == true &&
        requesterData?['role'] == 'requester';

    if (!isValidRequester) {
      batch.update(locatorDeviceRef, {
        'pairedRequesters.$requesterId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      removedCount++;
    }
  }

  if (removedCount == 0) {
    Log.d("BEACON CLEANUP => paired requesters valid");
    return;
  }

  await batch.commit();

  Log.d(
    "BEACON CLEANUP => removed invalid paired requesters count=$removedCount",
  );
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
          style: AppFonts.body.copyWith(color: AppColors.textSecondary,fontSize: 18,),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.ok,
              style: AppFonts.button.copyWith(color: AppColors.primary,fontSize: 18,),
            ),
          ),
        ],
      ),
    );
  }
	
	Future<void> _loadVersion() async {
		final info = await PackageInfo.fromPlatform();

		if (!mounted) return;
		setState(() {
			_appVersion = "${info.version}+${info.buildNumber}";
		});
	}	
	
	Future<void> _checkForUpdate() async {
		try {
			final info = await InAppUpdate.checkForUpdate();

			if (!mounted) return;

			if (info.updateAvailability == UpdateAvailability.updateAvailable &&
					info.flexibleUpdateAllowed) {
				_showUpdateDialog();
			}
		} catch (_) {
			// Debug APK, sideload veya Play Store dışı kurulumda hata verebilir.
			// Sessiz geçiyoruz.
		}
	}
	
	void _showUpdateDialog() {
	final l10n = AppLocalizations.of(context)!;
		showDialog(
			context: context,
			barrierDismissible: true,
			builder: (context) {
				return AlertDialog(
					title: Text(l10n.updateAvailable),
					content: Text(
						l10n.aNewVer,
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.pop(context),
							child: Text(l10n.later),
						),
						TextButton(
							onPressed: () async {
								Navigator.pop(context);
								try {
									await InAppUpdate.startFlexibleUpdate();
									await InAppUpdate.completeFlexibleUpdate();
								} catch (_) {}
							},
							child: Text(l10n.update),
						),
					],
				);
			},
		);
	}
	
	void _listenCallMe() async {
		final groupId = await IdentityService.getGroupId();

		final locatorId = await IdentityService.getLocatorId();

		if (groupId == null || locatorId == null) {
			return;
		}

		final sub = FirebaseFirestore.instance
				.collection('groups')
				.doc(groupId)
				.collection('call_me')
				.doc(locatorId)
				.collection('items')
				.snapshots()
				.listen((snapshot) {
			for (final change in snapshot.docChanges) {
				if (change.type != DocumentChangeType.added) {
					continue;
				}

				final data = change.doc.data();

				if (data == null) continue;

				if (data['status'] != 'pending') {
					continue;
				}

				final item = {
					...data,
					'callMeId': change.doc.id,
				};

				if (!mounted) return;

				setState(() {
					final alreadyExists = _pendingCallMeQueue.any(
						(x) => x['callMeId'] == item['callMeId'],
					);

					if (!alreadyExists) {
						_pendingCallMeQueue.add(item);
					}

					_callMeData ??= item;
				});
			}
		});

		_subscriptions.add(sub);
	}

Future<void> _clearLocatorGroupIfNoRequester() async {
  if (_clearingGroupAfterUnpair) return;

  _clearingGroupAfterUnpair = true;

  try {
    final locatorId = await IdentityService.getLocatorId();

    if (locatorId == null || locatorId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('locators')
        .doc(locatorId)
        .set({
          'groupId': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    Log.d("LOCATOR SYNC => groupId cleared because no paired requester");
  } catch (e) {
    Log.e("LOCATOR SYNC => clear groupId failed => $e");
  } finally {
    _clearingGroupAfterUnpair = false;
  }
}

Future<void> _syncLocalGroupWithServer() async {
  final locatorId = await IdentityService.getLocatorId();

  if (locatorId == null || locatorId.isEmpty) return;

  final locatorDoc = await FirebaseFirestore.instance
      .collection('locators')
      .doc(locatorId)
      .get();

  final serverGroupId = locatorDoc.data()?['groupId'];

  if (serverGroupId == null ||
      serverGroupId.toString().trim().isEmpty) {
    await IdentityService.clearGroupId(
      reason: 'locator_home_server_group_missing',
    );

    if (!mounted) return;

    setState(() {
      _hasGroup = false;
    });

    Log.d(
      "BEACON LOCATOR HOME => "
      "server groupId missing, local groupId cleared",
    );
  }
}
Future<Map<String, String>> _loadLocatorCodeData() async {
  final locatorId = await IdentityService.getLocatorId() ?? '';
  final locatorCode = await IdentityService.getLocatorCode() ?? '------';
  final locatorName = await IdentityService.getLocatorName() ?? 'Member';

  final groupId = await IdentityService.getGroupId() ?? '';

  String groupName = '';

  if (groupId.isNotEmpty) {
    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .get();

    groupName = doc.data()?['groupName'] ?? '';
  }

  return {
    'locatorId': locatorId,
    'locatorCode': locatorCode,
    'locatorName': locatorName,
    'groupId': groupId,
    'groupName': groupName,
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
      .asyncMap((doc) async {
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
      final requesterDoc = await FirebaseFirestore.instance
          .collection('requesters')
          .doc(requesterId)
          .get();

      final requesterData = requesterDoc.data() ?? {};

      result.add({
        'requesterId': requesterId,
        'requesterName': requesterData['requesterName'] ?? 'Requester',
        'requesterCode': requesterData['requesterCode'] ?? '------',
      });
    }

    result.sort((a, b) {
      final aName = (a['requesterName'] ?? '').toLowerCase();
      final bName = (b['requesterName'] ?? '').toLowerCase();

      return aName.compareTo(bName);
    });

    return result;
  });
}

  void _showLocatorQrDialog({
    required String locatorId,
    required String locatorCode,
  }) {
	showDialog(
    context: context,
      builder: (dialogContext){
			final l10n =
					AppLocalizations.of(dialogContext)!;

			return Dialog(
        backgroundColor: AppColors.background,
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
			},
			);
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
              Stack(
								alignment: Alignment.bottomRight,
								children: [
									Icon(
										Icons.qr_code_scanner_rounded,
										color: AppColors.accent,
										size: 24,
									),
									
								],
							),	
							Icon(
										Icons.zoom_in,
										size: 32,
										color: AppColors.accent,
									),
              const SizedBox(width: 4),
              Text(
							    '${l10n.memberCode}',
								textAlign: TextAlign.center,
								style: AppFonts.button.copyWith(color: AppColors.accent),
							),	
							const SizedBox(width: 2),
							Text(
								locatorCode,
								textAlign: TextAlign.left,
								style: AppFonts.subtitle.copyWith(
									color: AppColors.accent,
									letterSpacing: 2,
								),
							),						
            ],
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
					final result = await Navigator.push(
						context,
						MaterialPageRoute(
							builder: (_) => const LocatorPermissionPage(),
						),
					);

					if (!mounted) return;

					if (result != null) {
						setState(() {
							hasAllPermissions = result;
						});
					}

					if (hasAllPermissions) {
						await _startLocatorHome();
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
			if (requesters.isNotEmpty) {
				_hadPairedRequester = true;
			}
      /*if (requesters.isEmpty && _hadPairedRequester) {
					WidgetsBinding.instance.addPostFrameCallback((_) {
				unawaited(_clearLocatorGroupIfNoRequester());
			});
        return AppCard(
          child: Text(
            l10n.noPairedRequester,
            style: AppFonts.subtitle,
          ),
        );
      }*/
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
              style: AppFonts.title.copyWith(fontSize: 18,color: AppColors.primary,),
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
                      child: RichText(
												overflow: TextOverflow.ellipsis,
												text: TextSpan(
													children: [
														TextSpan(
															text: '$requesterName',
															style: AppFonts.subtitle.copyWith(
																color: AppColors.textPrimary,
																fontWeight: FontWeight.w700
															),
														),

														TextSpan(
															text: ' - $requesterCode',
															style: AppFonts.subtitle.copyWith(
																color: AppColors.textSecondary,
																fontSize: 12,
															),
														),
													],
												),
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

													if (!context.mounted) return;													
													AppBanner.success(
														context,
														l10n.callMeSent,
													);
												},
                      icon: Icon(
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
						if (requesters.length > 1) ...[
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
									AppBanner.success(
										context,
										l10n.callMeSentAll,
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
														AppBanner.error(
															context,
															l10n.pairingRejected,
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
													style: ElevatedButton.styleFrom(
														backgroundColor: AppColors.primary,
													),
                          onPressed: () async {
                            final result =
                                await PairingApprovalService.approvePairingRequest(
                                  requestId: doc.id,
                                  requestData: data,
                                );
														if (!context.mounted) return;

														if (result == 'approved') {
															await Future.delayed(
																const Duration(milliseconds: 300),
															);

															await _startLocatorHome();
															await SmartPresenceScheduler.boostAndUpdateNow(
																reason: 'pairing_approved',
															);
														}
														AppBanner.info(
															context,
															result,
														);
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
              Icon(
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
													Icon(
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
																	style: AppFonts.caption.copyWith(
																		color: AppColors.textSecondary,
																		fontSize: 12,
																	),
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
final l10n = AppLocalizations.of(context)!;
  return Scaffold(
    backgroundColor: AppColors.background,
    body: Stack(
      children: [
        SafeArea(
        child: FutureBuilder<Map<String, String>>(
          future: _loadLocatorCodeData(),
          builder: (context, snapshot) {
 					final l10n = AppLocalizations.of(context)!;
           final locatorId = snapshot.data?['locatorId'] ?? '';
            final locatorCode = snapshot.data?['locatorCode'] ?? '------';
            final locatorName = snapshot.data?['locatorName'] ?? l10n.member;
						final groupId = snapshot.data?['groupId'] ?? '';
						final groupName = snapshot.data?['groupName'] ?? '';
						final langCode =
						Localizations.localeOf(context).languageCode.toUpperCase();
            
						return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,								
                children: [								
                  Expanded(
									child: SingleChildScrollView(
										padding: const EdgeInsets.only(bottom: 16),
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												Row(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Expanded(
															child: Column(
																crossAxisAlignment: CrossAxisAlignment.center,
																children: [
																	SizedBox(
																		width: double.infinity,
																		child: Stack(
																			alignment: Alignment.centerLeft,																
																				children: [
																					Text(
																						l10n.titleMember,
																						style: AppFonts.title.copyWith(
																							fontSize: 24,
																							color: AppColors.primary,
																						),
																					),
																					Positioned(
																						right: 30,
																						child: IconButton(
																							onPressed: () async {
																								final next = !_isDarkTheme;

																								await ThemeService.setDarkTheme(next);

																								AppColors.isDark = next;
																								_applySystemBars();
																								if (!mounted) return;

																								setState(() {
																									_isDarkTheme = next;
																								});
																							},
																							icon: Icon(
																								_isDarkTheme
																										? Icons.light_mode_rounded
																										: Icons.dark_mode_rounded,
																								color: AppColors.primary,
																								size: 22,
																							),
																						),
																					),
																					Positioned(
																						right: 0,
																						child: IconButton(
																							onPressed: () {
																								setState(() {
																									_showGuide = !_showGuide;
																								});
																							},
																							icon: Icon(
																								_showGuide
																										? Icons.keyboard_arrow_up_rounded
																										: Icons.help_outline_rounded,
																								color: AppColors.primary,
																								size: 22,
																							),
																						),
																					),																	
																				],
																			),
																		),													
																	],
																),
															),
														],
													),
													AnimatedCrossFade(
														duration: const Duration(milliseconds: 250),
														crossFadeState: _showGuide
																? CrossFadeState.showFirst
																: CrossFadeState.showSecond,
														firstChild: const GuidePanel(),
														secondChild: const SizedBox.shrink(),
													),
													const SizedBox(height: 6),

													InkWell(
														onTap: () {
															setState(() {
																_showGroupInfo = !_showGroupInfo;
															});
														},
														borderRadius: BorderRadius.circular(8),
														child: Padding(
															padding: const EdgeInsets.symmetric(vertical: 4),
															child: Row(
																mainAxisSize: MainAxisSize.min,
																children: [
																	Icon(
																		_showGroupInfo
																				? Icons.keyboard_arrow_up_rounded
																				: Icons.chevron_right_rounded,
																		color: AppColors.primary,
																		size: 22,
																	),
																	const SizedBox(width: 4),
																	Flexible(
																		child: Text(
																			l10n.groupInfo,
																			overflow: TextOverflow.ellipsis,
																			style: AppFonts.subtitle.copyWith(
																				color: AppColors.primary,
																			),
																		),
																	),
																],
															),
														),
													),

													AnimatedCrossFade(
														duration: const Duration(milliseconds: 250),
														crossFadeState: _showGroupInfo
																? CrossFadeState.showFirst
																: CrossFadeState.showSecond,
														firstChild: GroupInfoPanel(
															groupName: groupName,
															locatorName: locatorName,
															locatorCode: locatorCode,
															langCode: langCode,
															onLocatorNameChanged: () {
																setState(() {});
															},
															onShowLocatorQr: () {
																_showLocatorQrDialog(
																	locatorId: locatorId,
																	locatorCode: locatorCode,
																);
															},
															onLanguageChanged: () {
																setState(() {});
															},
														),
														secondChild: const SizedBox.shrink(),
													),
									
													const SizedBox(height: 12),
													_buildPairingArea(),
													const SizedBox(height: 12),
													_activeWatchersCard(),
												],
											),
										),
									),	
									const SizedBox(height: 12),
									_permissionsButton(),
									const SizedBox(height: 70),
									],	
                ),
              );
							
            },						
          ),
        ),
				Positioned(
					left: 2,
					right: 2,
					bottom: 2,
					child: Material(
						color: AppColors.background,
						child: Padding(
							padding: const EdgeInsets.symmetric(horizontal: 12),
							child: Row(
								children: [
									Expanded(
										child: Align(
											alignment: Alignment.centerLeft,
											child: InkWell(
												onTap: () {
													openFeedbackMenu();
												},
												borderRadius: BorderRadius.circular(20),
												child: Padding(
													padding: const EdgeInsets.symmetric(
														horizontal: 4,
														vertical: 2,
													),
													child: Row(
														mainAxisSize: MainAxisSize.min,
														children: [
															Icon(
																Icons.chat_bubble_outline_rounded,
																size: 18,
																color: AppColors.primary,
															),
															const SizedBox(width: 4),
															Text(
																l10n.feedback,
																style: TextStyle(
																	color: AppColors.primary,
																	fontSize: 14,
																	fontWeight: FontWeight.w500,
																),
															),
														],
													),
												),
											),
										),
									),

									Text(
										"${l10n.version} $_appVersion",
										style: TextStyle(
											color: AppColors.textPrimary,
											fontSize: 15,
											fontWeight: FontWeight.w500,
										),
									),
									Expanded(
										child: Align(
											alignment: Alignment.centerRight,
											child: FittedBox(
												fit: BoxFit.scaleDown,
												child: InkWell(
													onTap: () async {
														final Uri url = Uri.parse(
															'https://play.google.com/store/apps/developer?id=Lynra',
														);

														await launchUrl(
															url,
															mode: LaunchMode.externalApplication,
														);
													},
													borderRadius: BorderRadius.circular(20),
													child: Padding(
														padding: const EdgeInsets.symmetric(
															horizontal: 2,
															vertical: 2,
														),
														child: Row(
															mainAxisSize: MainAxisSize.min,
															children: [
																Icon(
																	Icons.apps_rounded,
																	size: 17,
																	color: AppColors.primary,
																),
																const SizedBox(width: 3),
																Text(
																	l10n.otherApps,
																	maxLines: 1,
																	overflow: TextOverflow.ellipsis,
																	style: TextStyle(
																		color: AppColors.primary,
																		fontSize: 13,
																		fontWeight: FontWeight.w500,
																	),
																),
															],
														),
													),
												),
											),
										),
									),
								],
							),
						),
					),
				),
				if (_callMeData != null)
					Positioned.fill(
						child: CallMeOverlay(
							data: _callMeData!,
							onDismiss: () async {
								final callMeId = _callMeData!['callMeId'];

								final groupId = _callMeData!['groupId'];

								final locatorId = _callMeData!['targetLocatorId'];

								await FirebaseFirestore.instance
										.collection('groups')
										.doc(groupId)
										.collection('call_me')
										.doc(locatorId)
										.collection('items')
										.doc(callMeId)
										.delete();
								if (!mounted) return;
								setState(() {
									_pendingCallMeQueue.removeWhere(
										(x) => x['callMeId'] == callMeId,
									);
									_callMeData = _pendingCallMeQueue.isNotEmpty
											? _pendingCallMeQueue.first
											: null;
								});
							},
						),	
				),
							if (!_hasFullAccess && _hasGroup)
								const LocatorSubscriptionExpiredOverlay(),
						],
						),
					);
				}
void openFeedbackMenu() {
final l10n = AppLocalizations.of(context)!;
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FeedbackItem(
                icon: Icons.star_rounded,
                title: l10n.rateOnPlayStore,
                onTap: () async {
									Navigator.pop(context);
									final Uri url = Uri.parse(// ?*?
										"https://play.google.com/store/apps/details?id=com.akinik.findlostgadget.app&pli=1",
									);
									await launchUrl(
										url,
										mode: LaunchMode.externalApplication,
									);
								},
              ),

              const SizedBox(height: 12),

              _FeedbackItem(
                icon: Icons.mail_outline_rounded,
                title: l10n.sendFeedback,
                onTap: () async {
                  Navigator.pop(context);
                  openFeedback();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}	
Future<void> openFeedback() async {
	String _appVersion = '';
	final infoapp = await PackageInfo.fromPlatform();
	_appVersion = "${infoapp.version}+${infoapp.buildNumber}";
	
	
  final info = await DeviceInfoPlugin().androidInfo;


  final body = '''
Message:

---

App version: $_appVersion
Android: ${info.version.release}
Device: ${info.manufacturer} ${info.model}
''';

  final uri = Uri(
    scheme: 'mailto',
    path: 'lynra.dev@gmail.com',
    queryParameters: {
      'subject': 'LynraFamily Member Feedback',
      'body': body,
    },
  );

  await launchUrl(uri);
}		
}

class _FeedbackItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _FeedbackItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Text(
							title,
							style: AppFonts.body.copyWith(
								color: AppColors.textPrimary,
								fontWeight: FontWeight.w600,
							),
						),
          ],
        ),
      ),
    );
  }
}
