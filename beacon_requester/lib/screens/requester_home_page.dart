//?*?Free trial $_trialDaysLeft days left
import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/home_data_service.dart';
import 'add_locator_page.dart';
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
import '../services/active_watcher_service.dart';
import 'locator_notify_page.dart';
import '../core/widgets/call_me_overlay.dart';
import '../core/widgets/alert_overlay.dart';
import 'language_select_page.dart';
import '../l10n/app_localizations.dart';
import '../services/subscription_service.dart';
import '../core/widgets/subscription_expired_overlay.dart';
import '../core/widgets/group_info_panel.dart';
import '../services/requester_name_editor.dart';
import '../core/widgets/guide_panel.dart';
import '../services/notification_service.dart';
import '../services/requester_registry_service.dart';
import '../core/widgets/app_banner.dart';
import '../core/widgets/dialogs/app_confirm_dialog.dart';
import '../core/widgets/dialogs/app_info_dialog.dart';
import '../core/widgets/dialogs/app_input_dialog.dart';
import '../services/theme_service.dart';
import '../services/rtdb_auth_mapping_service.dart';
import '../utils/log.dart';
import 'live_tracking_map_page.dart';
import '../services/pending_pairing_manager.dart';
import '../services/pending_pairing_service.dart';
import '../services/pairing_response_service.dart';
import '../core/widgets/sos_overlay.dart';
import '../services/analytics_service.dart';


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
	List<Map<String, dynamic>> _pendingAlertQueue = [];
	Map<String, dynamic>? _sosData;
	final List<Map<String, dynamic>> _pendingSosQueue = [];
	late Future<Map<String, dynamic>?> _homeDataFuture;
	
	double? _myLat;
	double? _myLng;
	String? _requesterId;
	String _requesterName = '';
	bool _isMaster = false;
	Timer? _timeRefreshTimer;
	String _appVersion = '';
	bool _hasGroup = false;
	bool _showGroupInfo = false;
	bool _showGuide = false;
	bool _appInForeground = true;
	bool _isDarkTheme = true;
	
	StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
	bool _isPremium = false;
	bool _trialActive = false;
	bool _isEntitled = true;

	bool get _hasFullAccess => true;
			/*?*?(_isPremium || _trialActive) &&
			(_isMaster || _isEntitled);*/
	int _trialDaysLeft = 0;
	//final Map<String, DateTime> _lastMovementAlert = {};
	Timer? _requesterPositionTimer;
	DateTime? _lastRequesterLocationUpdate;
	bool _locatorsLoaded = false;
	
		@override
	void initState() {
		WidgetsBinding.instance.addObserver(this);
		super.initState();
		Log.d("RequesterHome initState");
	Log.d("state _hasFullAccess $_hasFullAccess ,_isPremium $_isPremium ,_trialActive $_trialActive"); 
		_homeDataFuture = HomeDataService.loadHomeData();
		_loadTheme();
		unawaited(_startHome());
		unawaited(_loadVersion());
		unawaited(_checkForUpdate());
		
		_timeRefreshTimer = Timer.periodic(
			const Duration(minutes: 1),
			(_) {
				if (!mounted) return;
				setState(() {});
			},
		);
		
	
		_purchaseSub =
    InAppPurchase.instance.purchaseStream.listen(
  (purchases) async {
    for (final purchase in purchases) {
      Log.d(
        "BEACON IAP => "
        "product=${purchase.productID} "
        "status=${purchase.status} "
        "purchaseId=${purchase.purchaseID} "
        "pendingComplete=${purchase.pendingCompletePurchase}",
      );

      bool purchaseProcessed = false;

      try {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          final purchaseId = purchase.purchaseID;

          if (purchaseId == null || purchaseId.isEmpty) {
            Log.d(
              "BEACON IAP => missing purchaseId "
              "${purchase.productID}",
            );
          } else {
            await SubscriptionService.processPurchase(
              productId: purchase.productID,
              purchaseId: purchaseId,
            );

            purchaseProcessed = true;

            if (purchase.productID ==
                    'lynrafamily_lifetime' &&
                mounted) {
              setState(() {
                _isPremium = true;
                _trialActive = false;
              });
            }

            Log.d(
              "BEACON IAP => purchase processed "
              "product=${purchase.productID} "
              "purchaseId=$purchaseId",
            );
          }
        }

        if (purchase.status == PurchaseStatus.error) {
          Log.d(
            "BEACON IAP => purchase error "
            "product=${purchase.productID} "
            "code=${purchase.error?.code} "
            "message=${purchase.error?.message}",
          );
        }

        if (purchase.status == PurchaseStatus.canceled) {
          Log.d(
            "BEACON IAP => purchase canceled "
            "product=${purchase.productID}",
          );
        }

        if (purchase.pendingCompletePurchase) {
          final canComplete =
              purchase.status != PurchaseStatus.purchased &&
                  purchase.status != PurchaseStatus.restored ||
              purchaseProcessed;

          if (canComplete) {
            Log.d(
              "BEACON IAP => completePurchase start "
              "product=${purchase.productID} "
              "purchaseId=${purchase.purchaseID}",
            );

            await InAppPurchase.instance.completePurchase(
              purchase,
            );

            Log.d(
              "BEACON IAP => completePurchase success "
              "product=${purchase.productID} "
              "purchaseId=${purchase.purchaseID}",
            );
          } else {
            Log.d(
              "BEACON IAP => completePurchase skipped "
              "because processPurchase failed "
              "product=${purchase.productID} "
              "purchaseId=${purchase.purchaseID}",
            );
          }
        }
      } catch (e, stackTrace) {
        Log.e(
          "BEACON IAP => processing failed "
          "product=${purchase.productID} "
          "purchaseId=${purchase.purchaseID}",
          e,
        );

        Log.d(
          "BEACON IAP => stackTrace=$stackTrace",
        );

        // processPurchase başarısızsa burada
        // completePurchase çağrılmıyor.
      }
    }
  },
  onError: (Object error, StackTrace stackTrace) {
    Log.e(
      "BEACON IAP => purchase stream error",
      error,
    );

    Log.d(
      "BEACON IAP => purchase stream "
      "stackTrace=$stackTrace",
    );
  },
);
		
	}
	
	@override
	void dispose() {
		WidgetsBinding.instance.removeObserver(this);
		_removeActiveWatchers();
		_timeRefreshTimer?.cancel();
		_purchaseSub?.cancel();
		_stopRequesterPositionTimer();
		super.dispose();
	}
	
	@override
	void didChangeAppLifecycleState(
		AppLifecycleState state,
	) async {
		Log.d("BEACON LIFECYCLE => $state");

		if (state == AppLifecycleState.resumed) {
			await _addActiveWatchers();
		}

		if (state == AppLifecycleState.paused ||
				state == AppLifecycleState.detached) {
			await _removeActiveWatchers();
		}
	_appInForeground = state == AppLifecycleState.resumed;
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
	Future<void> _startHome() async {
	Log.d("_startHome called");

final count1 = await FirebaseFirestore.instance
	.collection('locators')
	.count()
	.get();
Log.d("FIRESTORE_COUNT LOCATOR COUNT => ${count1.count}");
	
final count2 = await FirebaseFirestore.instance
	.collection('requesters')
	.count()
	.get();
Log.d("FIRESTORE_COUNT REQUESTER COUNT => ${count2.count}");
	
		
		await RtdbAuthMappingService.syncRequesterAuth();
		final isMaster = await GroupService.getLocalIsMaster();
		_isMaster = isMaster;
		
		await cleanupInvalidPairedLocators();
		

		await _initTrial();

		bool isEntitled = true;

		if (!_isMaster) {
			final requesterId = await IdentityService.getRequesterId();

			if (requesterId == null ||
					requesterId.isEmpty) {
				isEntitled = false;
			} else {
				final deviceDoc = await FirebaseFirestore.instance
						.doc(requesterId)
						.get();

				isEntitled =
						deviceDoc.data()?['isEntitled'] != false;
			}

			Log.d(
				"BEACON SUBSCRIPTION => "
				"requester isEntitled=$isEntitled",
			);
		}

		if (!_hasFullAccess) {
			Log.d(
				"BEACON SUBSCRIPTION => "
				"inactive or not entitled, skip server listeners _hasFullAccess:$_hasFullAccess,isEntitled:$isEntitled",
			);

			if (!mounted) return;

			setState(() {});
			_hasGroup = true;
			return;
		}

		await _loadLocators();
		await FCMService.initialize();
		
		await PendingPairingManager.start(
			onApproved: () async {
				await _loadLocators();

				if (!mounted) return;

				AppBanner.success(
					context,
					AppLocalizations.of(context)!.memberpaired,
				);
			},
			onRejected: () async {
				if (!mounted) return;

				AppBanner.error(
					context,
					AppLocalizations.of(context)!.pairingRejected,
				);
			},
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
	
	void _showUpdateDialog() async {
		final l10n = AppLocalizations.of(context)!;

		await AppInfoDialog.show(
			context: context,
			title: l10n.updateAvailable,
			message: l10n.aNewVer,
			cancelText: l10n.later,
			confirmText: l10n.update,
			onConfirm: () async {
				try {
					await InAppUpdate.startFlexibleUpdate();
					await InAppUpdate.completeFlexibleUpdate();
				} catch (_) {}
			},
		);
	}
	
	Future _loadLocators() async {
  _requesterId = await IdentityService.getRequesterId();

  Log.d("loadLocators called");
	
	// Önce locatorları yükle, kartlar hemen açılsın
  final locators =
      await LocatorListService.loadLocators();
	
	if (!mounted) return;

  setState(() {
    _locators = locators;
		_locatorsLoaded = true;
  });
	
	// Presence listener'ları başlat
  for (final locator in locators) {
    _listenLocatorPresence(
      locator['locatorId'],
    );
  }
	
	  // Active watcher
  await _addActiveWatchers();

  _listenCallMe();
  _listenAlerts();
  _listenSos();


  // GPS'i en sona bırak
  final position =
      await LocationHelper.getCurrentPosition();

  _myLat = position?.latitude;
  _myLng = position?.longitude;

  Log.d(
    "BEACON REQUESTER POS => "
    "$_myLat, $_myLng",
  );

}
	
	Future<void> _addActiveWatchers() async {
		
		final _requesterName = await IdentityService.getRequesterName();
		final _requesterCode = await IdentityService.getRequesterCode();
Log.d("_addActiveWatchers IdentityService.getRequesterName");

		for (final locator in _locators) {
			final locatorId = locator['locatorId'];

			if (locatorId == null) continue;

			await ActiveWatcherService.addWatcher(
				requesterName: _requesterName!,
				requesterCode: _requesterCode!,
				locatorId: locatorId,
			);
		}
	}

	Future<void> _removeActiveWatchers() async {
	_stopRequesterPositionTimer();

		for (final locator in _locators) {
			final locatorId = locator['locatorId'];

			if (locatorId == null) continue;

			await ActiveWatcherService.removeWatcher(
				locatorId: locatorId,
			);
		}
	}	

void _stopRequesterPositionTimer() {
  _requesterPositionTimer?.cancel();
  _requesterPositionTimer = null;
}

Future<void> _updateRequesterPositionIfNeeded() async {
  final now = DateTime.now();

  if (_lastRequesterLocationUpdate != null &&
      now.difference(_lastRequesterLocationUpdate!).inSeconds < 10) {
    return;
  }

  _lastRequesterLocationUpdate = now;

  await _updateRequesterPosition();
}

Future<void> _updateRequesterPosition() async {
  final position = await LocationHelper.getCurrentPosition();
Log.d("_updateRequesterPosition is called");
  if (position == null || !mounted) return;

  setState(() {
    _myLat = position.latitude;
    _myLng = position.longitude;
  });
}	
static Future<void> cleanupInvalidPairedLocators() async {
  final requesterId = await IdentityService.getRequesterId();

  if (requesterId == null) {
    Log.d("BEACON CLEANUP REQ => missing group/requester");
    return;
  }

  final requesterDeviceRef = FirebaseFirestore.instance
			.collection('requesters')
      .doc(requesterId);

  final requesterSnap = await requesterDeviceRef.get();
  final requesterData = requesterSnap.data();

  if (requesterData == null) {
    Log.d("BEACON CLEANUP REQ => requester device doc not found");
    return;
  }

  final pairedLocators = Map<String, dynamic>.from(
    requesterData['pairedLocators'] ?? {},
  );

  if (pairedLocators.isEmpty) {
    Log.d("BEACON CLEANUP REQ => no paired locators");
    return;
  }

  final batch = FirebaseFirestore.instance.batch();
  int removedCount = 0;

  for (final locatorId in pairedLocators.keys) {
    final locatorDeviceRef = FirebaseFirestore.instance
				.collection('locators')
        .doc(locatorId);

    final locatorSnap = await locatorDeviceRef.get();
    final locatorData = locatorSnap.data();

    final isValidLocator = locatorSnap.exists;
       /* locatorSnap.exists &&
        locatorData?['active'] == true &&
        locatorData?['role'] == 'locator';?*? */

    if (!isValidLocator) {
      batch.update(requesterDeviceRef, {
        'pairedLocators.$locatorId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      removedCount++;
    }
  }

  if (removedCount == 0) {
    Log.d("BEACON CLEANUP REQ => paired locators valid");
    return;
  }

  await batch.commit();

  Log.d(
    "BEACON CLEANUP REQ => removed invalid paired locators count=$removedCount",
  );
}
	
	void _listenLocatorPresence(String locatorId) {
	final l10n = AppLocalizations.of(context)!;

		final sub = FirebaseDatabase.instance
				.ref(
					'presence/locators/$locatorId',
				)
				.onValue
				.listen((event) async {
				final value = event.snapshot.value;

				Log.d(
					"BEACON PRESENCE UPDATE => "
					"$locatorId => $value",
				);

				if (value is! Map) return;

				final presence =
						Map<String, dynamic>.from(value as Map);

				//final movedMeters = (presence['movedSinceLastUpdateMeters'] as num?)?.toDouble() ?? 0;

				final locator = _locators.firstWhere(
					(x) => x['locatorId'] == locatorId,
					orElse: () => {},
				);
			
				if (!mounted) return;

				final lat = presence['lat']?.toDouble();
				final lng = presence['lng']?.toDouble();

				String address = '';

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

					final oldAddress =
					_locators[index]['address'] as String? ?? '';

					final finalAddress = address.isNotEmpty
							? address
							: oldAddress.isNotEmpty
									? oldAddress
									: l10n.addressNotAvailable;

					_locators[index] = {
						..._locators[index],
						...presence,
						'address': finalAddress,
					};
				});
				_updateRequesterPositionIfNeeded();
			});
		_subscriptions.add(sub);
	}
	
	void _listenCallMe() async {

		final requesterId =
				await IdentityService.getRequesterId();

		if (requesterId == null) {
			return;
		}

		final sub = FirebaseFirestore.instance
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

							_callMeData = item;
						});
					}
				});
		_subscriptions.add(sub);
	}
	
	void _listenAlerts() async {
  final requesterId = await IdentityService.getRequesterId();

  if (requesterId == null) {
    return;
  }

  final sub = FirebaseFirestore.instance
      .collection('alerts')
      .doc(requesterId)
      .collection('items')
      .orderBy(
        'createdAt',
        descending: false,
      )
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
        'alertDocId': change.doc.id,
      };

      if (!mounted) return;

      setState(() {
        final alreadyExists = _pendingAlertQueue.any(
          (x) => x['alertDocId'] == item['alertDocId'],
        );

        if (!alreadyExists) {
          _pendingAlertQueue.add(item);
        }

        _pendingAlertQueue.sort((a, b) {
          final aTime = a['createdAt'] as Timestamp?;
          final bTime = b['createdAt'] as Timestamp?;

          return (aTime?.millisecondsSinceEpoch ?? 0)
              .compareTo(
            bTime?.millisecondsSinceEpoch ?? 0,
          );
        });

        _alertData = _pendingAlertQueue.isNotEmpty
            ? _pendingAlertQueue.last
            : null;
      });
    }
  });

  _subscriptions.add(sub);
}
void _listenSos() async {

  final requesterId =
      await IdentityService.getRequesterId();

  if (requesterId == null) {
    return;
  }

  final sub = FirebaseFirestore.instance
      .collection('sos')
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
            'sosId': change.doc.id,
          };

          if (!mounted) return;

          setState(() {
            final alreadyExists =
                _pendingSosQueue.any(
              (x) => x['sosId'] == item['sosId'],
            );

            if (!alreadyExists) {
              _pendingSosQueue.add(item);
            }

            _sosData = item;
          });
        }
      });

  _subscriptions.add(sub);
}	

Future<void> _buy(String productId) async {
  Log.d("BEACON IAP => query start productId=$productId");

  final response =
      await InAppPurchase.instance.queryProductDetails({
    productId,
  });

  if (response.productDetails.isEmpty) {
    Log.d(
      "BEACON IAP => Product not found "
      "notFound=${response.notFoundIDs}",
    );
    return;
  }

  final product = response.productDetails.first;

  Log.d(
    "BEACON IAP => found product "
    "${product.id} ${product.price}",
  );

  final purchaseParam = PurchaseParam(
    productDetails: product,
  );

  if (productId == 'lynrafamily_lifetime') {
    await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: purchaseParam,
    );
    return;
  }

  if (productId == 'extra_requester_1' ||
      productId == 'extra_member_1') {
    await InAppPurchase.instance.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: true,
    );
    return;
  }

  Log.d("BEACON IAP => unknown productId=$productId");
}
	
Future<void> _initTrial() async {
	await SubscriptionService.markExpiredIfNeeded();
  final info = await SubscriptionService.load();

  if (!mounted) return;

  setState(() {
    _isPremium = info.isPremium; Log.d("_initTrial _isPremium $_isPremium");
    _trialActive = info.trialActive;Log.d("_initTrial _trialActive $_trialActive");
    _trialDaysLeft = info.trialDaysLeft;Log.d("_initTrial _trialDaysLeft $_trialDaysLeft");
  });
}

Future<void> _showPurchaseMenu() async {
final l10n = AppLocalizations.of(context)!;
  await showDialog(
    context: context,
    builder: (dialogContext) {
      Widget purchaseItem({
        required IconData icon,
        required String title,
        required String subtitle,
        required String productId,
      }) {
        return AppCard(
          padding: const EdgeInsets.all(14),
          onTap: () {
            Navigator.pop(dialogContext);
            _buy(productId);
          },
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.subtitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: AppFonts.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        );
      }

      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(
          l10n.purchase,
          style: AppFonts.title.copyWith(
            color: AppColors.primary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isPremium)
                purchaseItem(
                  icon: Icons.lock_open_rounded,
                  title: l10n.lifeTimeAccess,
                  subtitle: 'Unlock LynraFamily for this group.',
                  productId: 'lynrafamily_lifetime',
                ),

              if (_isPremium) ...[
                purchaseItem(
                  icon: Icons.person_add_alt_1_rounded,
                  title: l10n.addAdmin,
                  subtitle: l10n.allowOneMoreAdmin,
                  productId: 'extra_requester_1',
                ),

                const SizedBox(height: 12),

                purchaseItem(
                  icon: Icons.group_add_rounded,
                  title: 'Add member',
                  subtitle: l10n.allowOneMoreMember,
                  productId: 'extra_member_1',
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildRejectedHome({
  required String requesterName,
}) {
  final l10n = AppLocalizations.of(context)!;

  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
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

            const SizedBox(height: 8),

            Text(
              l10n.rejected,
              textAlign: TextAlign.center,
              style: AppFonts.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await GroupService.clearLocalGroup();

                  if (!mounted) return;

                  setState(() {
                    _homeDataFuture = HomeDataService.loadHomeData();
                  });
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
	

Widget _buildGroupHome({
	required String requesterName,
  required Map<String, dynamic> data,
  required AppLocalizations l10n,
  required String langCode,
}) {
  final requesterId = data['requesterId'] ?? '';
	
	return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('requesters')
				.doc(requesterId)
        .snapshots(),
    builder: (context, requesterSnapshot) {
      										final requesterData =
												requesterSnapshot.data?.data() ?? {};

										final pairedLocators =
												Map<String, dynamic>.from(
													requesterData['pairedLocators'] ?? {},
												);
										
										return Padding(
											padding: const EdgeInsets.all(10),
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
													children: [						
																	Column(
																		children: [
																			SizedBox(
																				width: double.infinity,
																				child: Stack(
																					alignment: Alignment.center,
																					children: [
																						RichText(
																							text: TextSpan(
																								style: AppFonts.title.copyWith(
																									fontSize: 24,
																									color: AppColors.primary,
																								),
																								children: [
																									TextSpan(text: l10n.title),
																								],
																							),
																						),
																						Positioned(
																							right: 40,
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

																			AnimatedCrossFade(
																				duration: const Duration(milliseconds: 250),
																				crossFadeState: _showGuide
																						? CrossFadeState.showFirst
																						: CrossFadeState.showSecond,
																				firstChild: const GuidePanel(),
																				secondChild: const SizedBox.shrink(),
																			),
																			
																			const SizedBox(height: 6),

Row(
  children: [
    Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final changed =
              await RequesterNameEditor.edit(context);

          if (changed) {
            setState(() {
              _homeDataFuture =
                  HomeDataService.loadHomeData();
            });
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 6,
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  requesterName,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.title.copyWith(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.edit_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    ),

    TextButton.icon(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LanguageSelectPage(),
          ),
        );

        if (!context.mounted) return;

        setState(() {});
      },
      icon: Icon(
        Icons.language_rounded,
        size: 18,
        color: AppColors.accent,
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            langCode,
            style: AppFonts.caption.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(
            Icons.arrow_drop_down,
            size: 18,
            color: AppColors.accent,
          ),
        ],
      ),
    ),
  ],
),

const SizedBox(height: 12),								
																			
																		],
																	),									
																			
																	const SizedBox(height: 4),
																	AppCard(
																				onTap: () async {
																				await AnalyticsService.logEvent(
																					'add_member_opened',
																				);
																					final changed = await Navigator.push<bool>(
																						context,
																						MaterialPageRoute(
																							builder: (_) => const AddLocatorPage(),
																						),
																					);

																					if (changed == true && context.mounted) {
																						await PendingPairingManager.start(
																							onApproved: () async {
																								await _loadLocators();

																								if (!mounted) return;

																								AppBanner.success(
																									context,
																									AppLocalizations.of(context)!.memberpaired,
																								);
																							},
																							onRejected: () async {
																								if (!mounted) return;

																								AppBanner.error(
																									context,
																									AppLocalizations.of(context)!.pairingRejected,
																								);
																							},
																						);

																						if (!context.mounted) return;

																						AppBanner.info(
																							context,
																							AppLocalizations.of(context)!.waitingForLocator,
																						);
																					}
																				},
																				
																				child: SizedBox(
																					height: 44,
																					child: Row(
																						children: [
																							Icon(
																								Icons.location_searching_rounded,
																								color: AppColors.primary,
																								size: 26,
																							),
																							const SizedBox(width: 8),
																							Text(
																							pairedLocators.length == 1
																									? l10n.pairedMember
																									: '${l10n.pairedMembers} (${pairedLocators.length})',
																								style: AppFonts.subtitle.copyWith(
																									color: AppColors.primary,
																									fontWeight: FontWeight.w600,
																									fontSize: 16,
																								),
																							),
																							const Spacer(),
																								Container(
																								padding: const EdgeInsets.symmetric(
																									horizontal: 12,
																									vertical: 2,
																								),
																								decoration: BoxDecoration(
																									border: Border.all(
																										color: AppColors.textSecondary,
																										width: 1,
																									),
																									borderRadius: BorderRadius.circular(8),
																								),
																								child: Row(
																									mainAxisSize: MainAxisSize.min,
																									children: [																
																										RichText(
																											text: TextSpan(
																												children: [
																													TextSpan(
																														text: l10n.addMember,
																														style: AppFonts.subtitle.copyWith(
																															color: AppColors.primary,
																															fontWeight: FontWeight.w600,
																															fontSize: 14,
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
																				),																			
																			),
																	const SizedBox(height: 4),

																	Expanded(
																		child: !_locatorsLoaded
																				? const Center(
																						child: CircularProgressIndicator(),
																					)
																				: _locators.isEmpty
																				? Center(
																						child: Padding(
																							padding: const EdgeInsets.symmetric(horizontal: 24),
																							child: AppCard(
																								child: Column(
																									mainAxisSize: MainAxisSize.min,
																									crossAxisAlignment: CrossAxisAlignment.start,
																									children: [
																										Row(
																											children: [
																												Icon(
																													Icons.devices_rounded,
																													size: 28,
																													color: AppColors.primary,
																												),
																												const SizedBox(width: 10),
																												Expanded(
																													child: Text(
																														l10n.howToAddMember,
																														style: AppFonts.subtitle.copyWith(
																															color: AppColors.primary,
																														),
																													),
																												),
																											],
																										),

																										const SizedBox(height: 16),

																										_MemberSetupStep(
																											number: '1',
																											text: l10n.memberSetupStepOne,
																										),

																										const SizedBox(height: 12),

																										_MemberSetupStep(
																											number: '2',
																											text: l10n.memberSetupStepTwo,
																										),

																										const SizedBox(height: 12),

																										_MemberSetupStep(
																											number: '3',
																											text: l10n.memberSetupStepThree,
																										),

																										const SizedBox(height: 14),

																										Text(
																											l10n.memberAppFreeHint,
																											style: AppFonts.caption.copyWith(
																												color: AppColors.textSecondary,
																												height: 1.4,
																											),
																										),
																									],
																								),
																							),
																						),
																					)
																				: ListView.separated(
																						itemCount: _locators.length,//itemCount: _locators.isEmpty ? 0 : 4,
																						separatorBuilder: (_, __) =>
																								const SizedBox(height: 2),
																						itemBuilder: (context, index) {
																							final locator = _locators[index];//final locator = _locators[0];
																							final locatorId = locator['locatorId'] ?? '-';															
																							final locatorName = locator['locatorName'] ?? 'Member';
																							final locatorCode = locator['locatorCode'] ?? '------';
																							final status = locator['status'] ?? 'offline';
																							final battery = locator['battery'] ?? 0;
																							final gpsEnabled = locator['gpsEnabled'] == true;																	
																							final locatorNames = <String, String>{
																								for (final item in _locators)
																									(item['locatorId'] ?? '') as String:
																											(item['locatorName'] ?? 'Member') as String,
																							};																							
																							
																							final stationarySince =
																							locator['stationarySince'] is int
																								? locator['stationarySince'] as int
																								: null;
																							final offlineSince = locator['offlineSince'] is int
																								? locator['offlineSince'] as int
																								: null;
																							final l10n = AppLocalizations.of(context)!;
																							final lastSeenText = TimeHelper.formatLastSeen(
																								locator['lastSeen'],
																								l10n,
																							);					
																							final geoInside = locator['geoInside'] == true;
																							final geoPlaceName =
																									(locator['geoPlaceName'] ?? '').toString().trim();
																							final geoPlaceDistanceMeters =
																									locator['geoPlaceDistanceMeters'] as int?;
																							final placeName =
																									geoInside && geoPlaceName.isNotEmpty
																											? geoPlaceDistanceMeters != null && geoPlaceDistanceMeters >= 20
																													? '${geoPlaceName.toUpperCase()} • ${geoPlaceDistanceMeters} m'
																													: geoPlaceName.toUpperCase()
																											: '';																							
																							final distanceMeters = LocationHelper.distanceMeters(fromLat: _myLat,fromLng: _myLng,toLat: locator['lat']?.toDouble(),toLng: locator['lng']?.toDouble(),);
																							final distanceText = distanceMeters == null ? '-' : '${distanceMeters.round()} m';
																							final lat = locator['lat']?.toDouble();
																							final lng = locator['lng']?.toDouble();
																							return LocatorStatusCard(
																								locatorId: locatorId,
																								locatorName: locatorName,
																								locatorCode: locatorCode,
																								status: status,
																								battery: battery,
																								gpsEnabled: gpsEnabled,
																								addressText: locator['address'] ?? l10n.addressNotAvailable,
																								geoInside: geoInside,
																								placeName: placeName,
																								lastSeenText: lastSeenText,
																								distanceText: distanceText,
																								onOpenMaps: () async {																									
																									if (lat == null || lng == null) return;
																									await MapHelper.openInMaps(
																										lat: lat,
																										lng: lng,
																									);
																								},
																								onLiveTrack: () {																									
																								 Navigator.push(
																										context,
																										MaterialPageRoute(
																											builder: (_) => LiveTrackingMapPage(
																												locatorId: locatorId,
																												locatorName: locatorName,
																												latitude: lat,
																												longitude: lng,
																												address: locator['address'] ?? l10n.addressNotAvailable,
																												locatorNames: locatorNames,
																											),
																										),
																									);
																								},
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
																											),
																										),
																									);
																								},
																								onRemove: () async {
																									final result = await AppConfirmDialog.show(
																										context: context,
																										title: l10n.removeMember,
																										message: l10n.thismember,
																										confirmText: l10n.remove,
																										cancelText: l10n.cancel,
																										confirmColor: AppColors.danger,
																									);
																									if (result != true) return;
																									
																									await ActiveWatcherService.removeWatcher(
																										locatorId: locatorId,
																									);

																									await GroupService.removePairedLocator(
																										locatorId: locatorId,
																									);

																									if (!context.mounted) return;
																									
																									await _loadLocators();
																									
																									if (!context.mounted) return;
																										AppBanner.success(
																											context,
																											l10n.memberremoved,
																										);
																									setState(() {});
																								},
																								stationarySince: stationarySince,
																								offlineSince: offlineSince,
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
  final langCode = Localizations.localeOf(context).languageCode.toUpperCase();

  return Scaffold(
    backgroundColor: AppColors.background,
    body: Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _homeDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
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

                final requesterName = data['requesterName'] ?? '-';             
								
								_hasGroup =
										data['hasGroup'] == true;					

								
								return _buildGroupHome(
									requesterName: requesterName,
									data: data,
									l10n: l10n,
									langCode: langCode,
								);
						
														},
													),
												),
											),
											
											Positioned(
												left: 8,
												right: 8,
												bottom: 8,
												child: Material(
													color: Colors.transparent,
															child: AppCard(
																	padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
																		child: Column(
																			crossAxisAlignment: CrossAxisAlignment.start,
																				children: [
																					Row(
																						children: [
																							if (_hasGroup) ...[
																								Expanded(
																								child: Text(
																									_isPremium
																											? l10n.premiumActive
																											: (_trialActive
																													? l10n.freeTrialDaysLeft(_trialDaysLeft)
																													: l10n.trialExpired),
																									style: AppFonts.caption.copyWith(
																										color: AppColors.textPrimary,
																										fontWeight: FontWeight.w600,
																									),
																								),
																								),
																							],
																							const SizedBox(width: 32),						
																							if (_appVersion.isNotEmpty)
																								Flexible(
																								flex: 0,
																								child: Text(
																									"${l10n.version} $_appVersion",
																									style: AppFonts.caption.copyWith(
																										color: AppColors.textPrimary,
																										fontWeight: FontWeight.w500,
																									),
																								),
																								),
																								const SizedBox(width: 8),
																									TextButton(
																										onPressed: _showPurchaseMenu,
																										style: TextButton.styleFrom(
																											padding: const EdgeInsets.symmetric(horizontal: 8),
																											minimumSize: const Size(0, 32),
																											tapTargetSize: MaterialTapTargetSize.shrinkWrap,
																										),
																										child: Text(
																											l10n.purchase,
																											style: AppFonts.button.copyWith(
																												color: AppColors.primary,
																												fontSize: 16,
																											),
																										),
																									),
																									
																								],
																							),
																						const SizedBox(height: 2),
																						Row(
																							children: [
																								InkWell(
																									onTap: openFeedbackMenu,
																									borderRadius: BorderRadius.circular(20),
																									child: Padding(
																										padding: const EdgeInsets.symmetric(
																											horizontal: 2,
																											vertical: 2,
																										),
																										child: Row(
																											children: [
																												Icon(
																													Icons.chat_bubble_outline_rounded,
																													size: 13,
																													color: AppColors.primary,
																												),
																												const SizedBox(width: 16),
																												Text(
																													l10n.feedback,
																													style: AppFonts.caption.copyWith(
																														color: AppColors.primary,
																													),
																												),
																											],
																										),
																									),
																								),
																								const SizedBox(width: 48),
																								InkWell(
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
																											horizontal: 4,
																											vertical: 2,
																										),
																										child: Row(
																											children: [
																												Icon(
																													Icons.apps_rounded,
																													size: 13,
																													color: AppColors.primary,
																												),
																												const SizedBox(width: 4),
																												Text(
																													l10n.otherApps,
																													style: AppFonts.caption.copyWith(
																														color: AppColors.primary,
																													),
																												),
																											],
																										),
																									),
																								),
																							],
																						),
																					],
																				),
																				
																		),
																		),
																	),								
																	if (_callMeData != null)
																	CallMeOverlay(
																		data: _callMeData!,
																		onDismiss: () async {

																			final callMeId =
																					_callMeData!['callMeId'];

																			final requesterId =
																					_callMeData!['targetRequesterId'];

																			await FirebaseFirestore.instance
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
																		? _pendingCallMeQueue.last
																		: null;
																			});
																		},
																	),	
																	if (_alertData != null)
																	AlertOverlay(
																		data: _alertData!,
																		onDismiss: () async {
																			final alertDocId =
																					_alertData!['alertDocId'];

																			final requesterId =
																					_alertData!['targetRequesterId'];

																			await FirebaseFirestore.instance
																					.collection('alerts')
																					.doc(requesterId)
																					.collection('items')
																					.doc(alertDocId)
																					.delete();

																			if (!mounted) return;

																			setState(() {
																				_pendingAlertQueue.removeWhere(
																					(x) => x['alertDocId'] == alertDocId,
																				);

																				_alertData = _pendingAlertQueue.isNotEmpty
																						? _pendingAlertQueue.last
																						: null;
																			});
																		},
																	),
																	if (_sosData != null)
																	SosOverlay(
																		data: _sosData!,
																		onDismiss: () async {
																			final sosId = _sosData!['sosId'];
																			final requesterId =
																					_sosData!['targetRequesterId'];

																			await FirebaseFirestore.instance
																					.collection('sos')
																					.doc(requesterId)
																					.collection('items')
																					.doc(sosId)
																					.delete();

																			if (!mounted) return;

																			setState(() {
																				_pendingSosQueue.removeWhere(
																					(x) => x['sosId'] == sosId,
																				);

																				_sosData = _pendingSosQueue.isNotEmpty
																						? _pendingSosQueue.last
																						: null;
																			});
																		},
																	),
																	if (!_hasFullAccess && _hasGroup)
																	SubscriptionExpiredOverlay(
																		isMaster: true,
																		onUpgrade: () {
																			_showPurchaseMenu();
																		},
																	),
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
										"https://play.google.com/store/apps/details?id=com.lynra.beacon.requester",
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
      'subject': 'LynraFamily Feedback',
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
						width: 1,
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
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _MemberSetupStep extends StatelessWidget {
  final String number;
  final String text;

  const _MemberSetupStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: AppFonts.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppFonts.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}


