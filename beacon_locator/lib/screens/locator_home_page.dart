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
import '../services/presence_service.dart';
import '../services/pairing_request_service.dart';
import '../services/pairing_approval_service.dart';
import '../services/call_me_service.dart';
import '../services/alert_service.dart';
import '../services/alert_monitor_service.dart';


class LocatorHomePage extends StatefulWidget {
  const LocatorHomePage({super.key});

  @override
  State<LocatorHomePage> createState() => _LocatorHomePageState();
}

class _LocatorHomePageState extends State<LocatorHomePage>
    with WidgetsBindingObserver {
  bool hasAllPermissions = false;
  Timer? _presenceTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndWarn();
    });

    PresenceService.updateOnline();

    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      PresenceService.updateOnline();
    });
		
		AlertMonitorService.start();
		
		
		
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
		AlertMonitorService.stop();

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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Permissions required', style: AppFonts.title),
        content: Text(
          'Some permissions are missing. Please open the permissions page and allow the required permissions.',
          style: AppFonts.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
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
    final locatorName = await IdentityService.getLocatorName() ?? 'Locator';

    return {
      'locatorId': locatorId,
      'locatorCode': locatorCode,
      'locatorName': locatorName,
    };
  }

  Future<Map<String, String>?> _loadPairedRequesterData() async {
    final groupId = await IdentityService.getGroupId();

    final locatorId = await IdentityService.getLocatorId();

    if (groupId == null || locatorId == null) {
      return null;
    }

    final doc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(locatorId)
        .get();

    final data = doc.data();

    if (data == null) {
      return null;
    }

    final pairedRequesters = Map<String, dynamic>.from(
      data['pairedRequesters'] ?? {},
    );

    if (pairedRequesters.isEmpty) {
      return null;
    }

    final requesterId = pairedRequesters.keys.first;

    final requesterData = Map<String, dynamic>.from(
      pairedRequesters[requesterId] ?? {},
    );

    return {
			'requesterId': requesterId,

      'requesterName': requesterData['requesterName'] ?? 'Requester',

      'requesterCode': requesterData['requesterCode'] ?? '------',
    };
  }

  void _showLocatorQrDialog({
    required String locatorId,
    required String locatorCode,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Locator QR Code', style: AppFonts.title),
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
              Text('Locator code', style: AppFonts.caption),
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

  Widget _locatorCodeHeader(String locatorId, String locatorCode) {
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
              Text('Locator Code', style: AppFonts.caption),
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
          'Permissions',
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
    return FutureBuilder<Map<String, String>?>(
      future: _loadPairedRequesterData(),
      builder: (context, snapshot) {
        final data = snapshot.data;

        if (data == null) {
          return Column(
            children: [
              AppCard(
                child: Text('No paired requester', style: AppFonts.subtitle),
              ),
              const SizedBox(height: 12),
              _permissionsButton(),
            ],
          );
        }
				final requesterId = data['requesterId'] ?? '';
        final requesterName = data['requesterName'] ?? 'Requester';
        final requesterCode = data['requesterCode'] ?? '------';

        return AppCard(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								'Paired requester',
								style: AppFonts.caption,
							),

							const SizedBox(height: 6),

							Text(
								'$requesterName - $requesterCode',
								style: AppFonts.subtitle,
							),

							const SizedBox(height: 16),

							SizedBox(
								width: double.infinity,
								height: 48,
								child: ElevatedButton.icon(
									onPressed: () async {

  final groupId =
      await IdentityService.getGroupId();

  if (groupId == null) {
    return;
  }

  await CallMeService.createCallMe(
    groupId: groupId,
    targetRequesterId: requesterId,
  );

  if (!context.mounted) return;

  ScaffoldMessenger.of(context)
      .showSnackBar(
    const SnackBar(
      content: Text(
        'Call Me sent',
      ),
    ),
  );
},
									icon: const Icon(
										Icons.call_rounded,
										color: AppColors.background,
									),
									label: Text(
										'Call Me',
										style: AppFonts.button.copyWith(
											color: AppColors.background,
										),
									),
									style: ElevatedButton.styleFrom(
										backgroundColor: AppColors.primary,
										shape: RoundedRectangleBorder(
											borderRadius: BorderRadius.circular(16),
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
                  Text('Pairing request', style: AppFonts.caption),
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
                          onPressed: () {},
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
            final locatorName = snapshot.data?['locatorName'] ?? 'Locator';

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
                              'Locator',
                              style: AppFonts.title.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 6),
                            Text(locatorName, style: AppFonts.caption),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _locatorCodeHeader(locatorId, locatorCode),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildPairingArea(),
                  
                  const Spacer(),
									const SizedBox(height: 12),

									SizedBox(
										width: double.infinity,
										height: 54,
										child: OutlinedButton.icon(
											onPressed: () {
												// TODO
											},
											icon: const Icon(
												Icons.settings_rounded,
												color: AppColors.primary,
											),
											label: Text(
												'Open Settings',
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
									const SizedBox(height: 12),
                  _permissionsButton(),
                  const SizedBox(height: 12),
									SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.35),
                        ),
                        backgroundColor: AppColors.danger.withValues(
                          alpha: 0.08,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Stop Sharing',
                        style: AppFonts.button.copyWith(
                          color: AppColors.danger,
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
