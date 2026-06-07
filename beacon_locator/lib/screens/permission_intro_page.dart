// https://youtube.com/shorts/uz_d2RcNNc0?feature=share

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import 'locator_name_page.dart';


class PermissionIntroPage extends StatelessWidget {
  const PermissionIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.25),
                      AppColors.primary.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.location_searching_rounded,
                  color: AppColors.primary,
                  size: 52,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'Location Permission',
                style: AppFonts.title.copyWith(
                  fontSize: 28,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 18),

              Text(
'LynraFamily Member needs location permission to respond to family location requests and share location updates.\n\n'
  'Background location access allows the app to provide location updates even when the app is not open.\n\n'
  'Your location is only shared with trusted members of your family group.',                style: AppFonts.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
										Navigator.push(
											context,
											MaterialPageRoute(
												builder: (_) => const LocatorNamePage(),
											),
										);
									},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppFonts.button.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}