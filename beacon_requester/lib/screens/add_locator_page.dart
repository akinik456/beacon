import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../services/locator_pairing_service.dart';
import '../services/pairing_response_service.dart';
import '../services/group_service.dart';

class AddLocatorPage extends StatefulWidget {
  const AddLocatorPage({super.key});

  @override
  State<AddLocatorPage> createState() => _AddLocatorPageState();
}

class _AddLocatorPageState extends State<AddLocatorPage> {
  final codeCtrl = TextEditingController();

  bool get canSend => codeCtrl.text.trim().isNotEmpty;

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

    final code = result.trim();

    if (code.isNotEmpty) {
      codeCtrl.text = code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
			  centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Add Member',          
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect a Member',
										style: AppFonts.subtitle.copyWith(
										color: AppColors.primary,
										),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scan the member QR code or enter its short code manually.',
                    style: AppFonts.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            AppCard(
              child: _InputField(
                controller: codeCtrl,
                label: 'Member code',
                hint: 'Enter member short code',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z0-9]'),
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
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scan QR code', style: AppFonts.subtitle),
                        const SizedBox(height: 4),
                        Text(
                          'Read member code with camera',
                          style: AppFonts.caption,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
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
                onPressed: canSend
								? () async {
										final result =
    await LocatorPairingService
        .sendPairingRequest(
  locatorInput: codeCtrl.text,
);

if (result == null) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context)
      .showSnackBar(
    const SnackBar(
      content: Text(
        'Member not found',
      ),
    ),
  );

  return;
}

final locatorId =
    result['locatorId']!;

final requestId =
    result['requestId']!;

if (!context.mounted) return;

ScaffoldMessenger.of(context)
    .showSnackBar(
  const SnackBar(
    content: Text(
      'Waiting for locator approval...',
    ),
  ),
);

PairingResponseService
    .watchPairingResponse(
  locatorId: locatorId,
  requestId: requestId,
).listen((snapshot) async {

  final data = snapshot.data();

  if (data == null) return;

  final status =
      data['status'] ?? 'pending';

  if (!context.mounted) return;

  if (status == 'approved') {
  await GroupService.addPairedLocatorToRequester(
    locatorId: locatorId,
  );
	await GroupService.addPairedRequesterToLocator(
		locatorId: locatorId,
	);	
	await GroupService.ensureLocatorDefaultSettings(
		locatorId: locatorId,
	);

	await GroupService.ensureRequesterNotifySettings(
		locatorId: locatorId,
	);
  ScaffoldMessenger.of(context)
      .showSnackBar(
    const SnackBar(
      content: Text(
        'Member paired successfully',
      ),
    ),
  );
  await PairingResponseService
      .deletePairingRequest(
    locatorId: locatorId,
    requestId: requestId,
  );
  if (!context.mounted) return;
  Navigator.pop(context,true);
}else if (status == 'rejected_capacity') {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Pairing request rejected',
        ),
      ),
    );
  }
	else if (status.toString().startsWith('rejected')) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Pairing request rejected'),
    ),
  );
}
	
});
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
                  'Send Pairing Request',
                  style: AppFonts.button.copyWith(
                    color: canSend
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Scan Member QR',
          style: AppFonts.title.copyWith(
					color: AppColors.primary,
					),					
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
  final List<TextInputFormatter>? inputFormatters;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.caption.copyWith(
    color: AppColors.primary,
  ),),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          inputFormatters: inputFormatters,
          textCapitalization: TextCapitalization.characters,
          style: AppFonts.body.copyWith(
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
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
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}