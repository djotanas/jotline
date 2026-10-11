import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

class JotlineApp extends StatelessWidget {
  const JotlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(),
    );
  }
}
