import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/home_data_service.dart';

class RequesterHomePage extends StatelessWidget {
  const RequesterHomePage({super.key});

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

            final groupName = data['groupName'] ?? '-';
            final requesterName = data['requesterName'] ?? '-';
            final pairedLocators =
                Map<String, dynamic>.from(data['pairedLocators'] ?? {});

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: AppFonts.title.copyWith(fontSize: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    requesterName,
                    style: AppFonts.caption,
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
                                      child: Text(
                                        locatorId,
                                        style: AppFonts.body,
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