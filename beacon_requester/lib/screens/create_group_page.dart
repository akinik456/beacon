import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/group_service.dart';
import 'requester_home_page.dart';
import '../services/identity_service.dart';
import '../services/requester_registry_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/log.dart';


class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final groupNameCtrl = TextEditingController();
  bool get canConfirm => groupNameCtrl.text.trim().isNotEmpty ;

  @override
  void initState() {
    super.initState();
    groupNameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    groupNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
			  centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: Text(
          l10n.createNewGroup,
          style: AppFonts.title.copyWith(
					color: AppColors.primary,
					),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppCard(
              child: Column(
                children: [
                  _InputField(
                    controller: groupNameCtrl,
                    label: l10n.groupName,
                    hint: l10n.familyHome,
										maxLength: 20,
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: canConfirm 
									? () async {
										
										final _requesterName = await IdentityService.getRequesterName();
										final _requesterCode = await IdentityService.getRequesterCode();
										Log.d("_CreateGroupPageState IdentityService.getRequesterName");

										
										final groupId  =await GroupService.createGroup(
											groupName: groupNameCtrl.text,
										);
										
										await GroupService.setLocalIsMaster(true);
									
										if (!context.mounted) return;

										if (groupId.isNotEmpty) {
											Navigator.pushReplacement(
												context,
												MaterialPageRoute(
													builder: (_) => RequesterHomePage(),
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
                  l10n.confirm,
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
	final int? maxLength;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
		this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
			maxLength: maxLength,
      style: AppFonts.body,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppFonts.caption,
        hintStyle: AppFonts.caption,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}