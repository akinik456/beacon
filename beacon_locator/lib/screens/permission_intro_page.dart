// https://youtube.com/shorts/uz_d2RcNNc0?feature=share

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../l10n/app_localizations.dart';

import '../services/identity_service.dart';
import '../services/locator_registry_service.dart';
import '../services/firebase_authentication_service.dart';
import 'locator_home_page.dart';
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
							padding: const EdgeInsets.all(24),
							child: Column(
								children: [
									Align(
										alignment: Alignment.centerRight,
										child: TextButton.icon(
											onPressed: () async {
												await Navigator.push(
													context,
													MaterialPageRoute(
														builder: (_) => const LanguageSelectPage(),
													),
												);
												if (!mounted) return;
												setState(() {});
											},
											icon: Icon(
												Icons.language_rounded,
												size: 18,
												color: AppColors.accent,
											),
											label: Row(
												mainAxisSize: MainAxisSize.min,
												children: [
													Text(
														langCode,
														style: AppFonts.caption.copyWith(
															color: AppColors.accent,
															fontWeight: FontWeight.w600,
														),
													),
													Icon(
														Icons.arrow_drop_down,
														size: 18,
														color: AppColors.accent,
													),
												],
											),
										),
									),

									const SizedBox(height: 4),

									Container(
										width: 80,
										height: 80,
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
										child: Icon(
											Icons.location_searching_rounded,
											color: AppColors.primary,
											size: 52,
										),
									),

									const SizedBox(height: 16),

									Text(
										l10n.locationPermissionTitle,
										style: AppFonts.title.copyWith(
											fontSize: 28,
										),
										textAlign: TextAlign.center,
									),

									const SizedBox(height: 18),

									Text(
										l10n.locationPermissionDescForLocator,
										style: AppFonts.body.copyWith(
											color: AppColors.textSecondary,
											height: 1.6,
											fontSize: 16,
										),
										textAlign: TextAlign.center,
									),

									const Spacer(),

									SizedBox(
										width: double.infinity,
										height: 58,
										child: ElevatedButton(
											onPressed: _isStarting
													? null
													: () async {
															setState(() {
																_isStarting = true;
															});

															try {
																await IdentityService.setLocatorName(
																	l10n.member,
																);

																await IdentityService.createLocatorId();
																await AuthService.ensureSignedIn();
																await LocatorRegistryService.ensureLocatorAuthUid();
																await LocatorRegistryService.registerLocator();

																if (!context.mounted) return;

																Navigator.pushReplacement(
																	context,
																	MaterialPageRoute(
																		builder: (_) =>
																				const LocatorHomePage(),
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
												backgroundColor: AppColors.primary,
												shape: RoundedRectangleBorder(
													borderRadius: BorderRadius.circular(18),
												),
											),
											child: Text(
												l10n.cntinue,
												style: AppFonts.button.copyWith(
													color: AppColors.background,
													fontSize: 18,
												),
											),
										),
									),

									const SizedBox(height: 12),
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