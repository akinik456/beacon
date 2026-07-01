import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

class AppInputDialog {
  AppInputDialog._();

  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String hintText,
    required String confirmText,
    required String cancelText,
    String? initialValue,
    int maxLength = 20,
    bool autofocus = true,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
    TextInputAction textInputAction =
        TextInputAction.done,
  }) {
    final controller = TextEditingController(
      text: initialValue,
    );

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            title,
            style: AppFonts.title,
          ),
          content: TextField(
            controller: controller,
            autofocus: autofocus,
            maxLength: maxLength,
            textCapitalization: textCapitalization,
            textInputAction: textInputAction,
            style: AppFonts.body.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppFonts.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            onSubmitted: (_) {
              Navigator.pop(
                dialogContext,
                controller.text.trim(),
              );
            },
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                cancelText,
                style: AppFonts.button,
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: Text(
                confirmText,
                style: AppFonts.button.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}