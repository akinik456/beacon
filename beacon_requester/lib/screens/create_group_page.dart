import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/group_service.dart';
import 'requester_home_page.dart';
import '../services/identity_service.dart';
import '../services/requester_registry_service.dart';


class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final groupNameCtrl = TextEditingController();
  //final requesterNameCtrl = TextEditingController();

  bool get canConfirm =>
      groupNameCtrl.text.trim().isNotEmpty ;
			//&& requesterNameCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    groupNameCtrl.addListener(() => setState(() {}));
    //requesterNameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    groupNameCtrl.dispose();
    //requesterNameCtrl.dispose();
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
          'Create group',
          style: AppFonts.title,
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
                    label: 'Group name',
                    hint: 'Family, Team, Home...',
                  ),
                  const SizedBox(height: 18),
                 /* _InputField(
                    controller: requesterNameCtrl,
                    label: 'Your Name',
										hint: 'Enter your name',
                  ),*/
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
										/*await IdentityService.setRequesterName(
											requesterNameCtrl.text,
										);									
									
										await IdentityService.createRequesterId();
										await RequesterRegistryService.registerRequester();*/
										final _requesterName = await IdentityService.getRequesterName();
										final _requesterCode = await IdentityService.getRequesterCode();
										
										
										final groupId  =await GroupService.createGroup(
											groupName: groupNameCtrl.text,
											requesterName: _requesterName!,
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