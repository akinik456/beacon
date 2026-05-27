import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/home_data_service.dart';
import 'add_locator_page.dart';


class RequesterHomePage extends StatelessWidget {
  const RequesterHomePage({super.key});

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
    return Scaffold(
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
                    child: pairedLocators.isEmpty
                        ? Center(
                            child: Text(
                              'No paired locators yet.',
                              style: AppFonts.caption,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: pairedLocators.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final locatorId =
																	pairedLocators.keys.elementAt(index);

															final locatorData =
																	Map<String, dynamic>.from(
																pairedLocators[locatorId] ?? {},
															);

															final locatorName =
																	locatorData['name'] ?? 'Locator';

															final locatorCode =
																	locatorData['locatorCode'] ?? '------';

                              return AppCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.person_pin_circle_rounded,
                                        color: AppColors.primary,
                                      ),
                                    ),

                                    const SizedBox(width: 14),

                                    Expanded(
																			child: Column(
																				crossAxisAlignment:
																						CrossAxisAlignment.start,
																				children: [

																					Text(
																						'$locatorName - $locatorCode',
																						style: AppFonts.subtitle,
																					),

																					const SizedBox(height: 4),

																				],
																			),
																		),
                                  ],
                                ),
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
    );
  }
}