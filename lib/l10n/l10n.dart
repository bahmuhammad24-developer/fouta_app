import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('fr')];

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'appName': 'Fouta',
      'settings': 'Settings',
      'privacy': 'Privacy',
      'save': 'Save',
      'cancel': 'Cancel',
      'post': 'Post',
      'comment': 'Comment',
      'like': 'Like',
      'share': 'Share',
      'follow': 'Follow',
      'followers': 'Followers',
    },
    'fr': {
      'appName': 'Fouta',
      'settings': 'Paramètres',
      'privacy': 'Confidentialité',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'post': 'Publier',
      'comment': 'Commenter',
      'like': "J'aime",
      'share': 'Partager',
      'follow': 'Suivre',
      'followers': 'Abonnés',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }

  String get appName => translate('appName');
  String get settings => translate('settings');
  String get privacy => translate('privacy');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get post => translate('post');
  String get comment => translate('comment');
  String get like => translate('like');
  String get share => translate('share');
  String get follow => translate('follow');
  String get followers => translate('followers');

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
