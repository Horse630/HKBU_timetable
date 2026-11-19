import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkbu_timetable/l10n.dart';
import 'package:hkbu_timetable/lecturers.dart';
import 'package:hkbu_timetable/widgets/lecturer_browser.dart';

void main() {
  test('a lecturer collects every section they teach', () {
    final lecturers = lecturersFromJson({
      'courses': [
        {
          'code': 'ACCT1006',
          'title': 'Principles of Accounting II',
          'chineseTitle': '會計學原理',
          'sections': [
            {
              'section': '00003',
              'meetings': [
                {'dayTime': 'Tue 13:30-15:20'},
              ],
              'instructors': [
                {'name': ' Dr Ko, Man Lut ', 'department': 'Accountancy'},
              ],
            },
            {
              'section': '00001',
              'meetings': [
                {'dayTime': 'Fri 09:30-11:20'},
              ],
              'instructors': [
                {'name': 'Mr Cheng, Anthony T F', 'department': 'Accountancy'},
                {'name': '', 'department': 'Ignored'},
              ],
            },
          ],
        },
        {
          'code': 'ACCT2005',
          'title': 'Intermediate Accounting I',
          'chineseTitle': '',
          'sections': [
            {
              'section': '00001',
              'meetings': [
                {'dayTime': 'Mon 09:30-12:20'},
              ],
              'instructors': [
                {'name': 'Mr Cheng, Anthony T F', 'department': 'Accountancy'},
              ],
            },
          ],
        },
      ],
    });

    expect(lecturers.map((item) => item.name), [
      'Dr Ko, Man Lut',
      'Mr Cheng, Anthony T F',
    ]);
    final cheng = lecturers[1];
    expect(cheng.courseCount, 2);
    expect(
      cheng.courses.map((course) => '${course.code} ${course.sectionId}'),
      ['ACCT1006 00001', 'ACCT2005 00001'],
    );
    expect(cheng.courses.first.times, ['Fri 09:30-11:20']);
  });

  test('lecturers are grouped under every department they belong to', () {
    final groups = groupLecturersByDepartment([
      const Lecturer(
        name: 'Dr B',
        departments: ['Computer Science', 'Mathematics'],
        courses: [],
      ),
      const Lecturer(
        name: 'Dr A',
        departments: ['Computer Science'],
        courses: [],
      ),
      const Lecturer(name: 'Prof C', departments: [], courses: []),
    ]);

    expect(groups.map((group) => group.name), [
      'Computer Science',
      'Mathematics',
      '',
    ]);
    expect(groups[0].lecturers.map((item) => item.name), ['Dr A', 'Dr B']);
    expect(groups[1].lecturers.map((item) => item.name), ['Dr B']);
    expect(groups[2].lecturers.map((item) => item.name), ['Prof C']);
  });

  test('lecturers are read from data/courses.json', () {
    final json = jsonDecode(
      File('data/courses.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final lecturers = lecturersFromJson(json);
    final cheng = lecturers.singleWhere(
      (item) => item.name == 'Mr Cheng, Anthony T F',
    );
    expect(
      cheng.courses.any(
        (course) => course.code == 'ACCT1006' && course.sectionId == '00001',
      ),
      isTrue,
    );
    expect(lecturers.every((item) => item.name.trim().isNotEmpty), isTrue);
  });

  testWidgets('search finds a lecturer and the button shows their courses', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LecturerBrowser(strings: L10n('zh'))),
      ),
    );
    expect(find.text('正在載入講師…'), findsOneWidget);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Mr Cheng, Anthony T F');
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'Mr Cheng, Anthony T F',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('所教科目'), findsOneWidget);
    await tester.tap(find.textContaining('所教科目'));
    await tester.pump();

    expect(find.textContaining('隱藏科目'), findsOneWidget);
    expect(find.textContaining('ACCT1006 (00001)'), findsOneWidget);
    expect(
      find.text('Department of Accountancy, Economics and Finance'),
      findsWidgets,
    );

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.text('學系'));
    await tester.pumpAndSettle();
    expect(find.text('搜尋學系'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Computer Science');
    await tester.pump();
    await tester.tap(find.text('Department of Computer Science'));
    await tester.pump();
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();

    expect(find.text('學系 · 1'), findsOneWidget);
    expect(find.text('Department of Computer Science'), findsWidgets);
    expect(
      find.text('Department of Accountancy, Economics and Finance'),
      findsNothing,
    );
    expect(find.textContaining('所教科目'), findsWidgets);

    await tester.tap(find.byTooltip('隱藏'));
    await tester.pump();
    expect(find.text('Department of Computer Science'), findsWidgets);
    expect(find.textContaining('所教科目'), findsNothing);

    await tester.tap(find.byTooltip('展開'));
    await tester.pump();
    expect(find.textContaining('所教科目'), findsWidgets);
  });
}
