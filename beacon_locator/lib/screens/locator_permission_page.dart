import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/locator_permission_service.dart';
import '../l10n/app_localizations.dart';


class LocatorPermissionPage extends StatefulWidget {
		const LocatorPermissionPage({super.key});

		@override
		State<LocatorPermissionPage> createState() =>
				_LocatorPermissionPageState();
	}

	class _LocatorPermissionPageState
			extends State<LocatorPermissionPage> {

		bool locationGranted = false;
		bool activityGranted = false;
		bool batteryGranted = false;
		bool notificationGranted = false;

		bool autoStartGranted = false;
		bool memoryLockGranted = false;

		bool get allGranted =>
				locationGranted &&
				activityGranted &&
				batteryGranted &&
				notificationGranted &&
				autoStartGranted &&
				memoryLockGranted;
				
	@override
	void initState() {
		super.initState();
		_loadPermissionStates();
	}			

	Future<void> _loadPermissionStates() async {
		locationGranted =
				await LocatorPermissionService.isLocationAlwaysGranted();

		activityGranted =
				await LocatorPermissionService.isActivityRecognitionGranted();

		notificationGranted =
				await LocatorPermissionService.isNotificationGranted();

		batteryGranted =
				await LocatorPermissionService.isBatteryOptimizationDisabled();

		autoStartGranted =
    await LocatorPermissionService.isAutoStartMarkedOk();

		memoryLockGranted =
    await LocatorPermissionService.isMemoryLockMarkedOk();
		
		setState(() {});
	}	
	

  @override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                l10n.permissions,
                style: AppFonts.title.copyWith(
                  fontSize: 28,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              l10n.backgroundPermissions,
              style: AppFonts.title.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 16),

            _SectionTitle(l10n.systemPermissions),

            const SizedBox(height: 8),

            _PermissionItem(
              icon: Icons.location_on_rounded,
              title: l10n.locationAccess,
              subtitle: l10n.locationAlwaysDescription,
              granted: locationGranted,
              onTap: () async {
                await LocatorPermissionService.requestLocationAlways();

                final granted =
                    await LocatorPermissionService.isLocationAlwaysGranted();

                setState(() {
                  locationGranted = granted;
                });
              },
            ),

            const SizedBox(height: 10),

            _PermissionItem(
              icon: Icons.directions_run_rounded,
              title: l10n.physicalActivity,
              subtitle: l10n.requiredForMotion,
              granted: activityGranted,
              onTap: () async {
                await LocatorPermissionService.requestActivityRecognition();

                final granted =
                    await LocatorPermissionService
                        .isActivityRecognitionGranted();

                setState(() {
                  activityGranted = granted;
                });
              },
            ),

            const SizedBox(height: 10),

            _PermissionItem(
              icon: Icons.battery_charging_full_rounded,
              title: l10n.batteryOptimization,
              subtitle: l10n.batteryOptimizationDescription,
              granted: batteryGranted,
              onTap: () async {
                await LocatorPermissionService
                    .requestIgnoreBatteryOptimization();

                final granted =
                    await LocatorPermissionService
                        .isBatteryOptimizationDisabled();

                setState(() {
                  batteryGranted = granted;
                });
              },
            ),

            const SizedBox(height: 10),

            _PermissionItem(
              icon: Icons.notifications_active_rounded,
              title: l10n.notifications,
              subtitle: l10n.importantFor,
              granted: notificationGranted,
              onTap: () async {
                await LocatorPermissionService.requestNotification();

                final granted =
                    await LocatorPermissionService.isNotificationGranted();

                setState(() {
                  notificationGranted = granted;
                });
              },
            ),

            const SizedBox(height: 16),

            _SectionTitle(l10n.manufacturerSettings),

            const SizedBox(height: 8),

            _PermissionItem(
              icon: Icons.power_settings_new_rounded,
              title: l10n.autoStart,
              subtitle: l10n.enableAutostart,
              granted: autoStartGranted,
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) {
                    Future.delayed(const Duration(seconds: 10), () {
                      if (Navigator.canPop(dialogContext)) {
                        Navigator.pop(dialogContext);
                      }
                    });

                    return AlertDialog(
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.actionRequired,
                            style: AppFonts.title,
                          ),
                        ],
                      ),
                      content: Text(
                        l10n.backgroundAccessInstructions,
                        style: AppFonts.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  },
                );

                await Future.delayed(const Duration(seconds: 5));

                await LocatorPermissionService.setAutoStartMarkedOk(true);

                await LocatorPermissionService.openAutoStartSettings();

                setState(() {
                  autoStartGranted = true;
                });
              },
            ),

            const SizedBox(height: 10),

            _PermissionItem(
              icon: Icons.app_settings_alt_rounded,
              title: l10n.memoryLock,
              subtitle: l10n.preventSystemKillDescription,
              granted: memoryLockGranted,
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: Row(
                      children: [
                        Icon(
                          Icons.lock_clock_rounded,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.memoryProtection,
                          style: AppFonts.title,
                        ),
                      ],
                    ),
                    content: Text(
                      l10n.memoryProtectionInstructions,
                      style: AppFonts.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () async {
                          Navigator.pop(context);

                          await LocatorPermissionService
                              .setMemoryLockMarkedOk(true);

                          setState(() {
                            memoryLockGranted = true;
                          });
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.iUnderstand,
                          style: AppFonts.button.copyWith(
                            color: AppColors.background,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: allGranted
                    ? () {
                        Navigator.pop(context, allGranted);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      allGranted ? AppColors.primary : AppColors.surface,
                  disabledBackgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  allGranted
                      ? l10n.allPermissionsGranted
                      : l10n.grantRequiredPermissions,
                  style: AppFonts.button.copyWith(
                    color: allGranted
                        ? AppColors.background
                        : AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
	
	
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.caption.copyWith(
        color: AppColors.primary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1,
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onTap;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;
    final statusColor = granted ? AppColors.accent : AppColors.textSecondary;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: statusColor,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.subtitle.copyWith(fontSize: 14)),
                const SizedBox(height: 3),
                Text(subtitle, style: AppFonts.caption.copyWith(fontSize: 14)),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							Icon(
								granted
										? Icons.check_circle_rounded
										: Icons.radio_button_unchecked_rounded,
								color: granted
										? AppColors.accent
										: AppColors.textSecondary,
								size: 22,
							),

							const SizedBox(height: 4),

							Text(
								granted ? l10n.granted : l10n.missing,
								style: AppFonts.caption.copyWith(
									fontSize: 12,
									color: granted
											? AppColors.accent
											: AppColors.danger,
								),
							),
						],
					),
        ],
      ),
    );
  }
}