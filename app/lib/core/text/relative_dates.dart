import 'package:jotline/l10n/app_localizations.dart';

DateTime _deviceLocal(DateTime utc) => utc.toLocal();

/// Formats stored UTC dates relative to the device's local today.
final class RelativeDates {
  const new(this._l10n, {required this._now, this._toLocal = _deviceLocal});

  final AppLocalizations _l10n;
  final DateTime _now;
  final DateTime Function(DateTime) _toLocal;

  /// "hoje", "ontem", a weekday, "d MMM" or "d MMM yyyy" (DATE-01).
  String day(DateTime utc) => _format(_toLocal(utc)).text;

  /// Prefixes [verb]; "hoje" and "ontem" follow it directly, other forms take
  /// "em" (DATE-02).
  String withVerb(String verb, DateTime utc) {
    final formatted = _format(_toLocal(utc));
    final text = formatted.needsPreposition
        ? _l10n.onDate(formatted.text)
        : formatted.text;
    return '$verb $text';
  }

  /// Like [withVerb], followed by the local time as "HH:mm".
  String withTime(String verb, DateTime utc) {
    final local = _toLocal(utc);
    final hours = local.hour.toString().padLeft(2, '0');
    final minutes = local.minute.toString().padLeft(2, '0');
    return '${withVerb(verb, utc)}, $hours:$minutes';
  }

  ({String text, bool needsPreposition}) _format(DateTime local) {
    final today = _toLocal(_now);
    final days = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(local.year, local.month, local.day)).inDays;
    if (days <= 0) return (text: _l10n.today, needsPreposition: false);
    if (days == 1) return (text: _l10n.yesterday, needsPreposition: false);
    if (days < 7) {
      return (
        text: _l10n.weekdayShort(local.weekday.toString()),
        needsPreposition: true,
      );
    }
    final month = _l10n.monthShort(local.month.toString());
    final text = local.year == today.year
        ? '${local.day} $month'
        : '${local.day} $month ${local.year}';
    return (text: text, needsPreposition: true);
  }
}
