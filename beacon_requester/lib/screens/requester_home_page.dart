import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
	String _groupCode = '------';
	String? _groupName;
	double? _myLat;
	double? _myLng;
	String? _requesterId;
	String _requesterName = '';
	bool _isMaster = false;
	Timer? _timeRefreshTimer;
	String _appVersion = '';
	
		@override
	void initState() {
		WidgetsBinding.instance.addObserver(this);
		super.initState();
		FCMService.initialize();
		_homeDataFuture = HomeDataService.loadHomeData();
		_loadLocators();
		_loadGroupCode();
		unawaited(_loadVersion());
		unawaited(_checkForUpdate());
		
		_timeRefreshTimer = Timer.periodic(
			const Duration(minutes: 1),
			(_) {
				if (!mounted) return;
				setState(() {});
			},
		);
	}
	
	@override
	void dispose() {
		WidgetsBinding.instance.removeObserver(this);
		_removeActiveWatchers();
		_timeRefreshTimer?.cancel();
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
		showDialog(
			context: context,
			barrierDismissible: true,
			builder: (context) {
				return AlertDialog(
					title: const Text("Update Available"),
					content: const Text(
						"A new version is available. Update now for the best experience.",
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.pop(context),
							child: const Text("LATER"),
						),
						TextButton(
							onPressed: () async {
								Navigator.pop(context);
								try {
									await InAppUpdate.startFlexibleUpdate();
									await InAppUpdate.completeFlexibleUpdate();
								} catch (_) {}
							},
							child: const Text("UPDATE"),
						),
					],
				);
			},
		);
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
	

  Future<void> _loadGroupCode() async {
  final prefs = await SharedPreferences.getInstance();

  if (!mounted) return;

  setState(() {
    _groupCode =
        prefs.getString('group_code') ?? '------';
  });
}

Future<void> _editGroupName({
  required String groupId,
  required String currentGroupName,
}) async {
  final l10n = AppLocalizations.of(context)!;

  final controller = TextEditingController(
    text: currentGroupName,
  );

  final newName = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.groupName),
        content: TextField(
          controller: controller,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: l10n.groupName,
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

  if (newName == null || newName.isEmpty) return;
  if (newName == currentGroupName) return;

  await FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .update({
    'groupName': newName,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.saved),
    ),
  );
}

Future<void> _editRequesterName() async {
	final l10n = AppLocalizations.of(context)!;
  final currentName =
    await IdentityService.getRequesterName();

	final controller = TextEditingController(
		text: currentName ?? '',
	);

  final newName = await showDialog<String>(
    context: context,
    builder: (context) {
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
              Navigator.pop(context);
            },
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
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
    return;
  }

  final requesterId =
    await IdentityService.getRequesterId();

	if (requesterId == null ||
			requesterId.isEmpty) {
		return;
	}

	await FirebaseFirestore.instance
			.collection('requesters')
			.doc(requesterId)
			.update({
		'name': newName,
		'updatedAt': FieldValue.serverTimestamp(),
	});
	
	await IdentityService.setRequesterName(
		newName,
	);
	
	if (!mounted) return;
	
	setState(() {
		_homeDataFuture = HomeDataService.loadHomeData();
	});

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.saved),
    ),
  );
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
	
	Widget _requesterCodeHeader(String groupId, String groupCode) {
	final l10n = AppLocalizations.of(context)!;
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
              Stack(
								alignment: Alignment.bottomRight,
								children: const [
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
              const SizedBox(width: 6),
              Text(
							    '${l10n.groupCode}',
								textAlign: TextAlign.center,
								style: AppFonts.button.copyWith(color: AppColors.accent),
							),	
							const SizedBox(width: 6),
							Text(
								groupCode,
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
														l10n.waitingForApproval,
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [								
									Column(
  children: [
    Text(
      l10n.title,
      textAlign: TextAlign.center,
      style: AppFonts.title.copyWith(
        fontSize: 24,
        color: AppColors.primary,
      ),
    ),
		Text(
			"Version $_appVersion",
			style: TextStyle(
				color: Colors.white.withOpacity(0.4),
				fontSize: 11,
				fontWeight: FontWeight.w500,
			),
		),
    const SizedBox(height: 6),

    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .snapshots(),
      builder: (context, snapshot) {
        final liveGroupName =
            snapshot.data?.data()?['groupName'] ??
            groupName;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        liveGroupName,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.title.copyWith(
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _editGroupName(
                          groupId: groupId,
                          currentGroupName: liveGroupName,
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
								child: Row(
									mainAxisAlignment: MainAxisAlignment.end,
									children: [
										Flexible(
											child: Text(
												requesterName,
												overflow: TextOverflow.ellipsis,
												textAlign: TextAlign.right,
												style: AppFonts.title.copyWith(
													fontSize: 20,
													color: AppColors.primary,
												),
											),
										),

										const SizedBox(width: 4),

										GestureDetector(
											onTap: _editRequesterName,
											child: Icon(
												Icons.edit_rounded,
												size: 18,
												color: AppColors.primary,
											),
										),
									],
								),
							),
            ],
          ),
        );
      },
    ),
  ],
),
									
									Row(
										children: [										
											const SizedBox(width: 16),								
											_requesterCodeHeader(groupId, _groupCode),
											const Spacer(),
											TextButton.icon(
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
													color: AppColors.accent,
												),
												label: Row(
													mainAxisSize: MainAxisSize.min,
													children: [
														Text(
															Localizations.localeOf(context).languageCode == 'tr'
																	? 'TR'
																	: 'EN',
															style: AppFonts.caption.copyWith(
																color: AppColors.accent,
																fontWeight: FontWeight.w600,
															),
														),
														const Icon(
															Icons.arrow_drop_down,
															size: 18,
															color: AppColors.accent,
														),
													],
												),
											)
										],
									),							
		const SizedBox(height: 4),

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

    return AppCard(
      onTap: () async {
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
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            const Icon(
              Icons.add_rounded,
              color: AppColors.primary,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                isFull
                    ? '${l10n.addMember} (${l10n.memberlimitreached})'
                    : l10n.addMember,
                style: AppFonts.button.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),

            
          ],
        ),
      ),
    );
  },
),
							const SizedBox(height: 4),

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

                  const SizedBox(height: 4),

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
															final l10n = AppLocalizations.of(context)!;
															final lastSeenText = TimeHelper.formatLastSeen(
																locator['lastSeen'],
																l10n,
															);															
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
    .delete();

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



