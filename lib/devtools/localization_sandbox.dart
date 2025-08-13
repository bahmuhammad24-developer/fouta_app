import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

void main() => runApp(const LocalizationSandbox());

class LocalizationSandbox extends StatefulWidget {
  const LocalizationSandbox({super.key});

  @override
  State<LocalizationSandbox> createState() => _LocalizationSandboxState();
}

class _LocalizationSandboxState extends State<LocalizationSandbox> {
  Locale _locale = const Locale('en');

  void _updateLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate],
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).appName),
          ),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context).settings),
                Text(AppLocalizations.of(context).privacy),
                Text(AppLocalizations.of(context).save),
                Text(AppLocalizations.of(context).cancel),
                Text(AppLocalizations.of(context).post),
                Text(AppLocalizations.of(context).comment),
                Text(AppLocalizations.of(context).like),
                Text(AppLocalizations.of(context).share),
                Text(AppLocalizations.of(context).follow),
                Text(AppLocalizations.of(context).followers),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => _updateLocale(const Locale('en')),
                      child: const Text('EN'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _updateLocale(const Locale('fr')),
                      child: const Text('FR'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const sandboxRouteMap = {
  '/_dev/l10n': (_) => const LocalizationSandbox(),
};
