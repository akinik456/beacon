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
import '../services/locator_list_service.dart';
import '../services/group_service.dart';
import '../core/widgets/locator_status_card.dart';
import '../utils/time_helper.dart';
import '../utils/location_helper.dart';
import '../utils/map_helper.dart';
import '../services/group_service.dart';
import '../services/identity_service.dart';
import '../services/fcm_service.dart';
import 'locator_settings_page.dart';
import '../utils/address_helper.dart';

class RequesterHomePage extends StatefulWidget {
  const RequesterHomePage({super.key});

  @override
  State<RequesterHomePage> createState() =>
      _RequesterHomePageState();
}

class _RequesterHomePageState
    extends State<RequesterHomePage> {
		
	List<Map<String, dynamic>> _locators = [];
	final List<StreamSubscription> _subscriptions = [];
	Map<String, dynamic>? _callMeData;
	List<Map<String, dynamic>> _pendingCallMeQueue = [];
	Map<String, dynamic>? _alertData;
	
	String? _groupId;
	double? _myLat;
	double? _myLng;
	
		@override
	void initState() {
		super.initState();
		FCMService.initialize();

		_loadLocators();
	}
	
	Future<void> _loadLocators() async {
	_groupId = await GroupService.getLocalGroupId();
	
	final position =
    await LocationHelper.getCurrentPosition();

		_myLat = position?.latitude;
		_myLng = position?.longitude;

		print(
			"BEACON REQUESTER POS => "
			"$_myLat, $_myLng",
		);

		if (_groupId == null) return;
				final locators =
						await LocatorListService.loadLocators();

				setState(() {
					_locators = locators;
				});
				for (final locator in locators) {
			_listenLocatorPresence(
				locator['locatorId'],
			);
		}
	_listenCallMe();
	_listenAlerts();
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
                'Group QR Code',
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
                'Group code',
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
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
  children: [
    Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: HomeDataService.loadHomeData(),
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

            final groupId = data['groupId'] ?? '';
            final groupName = data['groupName'] ?? '-';
            final requesterName = data['requesterName'] ?? '-';
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

    const SizedBox(width: 16),

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
                    'Group Code',
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

SizedBox(
  width: double.infinity,
  height: 54,
  child: OutlinedButton.icon(
    onPressed: () async {

  final changed =
      await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) =>
          const AddLocatorPage(),
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
    icon: const Icon(
      Icons.add_rounded,
      color: AppColors.primary,
    ),
    label: Text(
      'Add Locator',
      style: AppFonts.button.copyWith(
        color: AppColors.primary,
      ),
    ),
    style: OutlinedButton.styleFrom(
      side: BorderSide(
        color: AppColors.primary.withValues(alpha: 0.25),
      ),
      backgroundColor:
          AppColors.primary.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  ),
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
                            '${pairedLocators.length} paired locator',
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
                              'No paired locators yet.',
                              style: AppFonts.caption,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: _locators.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final locator = _locators[index];
															final locatorId =
																locator['locatorId'] ?? '-';
															
															final locatorName =
																	locator['name'] ?? 'Locator';

															final locatorCode =
																	locator['locatorCode'] ?? '------';

															final status =
																	locator['status'] ?? 'offline';

															final battery =
																	locator['battery'] ?? 0;

															final gpsEnabled =
																	locator['gpsEnabled'] == true;
																	
															final lastSeenText =
																	TimeHelper.formatLastSeen(
																locator['lastSeen'],
															);
															
															final distanceMeters =
																	LocationHelper.distanceMeters(
																fromLat: _myLat,
																fromLng: _myLng,
																toLat: locator['lat']?.toDouble(),
																toLng: locator['lng']?.toDouble(),
															);
															final distanceText =
																	distanceMeters == null
																			? '-'
																			: '${distanceMeters.round()} m';
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
																onLongPress: () {
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
																addressText: locator['address'] ?? 'Address not available',
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
  _CallMeOverlay(
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
  _AlertOverlay(
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

class _CallMeOverlay extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const _CallMeOverlay({
    required this.data,
    required this.onDismiss,
  });

  @override
Widget build(BuildContext context) {
  final locatorName = data['locatorName'] ?? 'Locator';
  final locatorCode = data['locatorCode'] ?? '';
	
	final createdAt =
    data['createdAt'] as Timestamp?;

final timeText =
    TimeHelper.formatLastSeen(
      createdAt?.millisecondsSinceEpoch,
    );

  return Positioned.fill(
    child: Material(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.phone_in_talk_rounded,
                color: AppColors.primary,
                size: 54,
              ),

              const SizedBox(height: 18),

              Text(
                '$locatorName - $locatorCode',
                style: AppFonts.title,
                textAlign: TextAlign.center,
              ),
const SizedBox(height: 6),

Text(
  timeText,
  style: AppFonts.caption.copyWith(
    color: AppColors.textSecondary,
  ),
),
              const SizedBox(height: 8),

              Text(
                'wants you to call.',
                style: AppFonts.body,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDismiss,
                  child: const Text('Dismiss'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _AlertOverlay extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const _AlertOverlay({
    required this.data,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final locatorName =
        data['locatorName'] ?? 'Locator';

    final locatorCode =
        data['locatorCode'] ?? '';

    final alertType =
        data['type'] ?? 'alert';

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(
          alpha: 0.65,
        ),
        child: Center(
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 54,
                ),

                const SizedBox(height: 18),

                Text(
                  alertType.toString().toUpperCase(),
                  style: AppFonts.title,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  '$locatorName - $locatorCode',
                  style: AppFonts.subtitle,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onDismiss,
                    child: const Text(
                      'Dismiss',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}