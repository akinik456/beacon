import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/identity_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../../screens/language_select_page.dart';
import 'requester_list_card.dart';
import '../../services/requester_name_editor.dart';
import 'app_banner.dart';
import 'dialogs/app_input_dialog.dart';


class GroupInfoPanel  extends StatelessWidget {
  const GroupInfoPanel ({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.requesterName,
    required this.onRequesterNameChanged,
		required this.groupCode,
		required this.langCode,
		required this.onShowGroupQr,
		required this.onLanguageChanged,
  });

  final String groupId;
  final String groupName;
  final String requesterName;
  final VoidCallback onRequesterNameChanged;
	final String groupCode;
	final String langCode;
	final VoidCallback onShowGroupQr;
	final VoidCallback onLanguageChanged;

  Future<void> _editGroupName({
    required BuildContext context,
    required String currentGroupName,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    final controller = TextEditingController(
      text: currentGroupName,
    );

    final newName = await AppInputDialog.show(
			context: context,
			title: l10n.groupName,
			hintText: l10n.groupName,
			confirmText: l10n.sva,
			cancelText: l10n.cancel,
			maxLength: 20,
			textCapitalization: TextCapitalization.words,
		);


    if (newName == null || newName.isEmpty) return;
    if (newName == currentGroupName) return;
    if (!context.mounted) return;

    await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .update({
      'groupName': newName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
		AppBanner.success(
			context,
			l10n.saved,
		);
  }

  Widget _buildCodeRow(BuildContext context) {
		return Row(
			children: [
				const SizedBox(width: 8),

				InkWell(
					borderRadius: BorderRadius.circular(16),
					onTap: onShowGroupQr,
					child: Row(
						children: [
							Stack(
								alignment: Alignment.bottomRight,
								children: const [
									Icon(
										Icons.qr_code_scanner_rounded,
										color: AppColors.accent,
										size: 24,
									),
								],
							),
							Icon(
								Icons.zoom_in,
								size: 32,
								color: AppColors.accent,
							),
							const SizedBox(width: 6),
							Text(
								AppLocalizations.of(context)!.groupCode,
								style: AppFonts.button.copyWith(
									color: AppColors.textSecondary,
								),
							),
							const SizedBox(width: 6),
							Text(
								groupCode,
								style: AppFonts.subtitle.copyWith(
									color: AppColors.textSecondary,
									letterSpacing: 2,
								),
							),
						],
					),
				),

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
					icon: const Icon(
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
							const Icon(
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
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .snapshots(),
      builder: (context, snapshot) {
        final liveGroupName =
            snapshot.data?.data()?['groupName'] ?? groupName;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
						children: [
						Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        liveGroupName,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.title.copyWith(
                          fontSize: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        _editGroupName(
                          context: context,
                          currentGroupName: liveGroupName,
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
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
                    GestureDetector(
											onTap: () async {
												final changed =
														await RequesterNameEditor.edit(context);

												if (changed) {
													onRequesterNameChanged();
												}
											},
											child: const Icon(
												Icons.edit_rounded,
												size: 18,
												color: AppColors.textSecondary,
											),
										),
                  ],
                ),
              ),
            ],
          ),					
							const SizedBox(height: 8),
							_buildCodeRow(context),
							
							const SizedBox(height: 12),
							RequesterListCard(
								groupId: groupId,
							),
						],
					),
        );
      },
    );
  }
}