/// Utility helpers for notification preferences.
///
/// Each notification item is expected to contain a `type` field. This helper
/// filters out items where the user has disabled that type in their
/// preferences.

Map<String, bool> defaultNotificationPrefs() => const {
  'follows': true,
  'comments': true,
  'likes': true,
  'reposts': true,
  'mentions': true,
  'messages': true,
};

/// Returns [items] filtered according to [prefs]. A notification is kept if the
/// corresponding type is not explicitly disabled.
List<Map<String, dynamic>> filterNotifications(
  List<Map<String, dynamic>> items,
  Map<String, bool> prefs,
) {
  return items.where((item) {
    final type = item['type'] as String?;
    if (type == null) return false;
    return prefs[type] != false;
  }).toList();
}
