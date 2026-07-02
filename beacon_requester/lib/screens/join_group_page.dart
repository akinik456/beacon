import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import 'requester_home_page.dart';
import '../services/identity_service.dart';
import '../services/requester_registry_service.dart';
import '../services/group_service.dart';
import '../services/code_service.dart';
import '../l10n/app_localizations.dart';

class JoinGroupPage extends StatefulWidget {
  const JoinGroupPage({super.key});

  @override
  State<JoinGroupPage> createState() => _JoinGroupPageState();
}

class _JoinGroupPageState extends State<JoinGroupPage> {
  final codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    codeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanQrCode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const _QrScanPage(),
      ),
    );

    if (result == null) return;

		final raw =
				result.replaceFirst('code:', '');

		final code =
				CodeService.shortCodeFromId(raw);

		setState(() {
			codeCtrl.text = code;
		});
  }

	Future<void> _confirmJoin() async {
	final _requesterName = await IdentityService.getRequesterName();

		final groupId = await GroupService.joinGroup(
			groupCode: codeCtrl.text,
			requesterName: _requesterName!,
		);
		
		//await GroupService.setLocalIsMaster(false);

		if (!context.mounted) return;

		if (groupId != null && groupId.isNotEmpty) {

			Navigator.pushReplacement(
				context,
				MaterialPageRoute(
					builder: (_) => const RequesterHomePage(),
				),
			);
		}
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
          l10n.joinGroup,
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
                  const SizedBox(height: 18),
                  _InputField(
                    controller: codeCtrl,
                    label: l10n.groupCode,
                    hint: l10n.sixdigitcode,
                    keyboardType: TextInputType.text,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
												RegExp(r'[A-Za-z0-9]'),
											),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            AppCard(
              onTap: _scanQrCode,
              child: Row(
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
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.scanQRCode, style: AppFonts.subtitle),
                        const SizedBox(height: 4),
                        Text(
                          l10n.joinInstantlyWithCamera,
                          style: AppFonts.caption,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _confirmJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.surface.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  l10n.sendJoinRequest,
                  style: AppFonts.button.copyWith(
                    color: AppColors.background,
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

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  bool scanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (scanned) return;

    final value = capture.barcodes.first.rawValue;
    if (value == null || value.trim().isEmpty) return;

    scanned = true;
    Navigator.pop(context, value.trim());
  }

  @override
  Widget build(BuildContext context) {
	final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: Text(
          l10n.scanQRCode,
          style: AppFonts.title,
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.caption),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: AppFonts.body,
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            hintStyle: AppFonts.caption,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}