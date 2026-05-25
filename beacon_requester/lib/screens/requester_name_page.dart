import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import 'join_group_page.dart';
import '../services/identity_service.dart';

class RequesterNamePage extends StatefulWidget {
  const RequesterNamePage({super.key});

  @override
  State<RequesterNamePage> createState() => _RequesterNamePageState();
}

class _RequesterNamePageState extends State<RequesterNamePage> {
  final nameCtrl = TextEditingController();

  bool get canConfirm => nameCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Join group',
          style: AppFonts.title,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppCard(
              child: _InputField(
                controller: nameCtrl,
                label: 'Your name',
                hint: 'Requester name',
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: canConfirm
								? () async {

										final requesterId =
												await IdentityService.getOrCreateRequesterId();

										if (!context.mounted) return;

										if (requesterId.isNotEmpty) {
											Navigator.pushReplacement(
												context,
												MaterialPageRoute(
													builder: (_) =>  JoinGroupPage(),
												),
											);
										}
									}
								: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.surface.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Confirm',
                  style: AppFonts.button.copyWith(
                    color: canConfirm
                        ? AppColors.background
                        : AppColors.textSecondary,
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppFonts.body,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppFonts.caption,
        hintStyle: AppFonts.caption,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}