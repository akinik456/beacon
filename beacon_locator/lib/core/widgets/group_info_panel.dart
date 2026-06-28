import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../screens/language_select_page.dart';
import '../../services/locator_name_editor.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class GroupInfoPanel extends StatelessWidget {
  const GroupInfoPanel({
    super.key,
    required this.groupName,
    required this.locatorName,
    required this.locatorCode,
    required this.langCode,
    required this.onLocatorNameChanged,
    required this.onShowLocatorQr,
    required this.onLanguageChanged,
  });

  final String groupName;
  final String locatorName;
  final String locatorCode;
  final String langCode;
  final VoidCallback onLocatorNameChanged;
  final VoidCallback onShowLocatorQr;
  final VoidCallback onLanguageChanged;

  Widget _buildCodeRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onShowLocatorQr,
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
              const Icon(
                Icons.zoom_in,
                size: 32,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.memberCode,
                style: AppFonts.button.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                locatorCode,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  groupName,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.title.copyWith(
                    fontSize: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        locatorName,
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
                            await LocatorNameEditor.edit(context);

                        if (changed) {
                          onLocatorNameChanged();
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
        ],
      ),
    );
  }
}