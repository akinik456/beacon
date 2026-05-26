import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/identity_service.dart';
import '../services/code_service.dart';

class LocatorHomePage extends StatelessWidget {
  const LocatorHomePage({super.key});

  Future<Map<String, String>> _loadLocatorCodeData() async {
    final locatorId =
      await IdentityService.getLocatorId() ?? '';

		final locatorCode =
      await IdentityService.getLocatorCode() ?? '------';

    return {
      'locatorId': locatorId,
      'locatorCode': locatorCode,
    };
  }

  void _showLocatorQrDialog({
    required BuildContext context,
    required String locatorId,
    required String locatorCode,
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
                'Locator QR Code',
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
                  data: locatorId,
                  size: 240,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Locator code',
                style: AppFonts.caption,
              ),
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

  Widget _locatorCodeHeader(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _loadLocatorCodeData(),
      builder: (context, snapshot) {
        final locatorId = snapshot.data?['locatorId'] ?? '';
        final locatorCode = snapshot.data?['locatorCode'] ?? '------';

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (locatorId.isEmpty) return;

            _showLocatorQrDialog(
              context: context,
              locatorId: locatorId,
              locatorCode: locatorCode,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Locator Code',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
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
                          style: AppFonts.title.copyWith(
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ready to pair',
                          style: AppFonts.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _locatorCodeHeader(context),
                ],
              ),

              const SizedBox(height: 24),

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
                        'Waiting for pairing request',
                        style: AppFonts.subtitle,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.gps_fixed_rounded,
                            color: AppColors.success,
                            size: 28,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'GPS ON',
                            style: AppFonts.subtitle,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.battery_5_bar_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '87%',
                            style: AppFonts.subtitle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.35),
                    ),
                    backgroundColor: AppColors.danger.withValues(alpha: 0.08),
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
        ),
      ),
    );
  }
}