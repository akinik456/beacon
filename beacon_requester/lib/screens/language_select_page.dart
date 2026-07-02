import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_fonts.dart';
import '../core/widgets/app_card.dart';
import '../main.dart';
import '../l10n/app_localizations.dart';


class LanguageSelectPage extends StatefulWidget {
  const LanguageSelectPage({super.key});

  @override
  State<LanguageSelectPage> createState() =>
      _LanguageSelectPageState();
}

class _LanguageSelectPageState
    extends State<LanguageSelectPage> {
  String? _selectedCode;
	
	
  final List<Map<String, String>> _languages = const [
    {'code': 'en', 'name': 'English'},
    {'code': 'tr', 'name': 'Türkçe'},
    {'code': 'es', 'name': 'Español'},
		
    /*{'code': 'de', 'name': 'Deutsch'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'it', 'name': 'Italiano'},
    {'code': 'pt', 'name': 'Português'},*/
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  Future<void> _loadSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    final savedCode = prefs.getString('languageCode');

    final deviceCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;

    final supportedCodes =
        _languages.map((x) => x['code']).toSet();

    setState(() {
      _selectedCode = savedCode ??
          (supportedCodes.contains(deviceCode)
              ? deviceCode
              : 'en');
    });
  }

  Future<void> _saveLanguage(String code) async {
		await MyApp.of(context).setLocale(code);

		if (!mounted) return;

		Navigator.pop(context, true);
	}

  @override
  Widget build(BuildContext context) {
		final l10n = AppLocalizations.of(context)!;
    final selectedCode = _selectedCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
				centerTitle: true,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        title: Text(
						l10n.language,						
						style: AppFonts.subtitle.copyWith(
            color: AppColors.primary,
						fontSize: 22,
            ),
        ),
      ),
      body: SafeArea(
        child: selectedCode == null
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      const SizedBox(height: 16),

                      ..._languages.map((language) {
                        final code = language['code']!;
                        final name = language['name']!;
                        final isSelected = code == selectedCode;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          onTap: () {
                            setState(() {
                              _selectedCode = code;
                            });
                          },
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          title: Text(
                            '$name',
                            style: AppFonts.body.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        );
                      }),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            _saveLanguage(selectedCode);
                          },
													style: ElevatedButton.styleFrom(
														backgroundColor: AppColors.primary,
														shadowColor: AppColors.background,
														shape: RoundedRectangleBorder(
															borderRadius: BorderRadius.circular(18),
														),
													),
                          child: Text(
														l10n.sva,
														style: AppFonts.caption.copyWith(
															color: AppColors.background,
														),
													),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}