import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../l10n/app_localizations.dart';
import 'join_group_page.dart';
import '../services/identity_service.dart';
import '../services/requester_registry_service.dart';
import '../services/firebase_authentication_service.dart';

import 'requester_home_page.dart';
import 'language_select_page.dart';

class PermissionIntroPage extends StatefulWidget {
  const PermissionIntroPage({super.key});

  @override
  State<PermissionIntroPage> createState() =>
      _PermissionIntroPageState();
}

class _PermissionIntroPageState
    extends State<PermissionIntroPage> {
		bool _isStarting = false;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
final langCode =
    Localizations.localeOf(context).languageCode.toUpperCase();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
					children: [
						Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
											Align(
												alignment: Alignment.centerRight,
												child: TextButton.icon(
													onPressed: () async {
														await Navigator.push(
															context,
															MaterialPageRoute(
																builder: (_) =>
																		const LanguageSelectPage(),
															),
														);

														if (!mounted) return;
														setState(() {});
													},
													icon: Icon(
														Icons.language_rounded,
														size: 18,
														color: AppColors.primary,
													),
													label: Text(
										langCode,
										style: AppFonts.caption.copyWith(
											color: AppColors.accent,
											fontWeight: FontWeight.w600,
										),
									),
								),
							),
              const Spacer(),

              // ================= ICON =================
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.30),
                      AppColors.primary.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Icon(
                  Icons.location_searching_rounded,
                  size: 54,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 12),

              // ================= TITLE =================
              Text(
                l10n.permissionIntroTitle,
                style: AppFonts.title.copyWith(
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4),

              // ================= SUBTITLE =================
              Text(
                l10n.permissionIntroSubtitle,
                style: AppFonts.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // ================= LOCATION CARD =================
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.locationPermissionTitle,
                            style: AppFonts.subtitle,
                          ),

                          const SizedBox(height: 6),

                          Text(
                            l10n.locationPermissionDescription,
                            style: AppFonts.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ================= CAMERA CARD =================
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.cameraPermissionTitle,
                            style: AppFonts.subtitle,
                          ),

                          const SizedBox(height: 6),

                          Text(
                            l10n.cameraPermissionDesc,
                            style: AppFonts.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
							
							const Spacer(),

              // ================= CREATE BUTTON =================
              SizedBox(
                width: double.infinity,
                height: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.accent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isStarting
										? null
										:() async {
											setState(() {
												_isStarting = true;
											});
											try {
											await IdentityService.setRequesterName(l10n.yourname);
											await IdentityService.createRequesterId();
											final authUid = await AuthService.ensureSignedIn();
											await RequesterRegistryService.ensureRequesterAuthUid();

											await RequesterRegistryService.registerRequester();

											if (!context.mounted) return;

												Navigator.pushReplacement(
													context,
													MaterialPageRoute(
														builder: (_) => const RequesterHomePage(),
													),
												);
											} finally {
												if (context.mounted) {
													setState(() {
														_isStarting = false;
													});
												}
											}
										},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      l10n.cntinue,
                      style: AppFonts.button.copyWith(
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 34),

            ],
          ),
        ),
				if (_isStarting)
							Positioned.fill(
								child: Container(
									color: Colors.black54,
									child: Center(
										child: CircularProgressIndicator(
											color: AppColors.primary,
										),
									),
								),
							),
				],
				),
      ),
    );
  }
}