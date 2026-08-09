import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/identity_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../../screens/language_select_page.dart';
import '../../services/requester_name_editor.dart';
import 'app_banner.dart';
import 'dialogs/app_input_dialog.dart';

class GroupInfoPanel  extends StatelessWidget {
  const GroupInfoPanel ({
    super.key,
    required this.requesterName,
		required this.isMaster,
    required this.onRequesterNameChanged,
		required this.langCode,
		required this.onLanguageChanged,
		required this.onChanged,
  });

  final String requesterName;
	final bool isMaster;
  final VoidCallback onRequesterNameChanged;
	final String langCode;
	final VoidCallback onLanguageChanged;
	final VoidCallback? onChanged;
	
  Widget _buildCodeRow(BuildContext context) {
		return Row(
			children: [
				
				const Spacer(),

				TextButton.icon(
					onPressed: () async {
						await Navigator.push(
							context,
							MaterialPageRoute(
								builder: (_) => const LanguageSelectPage(),
							),
						);

						if (!context.mounted) return;

						onLanguageChanged();
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
			],
		);
	}

  @override
  Widget build(BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
						children: [
								Row(
								children: [
									Expanded(
										child: InkWell(
											borderRadius: BorderRadius.circular(12),
											onTap: () async {
												final changed =
														await RequesterNameEditor.edit(context);

												if (changed) {
													onRequesterNameChanged();
												}
											},
											child: Padding(
												padding: const EdgeInsets.symmetric(
													horizontal: 6,
													vertical: 6,
												),
												child: Row(
													mainAxisAlignment: MainAxisAlignment.end,
													children: [
														Flexible(
															child: Text(
																requesterName,
																overflow: TextOverflow.ellipsis,
																textAlign: TextAlign.right,
																style: AppFonts.title.copyWith(
																	fontSize: 20,
																	color: AppColors.textSecondary,
																),
															),
														),
														const SizedBox(width: 4),
														Icon(
															Icons.edit_rounded,
															size: 18,
															color: AppColors.textSecondary,
														),
													],
												),
											),
										),										
									),
								],
							),					
							const SizedBox(height: 8),
							_buildCodeRow(context),
							
							const SizedBox(height: 12),
						],
					),
        );
  }
}