import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import 'locator_home_page.dart';
import '../services/identity_service.dart';
import '../services/locator_registry_service.dart';

class LocatorNamePage extends StatefulWidget {
  const LocatorNamePage({super.key});

  @override
  State<LocatorNamePage> createState() => _LocatorNamePageState();
}

class _LocatorNamePageState extends State<LocatorNamePage> {
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

  void _confirm() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LocatorHomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
				centerTitle: true,
				backgroundColor: AppColors.background,
				surfaceTintColor: AppColors.primary,
				elevation: 0,
				title: Text(
					'LynraFamily Member',
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
              child: TextField(
                controller: nameCtrl,
                style: AppFonts.body,
                decoration: InputDecoration(
                  hintText: 'Enter member name',
                  hintStyle: AppFonts.caption,
                  border: InputBorder.none,
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: canConfirm
								? () async {
								
										await IdentityService.setLocatorName(
											nameCtrl.text,
										);
										
										final locatorId =
										await IdentityService.createLocatorId();

										await LocatorRegistryService.registerLocator();

										_confirm();
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