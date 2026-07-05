import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/group_service.dart';
import '../services/identity_service.dart';
import '../l10n/app_localizations.dart';
import '../core/widgets/app_banner.dart';

class LocatorNotifyPage extends StatefulWidget {
  final String locatorId;
  final String locatorName;
  final String locatorCode;

  const LocatorNotifyPage({
    super.key,
    required this.locatorId,
    required this.locatorName,
    required this.locatorCode,
  });

  @override
  State<LocatorNotifyPage> createState() => _LocatorNotifyPageState();
}

class _LocatorNotifyPageState extends State<LocatorNotifyPage> {
  bool callMe = true;
  bool gpsOff = false;
  bool batteryLow = false;
  bool geofence = false;
	bool movement = true;

  bool gpsOffEnabledByMaster = false;
  bool batteryLowEnabledByMaster = false;
  bool geofenceEnabledByMaster = false;
	bool movementEnabledByMaster = true;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final groupId = await GroupService.getLocalGroupId();
    final requesterId = await IdentityService.getRequesterId();

    if (groupId == null || requesterId == null) {
      if (!mounted) return;
      setState(() => loading = false);
      return;
    }

    final configDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(widget.locatorId)
        .collection('settings')
        .doc('config')
        .get();

    final config = configDoc.data() ?? {};

    final notifyDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(widget.locatorId)
        .collection('notifyRequesters')
        .doc(requesterId)
        .get();

    final notify = notifyDoc.data() ?? {};

    if (!mounted) return;

    setState(() {
      gpsOffEnabledByMaster = config['gpsOffAlert'] == true;
      batteryLowEnabledByMaster = config['batteryLowAlert'] == true;
      geofenceEnabledByMaster = config['geofenceAlert'] == true;
			movementEnabledByMaster = config['movementAlert'] == true;

      callMe = notify['callMe'] ?? true;
      gpsOff = gpsOffEnabledByMaster && (notify['gpsOff'] ?? false);
      batteryLow = batteryLowEnabledByMaster && (notify['batteryLow'] ?? false);
      geofence = geofenceEnabledByMaster && (notify['geofence'] ?? false);
			movement = movementEnabledByMaster && (notify['movement'] ?? false);
      loading = false;
    });
  }

  Future<void> _saveSettings() async {
    final groupId = await GroupService.getLocalGroupId();
    final requesterId = await IdentityService.getRequesterId();
		final l10n = AppLocalizations.of(context)!;
		
    if (groupId == null || requesterId == null) return;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(widget.locatorId)
        .collection('notifyRequesters')
        .doc(requesterId)
        .set({
      'callMe': callMe,
      'gpsOff': gpsOffEnabledByMaster ? gpsOff : false,
      'batteryLow': batteryLowEnabledByMaster ? batteryLow : false,
      'geofence': geofenceEnabledByMaster ? geofence : false,
      'movement': movementEnabledByMaster ? movement : false,
			'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;    
			AppBanner.success(
				context,
				l10n.notificationSettingsSaved,
			);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
				centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: Text(
          l10n.memberNotifications,
          style: AppFonts.title.copyWith(
					color: AppColors.primary,
					),
        ),
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: widget.locatorName,
                        style: AppFonts.title.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: '  •  ',
                        style: AppFonts.title.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: widget.locatorCode,
                        style: AppFonts.title.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  l10n.chooseWhichNotif,
                  style: AppFonts.caption,
                ),

                const SizedBox(height: 26),

                _NotifySwitchCard(
                  title: l10n.callme,
                  subtitle: l10n.receiveCallMe,
                  value: callMe,
                  enabled: true,
                  onChanged: (v) => setState(() => callMe = v),
                ),

                const SizedBox(height: 12),

                _NotifySwitchCard(
                  title: l10n.gpsOffAlert,
                  subtitle: gpsOffEnabledByMaster
                      ? l10n.receiveGPSalerts
                      : l10n.disabledByMaster,
                  value: gpsOff,
                  enabled: gpsOffEnabledByMaster,
                  onChanged: (v) => setState(() => gpsOff = v),
                ),

                const SizedBox(height: 12),

                _NotifySwitchCard(
                  title: l10n.batteryLowAlert,
                  subtitle: batteryLowEnabledByMaster
                      ? l10n.receivelowbattery
                      : l10n.disabledByMaster,
                  value: batteryLow,
                  enabled: batteryLowEnabledByMaster,
                  onChanged: (v) => setState(() => batteryLow = v),
                ),
								
								const SizedBox(height: 12),

								_NotifySwitchCard(
									title: l10n.movementAlert,
									subtitle: movementEnabledByMaster
											? l10n.receiveMovement
											: l10n.disabledByMaster,
									value: movement,
									enabled: movementEnabledByMaster,
									onChanged: (v) => setState(() => movement = v),
								),

                const SizedBox(height: 12),

                _NotifySwitchCard(
                  title: l10n.geofenceAlert,
                  subtitle: geofenceEnabledByMaster
                      ? 'Receive place enter / leave alerts'
                      : l10n.disabledByMaster,
                  value: geofence,
                  enabled: geofenceEnabledByMaster,
                  onChanged: (v) => setState(() => geofence = v),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      l10n.saveSettings,
                      style: AppFonts.button.copyWith(
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _NotifySwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _NotifySwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;
    final color = enabled ? AppColors.primary : AppColors.textSecondary;

    return AppCard(
      child: Row(
        children: [
          Icon(
            enabled
                ? Icons.notifications_active_rounded
                : Icons.notifications_off_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.subtitle),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppFonts.caption.copyWith(
                    color: enabled
                        ? AppColors.textSecondary
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}