import 'package:flutter_test/flutter_test.dart';
import 'package:hkbu_timetable/l10n.dart';
import 'package:hkbu_timetable/visits.dart';

void main() {
  test('goatcounter totals keep the 11790 base and then rise', () {
    expect(parseVisitCount('{"count":"11\u202f790"}'), 11790);
    expect(parseVisitCount('{"count":"12,010"}'), 12010);
    expect(displayedVisits(parseVisitCount('{"count":"10"}')), visitBase);
    expect(displayedVisits(parseVisitCount('<html>403</html>')), visitBase);
    expect(displayedVisits(12004), 12004);
    expect(const L10n('zh').visits(formatVisitCount(11790)), '網站瀏覽人數: 11,790');
    expect(const L10n('en').visits(formatVisitCount(12004)), '12,004 visits');
  });
}
