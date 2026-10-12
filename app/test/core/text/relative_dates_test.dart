import 'package:flutter_test/flutter_test.dart';
import 'package:jotline/core/text/relative_dates.dart';
import 'package:jotline/l10n/app_localizations_pt.dart';

void main() {
  final l10n = AppLocalizationsPt();
  final now = DateTime.utc(2026, 10, 12, 15);

  RelativeDates dates({DateTime? at, DateTime Function(DateTime)? toLocal}) =>
      RelativeDates(l10n, now: at ?? now, toLocal: toLocal ?? (d) => d);

  test('DATE-01: the same day reads "hoje"', () {
    expect(dates().day(DateTime.utc(2026, 10, 12, 0, 1)), 'hoje');
  });

  test('DATE-01: the previous calendar day reads "ontem" even under 24h', () {
    expect(dates().day(DateTime.utc(2026, 10, 11, 23, 59)), 'ontem');
  });

  test('DATE-01: 2 days before reads the weekday', () {
    expect(dates().day(DateTime.utc(2026, 10, 10)), 'sáb');
  });

  test('DATE-01: 6 days before still reads the weekday', () {
    expect(dates().day(DateTime.utc(2026, 10, 6)), 'ter');
  });

  test('DATE-01: 7 days before reads "d MMM" with no zero padding', () {
    expect(dates().day(DateTime.utc(2026, 10, 5)), '5 out');
  });

  test('DATE-01: days 2 to 6 before read their weekday abbreviation', () {
    final words = [
      for (var d = 6; d <= 10; d++) dates().day(DateTime.utc(2026, 10, d)),
    ];
    expect(words, ['ter', 'qua', 'qui', 'sex', 'sáb']);
  });

  test('DATE-01: the Sunday abbreviation is "dom"', () {
    expect(dates().day(DateTime.utc(2026, 10, 11)), 'ontem');
    expect(
      dates(at: DateTime.utc(2026, 10, 13)).day(DateTime.utc(2026, 10, 11)),
      'dom',
    );
  });

  test('DATE-01: Dec 31 against Jan 1 of the next year reads "ontem"', () {
    final newYear = DateTime.utc(2027, 1, 1, 10);
    expect(dates(at: newYear).day(DateTime.utc(2026, 12, 31, 20)), 'ontem');
  });

  test('DATE-01: Dec 31 seen from Jan 3 of the next year reads the weekday '
      'without a year', () {
    final newYear = DateTime.utc(2027, 1, 3, 10);
    expect(dates(at: newYear).day(DateTime.utc(2026, 12, 31)), 'qui');
  });

  test('DATE-01: another year adds the year', () {
    expect(dates().day(DateTime.utc(2025, 10, 2)), '2 out 2025');
  });

  test('DATE-01: a date from the previous year 7 or more days away adds the '
      'year', () {
    final early = DateTime.utc(2027, 1, 10, 10);
    expect(dates(at: early).day(DateTime.utc(2026, 12, 31)), '31 dez 2026');
  });

  test('DATE-02: "hoje" and "ontem" follow the verb directly', () {
    expect(
      dates().withVerb('arquivado', DateTime.utc(2026, 10, 12)),
      'arquivado hoje',
    );
    expect(
      dates().withVerb('excluído', DateTime.utc(2026, 10, 11)),
      'excluído ontem',
    );
  });

  test('DATE-02: other forms take "em"', () {
    expect(
      dates().withVerb('criado', DateTime.utc(2026, 10, 2)),
      'criado em 2 out',
    );
    expect(
      dates().withVerb('criado', DateTime.utc(2026, 10, 10)),
      'criado em sáb',
    );
    expect(
      dates().withVerb('criado', DateTime.utc(2025, 10, 2)),
      'criado em 2 out 2025',
    );
  });

  test('DATE-02: withTime pads hours and minutes', () {
    expect(
      dates().withTime('Editada', DateTime.utc(2026, 10, 12, 9, 5)),
      'Editada hoje, 09:05',
    );
    expect(
      dates().withTime('Editada', DateTime.utc(2026, 10, 2, 14, 32)),
      'Editada em 2 out, 14:32',
    );
  });

  test('DATE-03: stored UTC dates are converted before formatting', () {
    DateTime minus3(DateTime d) => d.subtract(const Duration(hours: 3));
    final local = dates(at: DateTime.utc(2026, 10, 12, 15), toLocal: minus3);

    expect(local.day(DateTime.utc(2026, 10, 12, 2)), 'ontem');
    expect(
      local.withTime('Editada', DateTime.utc(2026, 10, 12, 12, 30)),
      'Editada hoje, 09:30',
    );
  });

  test('DATE-04: the page count reads 0, 1 and N', () {
    expect(l10n.pageCount(0), 'nenhuma página');
    expect(l10n.pageCount(1), '1 página');
    expect(l10n.pageCount(12), '12 páginas');
  });
}
