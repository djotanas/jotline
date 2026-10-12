import 'package:flutter/material.dart';
import 'package:jotline/core/theme/jot_theme.dart';
import 'package:jotline/features/notebooks/presentation/notebooks_screen.dart';
import 'package:jotline/l10n/app_localizations.dart';

class JotlineApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildJotTheme(),
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const NotebooksScreen(),
    );
  }
}
