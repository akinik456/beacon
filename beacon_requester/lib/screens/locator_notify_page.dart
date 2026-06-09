import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/group_service.dart';
import '../services/identity_service.dart';

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

  bool gpsOffEnabledByMaster = false;
  bool batteryLowEnabledByMaster = false;
  bool geofenceEnabledByMaster = false;

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

      callMe = notify['callMe'] ?? true;
      gpsOff = gpsOffEnabledByMaster && (notify['gpsOff'] ?? false);
      batteryLow =
          batteryLowEnabledByMaster && (notify['batteryLow'] ?? false);
      geofence = geofenceEnabledByMaster && (notify['geofence'] ?? false);

      loading = false;
    });
  }

  Future<void> _saveSettings() async {
    final groupId = await GroupService.getLocalGroupId();
    final requesterId = await IdentityService.getRequesterId();

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
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
				centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Member Notifications',
          style: AppFonts.title.copyWith(
					color: AppColors.primary,
					),
        ),
      ),
      body: loading
          ? const Center(
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
                  'Choose which notifications you want to receive from this member.',
                  style: AppFonts.caption,
                ),

                const SizedBox(height: 26),

                _NotifySwitchCard(
                  title: 'Call Me',
                  subtitle: 'Receive wake-up requests from this member',
                  value: callMe,
                  enabled: true,
                  onChanged: (v) => setState(() => callMe = v),
                ),

                const SizedBox(height: 12),

                _NotifySwitchCard(
                  title: 'GPS Off Alert',
                  subtitle: gpsOffEnabledByMaster
                      ? 'Receive GPS off alerts'
                      : 'Disabled by master ',
                  value: gpsOff,
                  enabled: gpsOffEnabledByMaster,
                  onChanged: (v) => setState(() => gpsOff = v),
                ),

                const SizedBox(height: 12),

                _NotifySwitchCard(
                  title: 'Battery Low Alert',
                  subtitle: batteryLowEnabledByMaster
                      ? 'Receive low battery alerts'
                      : 'Disabled by master ',
                  value: batteryLow,
                  enabled: batteryLowEnabledByMaster,
                  onChanged: (v) => setState(() => batteryLow = v),
                ),

                const SizedBox(height: 12),

                _NotifySwitchCard(
                  title: 'Geofence Alert',
                  subtitle: geofenceEnabledByMaster
                      ? 'Receive place enter / leave alerts'
                      : 'Disabled by master ',
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
                      'Save Settings',
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