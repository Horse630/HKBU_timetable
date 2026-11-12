import 'package:flutter_test/flutter_test.dart';
import 'package:hkbu_timetable/models.dart';
import 'package:hkbu_timetable/schedule.dart';

void main() {
  test('back to back classes do not overlap', () {
    expect(
      rangesOverlap(minutesOf('09:30'), minutesOf('11:20'), minutesOf('11:20'), minutesOf('13:20')),
      isFalse,
    );
  });

  test('partial overlap is a clash and the blocks sit side by side', () {
    final catalog = Catalog([
      _course('COMP4006', 'Fri', '18:30', '20:30'),
      _course('ISEM3036', 'Fri', '15:30', '18:30'),
      _course('ISEM3027', 'Fri', '16:30', '17:30'),
    ]);
    final blocks = layoutBlocks(catalog, {
      'COMP4006': '00001',
      'ISEM3036': '00001',
      'ISEM3027': '00001',
    });

    final comp = blocks.singleWhere((block) => block.course.code == 'COMP4006');
    final isem = blocks.singleWhere((block) => block.course.code == 'ISEM3036');
    expect(comp.conflict, isFalse);
    expect(isem.conflict, isTrue);
    expect(isem.laneCount, 2);
    expect(findClashes(blocks), hasLength(1));
  });
}

Course _course(String code, String day, String start, String end) {
  return Course(
    code: code,
    title: code,
    chineseTitle: '',
    units: 3,
    outline: '',
    prerequisites: const [],
    corequisites: const [],
    targetStudents: const [],
    sections: [
      Section(
        id: '00001',
        instructors: const [],
        medium: 'English',
        meetings: [
          Meeting(
            weekday: weekdays[day]!,
            startMinute: minutesOf(start),
            endMinute: minutesOf(end),
            venue: 'SCT503',
            day: day,
            start: start,
            end: end,
          ),
        ],
      ),
    ],
  );
}
