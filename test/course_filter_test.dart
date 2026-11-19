import 'package:flutter_test/flutter_test.dart';
import 'package:hkbu_timetable/course_filter.dart';
import 'package:hkbu_timetable/models.dart';
import 'package:hkbu_timetable/reviews.dart';

void main() {
  test('subject heading is the letters before the course number', () {
    expect(subjectOf('COMP4006'), 'COMP');
    expect(subjectOf('gcap3225'), 'GCAP');
    expect(subjectOf('ISEM3036'), 'ISEM');
  });

  test('subject filter keeps only the chosen headings', () {
    final courses = [
      _course('COMP1001'),
      _course('ISEM2001'),
      _course('GCAP3225'),
    ];
    final visible = visibleCourses(
      courses: courses,
      query: '',
      subjects: {'COMP', 'ISEM'},
      days: const {},
      sortByRating: false,
      noExam: false,
      noTest: false,
      reviews: null,
    );
    expect(visible.map((course) => course.code), ['COMP1001', 'ISEM2001']);
  });

  test('sort by rating puts the higher recommend share first', () {
    final courses = [
      _course('AAAA1001'),
      _course('BBBB1001'),
      _course('CCCC1001'),
    ];
    final reviews = ReviewBook.parse(
      'Timestamp,Course Code,Course Title,Tutor / Lecturer,Reg / Don\'t Reg ?,Comment / Reason\n'
      '2026/1/1 上午 1:00:00,AAAA1001,T,L,Recommend｜推薦,ok\n'
      '2026/1/1 上午 1:00:00,AAAA1001,T,L,Not Recommend｜不推薦,no\n'
      '2026/1/1 上午 1:00:00,BBBB1001,T,L,Recommend｜推薦,ok\n'
      '2026/1/1 上午 1:00:00,BBBB1001,T,L,Recommend｜推薦,ok\n',
    );
    final visible = visibleCourses(
      courses: courses,
      query: '',
      subjects: const {},
      days: const {},
      sortByRating: true,
      noExam: false,
      noTest: false,
      reviews: reviews,
    );
    expect(visible.map((course) => course.code), ['BBBB1001', 'AAAA1001', 'CCCC1001']);
  });

  test('day filter keeps courses that meet on any chosen day', () {
    final courses = [
      _courseOn('MON1001', [1]),
      _courseOn('TUE1001', [2]),
      _courseOn('MIX1001', [1, 3]),
      _course('NONE1001'),
    ];
    final monday = visibleCourses(
      courses: courses,
      query: '',
      subjects: const {},
      days: {1},
      sortByRating: false,
      noExam: false,
      noTest: false,
      reviews: null,
    );
    expect(monday.map((course) => course.code), ['MON1001', 'MIX1001']);

    final both = visibleCourses(
      courses: courses,
      query: '',
      subjects: const {},
      days: {1, 2},
      sortByRating: false,
      noExam: false,
      noTest: false,
      reviews: null,
    );
    expect(both.map((course) => course.code), ['MON1001', 'TUE1001', 'MIX1001']);
  });

  test('no exam and no test filters keep only courses the outline confirms', () {
    final courses = [
      _course('EXAM1001', hasExam: true, hasTest: true),
      _course('NONE1001', hasExam: false, hasTest: false),
      _course('TEST1001', hasExam: false, hasTest: true),
      _course('UNKNOWN1001'),
    ];
    final noExam = visibleCourses(
      courses: courses,
      query: '',
      subjects: const {},
      days: const {},
      sortByRating: false,
      noExam: true,
      noTest: false,
      reviews: null,
    );
    expect(noExam.map((course) => course.code), ['NONE1001', 'TEST1001']);

    final both = visibleCourses(
      courses: courses,
      query: '',
      subjects: const {},
      days: const {},
      sortByRating: false,
      noExam: true,
      noTest: true,
      reviews: null,
    );
    expect(both.map((course) => course.code), ['NONE1001']);
  });
}

Course _courseOn(String code, List<int> days) {
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
        medium: '',
        meetings: [
          for (final day in days)
            Meeting(
              weekday: day,
              startMinute: 9 * 60,
              endMinute: 10 * 60,
              venue: '',
              day: 'Day',
              start: '09:00',
              end: '10:00',
            ),
        ],
      ),
    ],
  );
}

Course _course(String code, {bool? hasExam, bool? hasTest}) {
  return Course(
    code: code,
    title: code,
    chineseTitle: '',
    units: 3,
    outline: '',
    prerequisites: const [],
    corequisites: const [],
    targetStudents: const [],
    sections: const [],
    hasExam: hasExam,
    hasTest: hasTest,
  );
}
