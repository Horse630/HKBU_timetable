import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkbu_timetable/download.dart';
import 'package:hkbu_timetable/l10n.dart';
import 'package:hkbu_timetable/models.dart';
import 'package:hkbu_timetable/schedule.dart';
import 'package:hkbu_timetable/wallpaper.dart';
import 'package:hkbu_timetable/widgets/timetable_grid.dart';

void main() {
  test('back to back classes do not overlap', () {
    expect(
      rangesOverlap(
        minutesOf('09:30'),
        minutesOf('11:20'),
        minutesOf('11:20'),
        minutesOf('13:20'),
      ),
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
      'COMP4006': ['00001'],
      'ISEM3036': ['00001'],
      'ISEM3027': ['00001'],
    });

    final comp = blocks.singleWhere((block) => block.course.code == 'COMP4006');
    final isem = blocks.singleWhere((block) => block.course.code == 'ISEM3036');
    expect(comp.conflict, isFalse);
    expect(isem.conflict, isTrue);
    expect(isem.laneCount, 2);
    expect(findClashes(blocks), hasLength(1));
  });

  test('sections of the same course can be selected separately', () {
    final course = Course(
      code: 'COMP3115',
      title: 'Exploratory Data Analysis and Visualization',
      chineseTitle: '',
      units: 3,
      outline: '',
      prerequisites: const [],
      corequisites: const [],
      targetStudents: const [],
      sections: [
        _section('00001', 'Thu', '15:30', '17:20'),
        _section('20001', 'Thu', '16:00', '17:00'),
      ],
    );
    final blocks = layoutBlocks(Catalog([course]), {
      'COMP3115': ['00001', '20001'],
    });
    expect(blocks.map((block) => block.section.id).toSet(), {'00001', '20001'});
    expect(blocks.every((block) => block.conflict), isTrue);
    expect(findClashes(blocks), hasLength(1));
  });

  test('a custom class appears on its weekday and can show the teacher under the title', () {
    final catalog = Catalog([_course('COMP1005', 'Tue', '09:30', '11:20')]);
    final custom = Course(
      code: 'custom-1',
      title: 'Piano lesson',
      chineseTitle: '',
      units: 0,
      outline: '',
      prerequisites: const [],
      corequisites: const [],
      targetStudents: const [],
      sections: [
        Section(
          id: 'A',
          instructors: const ['Dr Lee'],
          medium: '',
          meetings: [
            Meeting(
              weekday: 2,
              startMinute: minutesOf('09:30'),
              endMinute: minutesOf('10:20'),
              venue: '',
              day: 'Tue',
              start: '09:30',
              end: '10:20',
            ),
          ],
        ),
      ],
      custom: true,
    );
    final blocks = layoutBlocks(
      catalog,
      {
        'COMP1005': ['00001'],
      },
      extras: [custom],
    );
    final own = blocks.singleWhere((block) => block.course.custom);
    expect(own.conflict, isTrue);
    expect(
      blockLabel(own, narrow: false, showTeacher: false),
      'Piano lesson\nA',
    );
    expect(
      blockLabel(own, narrow: false, showTeacher: true),
      'Piano lesson\nA\nDr Lee',
    );

    final official = Course(
      code: 'COMP1005',
      title: 'Essence of Computing',
      chineseTitle: '',
      units: 3,
      outline: '',
      prerequisites: const [],
      corequisites: const [],
      targetStudents: const [],
      sections: [
        Section(
          id: '00001',
          instructors: const ['Prof Chan'],
          medium: '',
          meetings: [
            Meeting(
              weekday: 1,
              startMinute: minutesOf('09:30'),
              endMinute: minutesOf('11:20'),
              venue: '',
              day: 'Mon',
              start: '09:30',
              end: '11:20',
            ),
          ],
        ),
      ],
    );
    final officialBlock = layoutBlocks(Catalog([official]), {
      'COMP1005': ['00001'],
    }).single;
    expect(
      blockLabel(officialBlock, narrow: false, showTeacher: false),
      'COMP1005 (00001)',
    );
    expect(
      blockLabel(officialBlock, narrow: false, showTeacher: true),
      'COMP1005 (00001)\nProf Chan',
    );
    expect(
      blockLabel(officialBlock, narrow: true, showTeacher: true),
      'COMP1005\n00001\nProf Chan',
    );
  });

  test('png filename includes the creation date', () {
    expect(
      timetablePngName(DateTime(2026, 11, 13, 1, 46)),
      'hkbu-timetable-2026-11-13-0146.png',
    );
    expect(
      wallpaperPngName(DateTime(2026, 11, 13, 1, 46)),
      'hkbu-wallpaper-2026-11-13-0146.png',
    );
  });

  test('wallpaper metrics fill the phone with only the timetable', () {
    final metrics = wallpaperMetrics(6);
    expect(metrics.widthFor(6), wallpaperWidth);
    expect(metrics.height, wallpaperHeight);
    expect(metrics.polished, isTrue);
  });

  testWidgets('the wallpaper image is the timetable itself', (tester) async {
    final metrics = wallpaperMetrics(6);
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(
      const Size(wallpaperWidth, wallpaperHeight),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 1,
            height: 1,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: metrics.widthFor(6),
                maxWidth: metrics.widthFor(6),
                minHeight: metrics.height,
                maxHeight: metrics.height,
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: metrics.widthFor(6),
                    height: metrics.height,
                    child: TimetableGrid(
                      days: const [1, 2, 3, 4, 5, 6],
                      blocks: const [],
                      strings: L10n('zh'),
                      metrics: metrics,
                      onBlockTap: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    expect(image.width, wallpaperWidth);
    expect(image.height, wallpaperHeight);
    expect(find.text('浸大時間表'), findsNothing);
    image.dispose();
  });
}

Section _section(String id, String day, String start, String end) {
  return Section(
    id: id,
    instructors: const [],
    medium: 'English',
    meetings: [
      Meeting(
        weekday: weekdays[day]!,
        startMinute: minutesOf(start),
        endMinute: minutesOf(end),
        venue: '',
        day: day,
        start: start,
        end: end,
      ),
    ],
  );
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
