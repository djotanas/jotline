import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jotline/core/database/integrity_check.dart';
import 'package:jotline/core/theme/jot_theme.dart';
import 'package:jotline/features/notebooks/presentation/notebooks_screen.dart';
import 'package:jotline/l10n/app_localizations.dart';

class JotlineApp extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<JotlineApp> createState() => _JotlineAppState();
}

class _JotlineAppState extends ConsumerState<JotlineApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        ref.read(integrityCheckProvider.future).then((check) => check.run()),
      );
    });
  }

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
