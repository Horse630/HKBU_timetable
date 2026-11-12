import 'models.dart';

class GridBlock {
  const GridBlock({
    required this.course,
    required this.section,
    required this.meeting,
    required this.lane,
    required this.laneCount,
    required this.conflict,
  });

  final Course course;
  final Section section;
  final Meeting meeting;
  final int lane;
  final int laneCount;
  final bool conflict;
}

class Clash {
  const Clash(this.left, this.right, this.weekday);

  final String left;
  final String right;
  final int weekday;
}

List<GridBlock> layoutBlocks(Catalog catalog, Map<String, String> picks) {
  final items = <GridBlock>[];
  for (final entry in picks.entries) {
    final course = catalog.byCode[entry.key];
    final section = course?.sectionById(entry.value);
    if (course == null || section == null) continue;
    for (final meeting in section.meetings) {
      items.add(
        GridBlock(
          course: course,
          section: section,
          meeting: meeting,
          lane: 0,
          laneCount: 1,
          conflict: false,
        ),
      );
    }
  }

  final laidOut = <GridBlock>[];
  for (var day = 1; day <= 7; day++) {
    final dayItems = items.where((item) => item.meeting.weekday == day).toList()
      ..sort((a, b) => a.meeting.startMinute.compareTo(b.meeting.startMinute));
    final laneEnds = <int>[];
    final lanes = <int>[];
    for (final item in dayItems) {
      var lane = -1;
      for (var index = 0; index < laneEnds.length; index++) {
        if (laneEnds[index] <= item.meeting.startMinute) {
          lane = index;
          break;
        }
      }
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(item.meeting.endMinute);
      } else {
        laneEnds[lane] = item.meeting.endMinute;
      }
      lanes.add(lane);
    }
    final laneCount = laneEnds.isEmpty ? 1 : laneEnds.length;
    for (var index = 0; index < dayItems.length; index++) {
      final item = dayItems[index];
      final conflict = dayItems.any(
        (other) =>
            other != item &&
            rangesOverlap(
              item.meeting.startMinute,
              item.meeting.endMinute,
              other.meeting.startMinute,
              other.meeting.endMinute,
            ),
      );
      laidOut.add(
        GridBlock(
          course: item.course,
          section: item.section,
          meeting: item.meeting,
          lane: lanes[index],
          laneCount: laneCount,
          conflict: conflict,
        ),
      );
    }
  }
  return laidOut;
}

List<Clash> findClashes(List<GridBlock> blocks) {
  final clashes = <Clash>[];
  final seen = <String>{};
  for (var i = 0; i < blocks.length; i++) {
    for (var j = i + 1; j < blocks.length; j++) {
      final a = blocks[i];
      final b = blocks[j];
      if (a.meeting.weekday != b.meeting.weekday) continue;
      if (!rangesOverlap(a.meeting.startMinute, a.meeting.endMinute, b.meeting.startMinute, b.meeting.endMinute)) {
        continue;
      }
      final key = '${a.course.code}|${b.course.code}|${a.meeting.weekday}';
      if (!seen.add(key)) continue;
      clashes.add(
        Clash(
          '${a.course.code} (${a.section.id})',
          '${b.course.code} (${b.section.id})',
          a.meeting.weekday,
        ),
      );
    }
  }
  return clashes;
}
