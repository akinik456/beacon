import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/home_data_service.dart';
import 'add_locator_page.dart';
import 'create_group_page.dart';
import 'join_group_page.dart';
import '../services/locator_list_service.dart';
import '../services/group_service.dart';
import '../core/widgets/locator_status_card.dart';
import '../utils/time_helper.dart';
import '../utils/location_helper.dart';
import '../utils/map_helper.dart';
import '../services/identity_service.dart';
import '../services/fcm_service.dart';
import 'locator_settings_page.dart';
import '../utils/address_helper.dart';
import '../services/request_location_service.dart';
import '../services/active_watcher_service.dart';
import '../services/join_request_service.dart';
import 'locator_notify_page.dart';
import '../core/widgets/call_me_overlay.dart';
import '../core/widgets/alert_overlay.dart';
import '../core/widgets/requester_list_card.dart';
import '../core/widgets/join_request_card.dart';
import 'language_select_page.dart';
import '../l10n/app_localizations.dart';


class RequesterHomePage extends StatefulWidget {
  const RequesterHomePage({super.key});

  @override
  State<RequesterHomePage> createState() =>
      _RequesterHomePageState();
}

class _RequesterHomePageState
    extends State<RequesterHomePage>
    with WidgetsBindingObserver {
		
	List<Map<String, dynamic>> _locators = [];
	final List<StreamSubscription> _subscriptions = [];
	Map<String, dynamic>? _callMeData;
	List<Map<String, dynamic>> _pendingCallMeQueue = [];
	Map<String, dynamic>? _alertData;
	late Future<Map<String, dynamic>?> _homeDataFuture;
	
	String? _groupId;
	double? _myLat;
	double? _myLng;
	String? _requesterId;
	bool _isMaster = false;
	
	
		@override
	void initState() {
		WidgetsBinding.instance.addObserver(this);
		super.initState();
		FCMService.initialize();
		_homeDataFuture = HomeDataService.loadHomeData();
		_loadLocators();
	}
	
	@override
	void dispose() {
		WidgetsBinding.instance.removeObserver(this);
		_removeActiveWatchers();
		super.dispose();
	}
	
	@override
	void didChangeAppLifecycleState(
		AppLifecycleState state,
	) async {
		print("BEACON LIFECYCLE => $state");

		if (state == AppLifecycleState.resumed) {
			await _addActiveWatchers();
		}

		if (state == AppLifecycleState.paused ||
				state == AppLifecycleState.detached) {
			await _removeActiveWatchers();
		}
	}	
	
	Future<void> _loadLocators() async {
		_groupId = await GroupService.getLocalGroupId();
		_isMaster = await GroupService.getLocalIsMaster();
		_requesterId = await IdentityService.getRequesterId();

		if (_groupId == null || _groupId!.isEmpty) {
			print("BEACON HOME => no group yet, skip locator load");
			return;
		}

		final position =
				await LocationHelper.getCurrentPosition();

		_myLat = position?.latitude;
		_myLng = position?.longitude;

		print(
			"BEACON REQUESTER POS => "
			"$_myLat, $_myLng",
		);

		final locators =
				await LocatorListService.loadLocators();
						

				setState(() {
					_locators = locators;
				});
				for (final locator in locators) {
			_listenLocatorPresence(
				locator['locatorId'],
			);
		await _addActiveWatchers();	
		}
	_listenCallMe();
	_listenAlerts();
	}
	
	Future<void> _addActiveWatchers() async {
		if (_groupId == null) return;
		
		final _requesterName = await IdentityService.getRequesterName();
		final _requesterCode = await IdentityService.getRequesterCode();

		for (final locator in _locators) {
			final locatorId = locator['locatorId'];

			if (locatorId == null) continue;

			await ActiveWatcherService.addWatcher(
				requesterName: _requesterName!,
				requesterCode: _requesterCode!,
				groupId: _groupId!,
				locatorId: locatorId,
			);
		}
	}

	Future<void> _removeActiveWatchers() async {
		if (_groupId == null) return;

		for (final locator in _locators) {
			final locatorId = locator['locatorId'];

			if (locatorId == null) continue;

			await ActiveWatcherService.removeWatcher(
				groupId: _groupId!,
				locatorId: locatorId,
			);
		}
	}	
	
	void _listenLocatorPresence(String locatorId) {
		if (_groupId == null) return;

		final sub = FirebaseDatabase.instance
				.ref(
					'presence/groups/$_groupId/locators/$locatorId',
				)
				.onValue
				.listen((event) async {
		final value = event.snapshot.value;

		print(
			"BEACON PRESENCE UPDATE => "
			"$locatorId => $value",
		);

		if (value is! Map) return;

		final presence =
				Map<String, dynamic>.from(value as Map);

		if (!mounted) return;

final lat = presence['lat']?.toDouble();
final lng = presence['lng']?.toDouble();

String address = 'Address not available';

if (lat != null && lng != null) {
  address = await AddressHelper.getAddressFromLatLng(
    lat: lat,
    lng: lng,
  );
}

		if (!mounted) return;

		setState(() {
			final index = _locators.indexWhere(
				(x) => x['locatorId'] == locatorId,
			);

			if (index == -1) return;

			_locators[index] = {
				..._locators[index],
				...presence,
				if (address != null) 'address': address,
			};
		});
	});

		_subscriptions.add(sub);
	}
	
	void _listenCallMe() async {

		final groupId =
				await GroupService.getLocalGroupId();

		final requesterId =
				await IdentityService.getRequesterId();

		if (groupId == null ||
				requesterId == null) {
			return;
		}

		final sub = FirebaseFirestore.instance
				.collection('groups')
				.doc(groupId)
				.collection('call_me')
				.doc(requesterId)
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
	
void _listenAlerts() async {
  final groupId = await GroupService.getLocalGroupId();
  final requesterId = await IdentityService.getRequesterId();

  if (groupId == null || requesterId == null) {
    return;
  }

  final sub = FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('alerts')
      .doc(requesterId)
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
			
			if (!mounted) return;
			setState(() {
				_alertData = {
					...data,
					'alertDocId': change.doc.id,
				};
			});

      print("BEACON ALERT => ${change.doc.id} => $data");
    }
  });

  _subscriptions.add(sub);
}	
	

  Future<String> _loadGroupCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('group_code') ?? '------';
  }


  void _showGroupQrDialog({
  required BuildContext context,
  required String groupId,
  required String groupCode,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      final l10n =
          AppLocalizations.of(dialogContext)!;

      return Dialog(
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
                l10n.groupQRCode,
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
                  data: groupId,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                l10n.groupCode,
                style: AppFonts.caption,
              ),

              const SizedBox(height: 6),

              Text(
                groupCode,
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


	Widget _buildNoGroupHome({
		required String requesterName,
	}) {
	final l10n = AppLocalizations.of(context)!;
		return Padding(
			padding: const EdgeInsets.all(20),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Text(
						l10n.wellcome,
						style: AppFonts.title.copyWith(
							fontSize: 26,
							color: AppColors.primary,
						),
					),

					const SizedBox(height: 6),

					Text(
						l10n.adminName,
						style: AppFonts.caption,
					),

					const SizedBox(height: 24),

					AppCard(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									l10n.noGroupYet,
									style: AppFonts.subtitle,
								),

								const SizedBox(height: 8),

								Text(
									l10n.createOrJoin,
									style: AppFonts.body.copyWith(
										color: AppColors.textSecondary,
									),
								),

								const SizedBox(height: 20),

								SizedBox(
									width: double.infinity,
									height: 52,
									child: ElevatedButton(
										onPressed: () async {
											final changed =
													await Navigator.push<bool>(
												context,
												MaterialPageRoute(
													builder: (_) =>
															CreateGroupPage(),
												),
											);

											if (changed == true &&
													context.mounted) {
												Navigator.pushReplacement(
													context,
													MaterialPageRoute(
														builder: (_) =>
																const RequesterHomePage(),
													),
												);
											}
										},
										child: Text(
											l10n.createNewGroup,
										),
									),
								),

								const SizedBox(height: 12),

								SizedBox(
									width: double.infinity,
									height: 52,
									child: ElevatedButton(
										onPressed: () async {
											final changed =
													await Navigator.push<bool>(
												context,
												MaterialPageRoute(
													builder: (_) =>
															JoinGroupPage(),
												),
											);

											if (changed == true &&
													context.mounted) {
												Navigator.pushReplacement(
													context,
													MaterialPageRoute(
														builder: (_) =>
																const RequesterHomePage(),
													),
												);
											}
										},
										child: Text(
											l10n.joinGroup,
										),
									),
								),

							],
						),
					),
				],
			),
		);
	}


  @override
  Widget build(BuildContext context) {
	final l10n = AppLocalizations.of(context)!;
    return Stack(
  children: [
    Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _homeDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              );
            }

            final data = snapshot.data;

            if (data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Home data could not be loaded.',
                    style: AppFonts.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
						
						if (data['isPending'] == true) {
				final groupId = data['groupId'];
				final requesterId = data['requesterId'];

				return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
					stream: FirebaseFirestore.instance
							.collection('groups')
							.doc(groupId)
							.collection('join_requests')
							.doc(requesterId)
							.snapshots(),
					builder: (context, joinSnapshot) {
						final joinData = joinSnapshot.data?.data();
						final status = joinData?['status'];

						if (status == 'rejected') {
							return Center(
								child: Padding(
									padding: const EdgeInsets.all(24),
									child: AppCard(
										child: Column(
											mainAxisSize: MainAxisSize.min,
											children: [
												const Icon(
													Icons.block_rounded,
													color: AppColors.danger,
													size: 48,
												),

												const SizedBox(height: 16),

												Text(
													l10n.rejected,
													style: AppFonts.title.copyWith(
														color: AppColors.danger,
													),
												),

												const SizedBox(height: 20),

												SizedBox(
													width: double.infinity,
													child: ElevatedButton(
														onPressed: () async {

															await FirebaseFirestore.instance
																	.collection('groups')
																	.doc(groupId)
																	.collection('join_requests')
																	.doc(requesterId)
																	.delete();

															await GroupService.clearLocalGroup();

															if (!context.mounted) return;

															Navigator.pushReplacement(
																context,
																MaterialPageRoute(
																	builder: (_) =>
																			const RequesterHomePage(),
																),
															);
														},
														child: Text(l10n.ok),
													),
												),
											],
										),
									),
								),
							);
						}

						return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
							stream: FirebaseFirestore.instance
									.collection('groups')
									.doc(groupId)
									.collection('devices')
									.doc(requesterId)
									.snapshots(),
								builder: (context, deviceSnapshot) {
								if (deviceSnapshot.hasData &&
										deviceSnapshot.data!.exists) {
									Future.microtask(() {
										if (!context.mounted) return;

										Navigator.pushReplacement(
											context,
											MaterialPageRoute(
												builder: (_) => const RequesterHomePage(),
											),
										);
									});
								}

								return Center(
									child: Padding(
										padding: const EdgeInsets.all(24),
										child: AppCard(
											child: Column(
												mainAxisSize: MainAxisSize.min,
												children: [
													const Icon(
														Icons.hourglass_top_rounded,
														color: AppColors.primary,
														size: 48,
													),
													const SizedBox(height: 16),
													Text(
														l10n.waitingForApprovale,
														style: AppFonts.title,
													),
													const SizedBox(height: 8),
													Text(
														l10n.yourrequest,
														textAlign: TextAlign.center,
														style: AppFonts.body.copyWith(
															color: AppColors.textSecondary,
														),
													),
												],
											),
										),
									),
								);
							},
						);
					},
				);
			}

            final hasGroup =
                data['hasGroup'] == true;

            final requesterName =
                data['requesterName'] ?? '-';

            if (!hasGroup) {
              return _buildNoGroupHome(
                requesterName: requesterName,
              );
            }

            final groupId = data['groupId'] ?? '';
            final groupName = data['groupName'] ?? '-';
            final pairedLocators =
                Map<String, dynamic>.from(data['pairedLocators'] ?? {});

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
            groupName,
            style: AppFonts.title.copyWith(
              fontSize: 26,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            requesterName,
            style: AppFonts.caption,
          ),
        ],
      ),
    ),

    TextButton.icon(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LanguageSelectPage(),
          ),
        );

        if (!mounted) return;
        setState(() {});
      },
      icon: const Icon(
        Icons.language_rounded,
        size: 18,
      ),
      label: Text(
        Localizations.localeOf(context).languageCode == 'tr'
            ? 'Türkçe'
            : 'English',
      ),
    ),

    const SizedBox(width: 10),

    FutureBuilder<String>(
      future: _loadGroupCode(),
      builder: (context, snapshot) {
        final groupCode = snapshot.data ?? '------';

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (groupId.isEmpty) return;

            _showGroupQrDialog(
              context: context,
              groupId: groupId,
              groupCode: groupCode,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
										'${l10n.group}\n'
										'${l10n.code}',
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
                groupCode,
                style: AppFonts.subtitle.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );
      },
    ),
  ],
),

		const SizedBox(height: 18),

		if (_isMaster && _groupId != null)
			JoinRequestCard(
				groupId: _groupId!,
			),
			
			if (_isMaster && _groupId != null)
			RequesterListCard(
				groupId: _groupId!,
			),

		StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
  stream: FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .snapshots(),
  builder: (context, snapshot) {
    final data = snapshot.data?.data();

    final maxLocators = data?['maxLocators'] ?? 1;
    final activeLocatorCount = data?['activeLocatorCount'] ?? 0;
    final isFull = activeLocatorCount >= maxLocators;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: isFull
            ? null
            : () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddLocatorPage(),
                  ),
                );

                if (changed == true && context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RequesterHomePage(),
                    ),
                  );
                }
              },
        icon: Icon(
          Icons.add_rounded,
          color: isFull
              ? AppColors.textSecondary
              : AppColors.primary,
        ),
        label: Text(
          isFull ? l10n.memberlimitreached : l10n.addMember,
          style: AppFonts.button.copyWith(
            color: isFull
                ? AppColors.textSecondary
                : AppColors.primary,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: isFull
                ? AppColors.textSecondary.withValues(alpha: 0.20)
                : AppColors.primary.withValues(alpha: 0.25),
          ),
          backgroundColor: isFull
              ? AppColors.textSecondary.withValues(alpha: 0.04)
              : AppColors.primary.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  },
),

							const SizedBox(height: 18),

                  AppCard(
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
                            '${pairedLocators.length}  ${l10n.pairedMember}',
                            style: AppFonts.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Expanded(
                    child: _locators.isEmpty
                        ? Center(
                            child: Text(
                              l10n.noPairedMemberYet,
                              style: AppFonts.caption,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: _locators.length,//itemCount: _locators.isEmpty ? 0 : 4,//itemCount: _locators.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final locator = _locators[index];//final locator = _locators[0];//final locator = _locators[index];
															final locatorId = locator['locatorId'] ?? '-';															
															final locatorName = locator['name'] ?? 'Member';
															final locatorCode = locator['locatorCode'] ?? '------';
															final status = locator['status'] ?? 'offline';
															final battery = locator['battery'] ?? 0;
															final gpsEnabled = locator['gpsEnabled'] == true;																	
															final lastSeenText = TimeHelper.formatLastSeen(locator['lastSeen'],);															
															final distanceMeters = LocationHelper.distanceMeters(fromLat: _myLat,fromLng: _myLng,toLat: locator['lat']?.toDouble(),toLng: locator['lng']?.toDouble(),);
															final distanceText = distanceMeters == null ? '-' : '${distanceMeters.round()} m';
															return LocatorStatusCard(
																locatorName: locatorName,
																locatorCode: locatorCode,
																status: status,
																battery: battery,
																gpsEnabled: gpsEnabled,
																lastSeenText: lastSeenText,
																distanceText: distanceText,
																onOpenMaps: () async {
																	final lat = locator['lat']?.toDouble();
																	final lng = locator['lng']?.toDouble();
																	if (lat == null || lng == null) return;
																	await MapHelper.openInMaps(
																		lat: lat,
																		lng: lng,
																	);
																},
																onRequestLocation: () async {
																	if (_groupId == null || _requesterId == null) return;
																	await RequestLocationService.createRequestLocation(
																		groupId: groupId,
																		requesterId: _requesterId!,
																		locatorId: locatorId,
																	);
																},
																addressText: locator['address'] ?? 'Address not available',
																onNotificationSettings: () {
																	 Navigator.push(
																		context,
																		MaterialPageRoute(
																			builder: (_) => LocatorNotifyPage(
																				locatorId: locatorId,
																				locatorName: locatorName,
																				locatorCode: locatorCode,
																			),
																		),
																	);
																},
																onSettings: () {
																	Navigator.push(
																		context,
																		MaterialPageRoute(
																			builder: (_) => LocatorSettingsPage(
																				locatorId: locatorId,
																				locatorName: locatorName,
																				locatorCode: locatorCode,
																				address: locator['address'] ?? '',
																				isMaster: _isMaster,
																			),
																		),
																	);
																},
																onRemove: () async {
																	final result = await showDialog<bool>(
																		context: context,
																		builder: (_) => AlertDialog(
																			backgroundColor: AppColors.surface,
																			title: Text(
																				l10n.removeMember,
																				style: AppFonts.title,
																			),
																			content: Text(
																				l10n.thismember,
																				style: AppFonts.body.copyWith(
																					color: AppColors.textSecondary,
																				),
																			),
																			actions: [
																				TextButton(
																					onPressed: () {
																						Navigator.pop(context, false);
																					},
																					child: Text(
																						l10n.cancel,
																						style: AppFonts.button.copyWith(
																							color: AppColors.textSecondary,
																						),
																					),
																				),
																				TextButton(
																					onPressed: () {
																						Navigator.pop(context, true);
																					},
																					child: Text(
																						l10n.remove,
																						style: AppFonts.button.copyWith(
																							color: AppColors.danger,
																						),
																					),
																				),
																			],
																		),
																	);

																	if (result != true) return;
																	
																	if (_groupId == null) return;

																	await ActiveWatcherService.removeWatcher(
																		groupId: _groupId!,
																		locatorId: locatorId,
																	);

																	await GroupService.removePairedLocator(
																		locatorId: locatorId,
																	);

																	if (!context.mounted) return;
																	
																	await _loadLocators();
																	
																	if (!context.mounted) return;

																	ScaffoldMessenger.of(context).showSnackBar(
																		SnackBar(
																			content: Text(l10n.memberremoved),
																		),
																	);

																	setState(() {});
																},
															);
                            },
                          ),
                  ),
                ],
              ),
            );
						
          },
        ),
      ),
    ),
		if (_callMeData != null)
	CallMeOverlay(
    data: _callMeData!,
    onDismiss: () async {

      final callMeId =
          _callMeData!['callMeId'];

      final groupId =
          _callMeData!['groupId'];

      final requesterId =
          _callMeData!['targetRequesterId'];

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('call_me')
          .doc(requesterId)
          .collection('items')
          .doc(callMeId)
          .update({
        'status': 'dismissed',
        'dismissedAt':
            FieldValue.serverTimestamp(),
      });

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
	
if (_alertData != null)
  AlertOverlay(
    data: _alertData!,
    onDismiss: () async {
  final alertDocId = _alertData!['alertDocId'];
  final groupId = _alertData!['groupId'];
  final requesterId = _alertData!['targetRequesterId'];

  await FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('alerts')
      .doc(requesterId)
      .collection('items')
      .doc(alertDocId)
      .update({
    'status': 'dismissed',
    'dismissedAt': FieldValue.serverTimestamp(),
  });

  if (!mounted) return;

  setState(() {
    _alertData = null;
  });
},
		
  ),	
		],
		);

  }
}



