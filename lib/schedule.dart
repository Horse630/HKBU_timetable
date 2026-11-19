import 'models.dart';

bool _sameClass(GridBlock a, GridBlock b) => a.course.code == b.course.code && a.section.id == b.section.id;

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

List<GridBlock> layoutBlocks(Catalog catalog, Map<String, List<String>> picks, {List<Course> extras = const []}) {
  final items = <GridBlock>[];
  for (final entry in picks.entries) {
    final course = catalog.byCode[entry.key];
    if (course == null) continue;
    for (final sectionId in entry.value) {
      final section = course.sectionById(sectionId);
      if (section == null) continue;
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
  }
  for (final course in extras) {
    for (final section in course.sections) {
      for (final meeting in section.meetings) {
        items.add(
          GridBlock(course: course, section: section, meeting: meeting, lane: 0, laneCount: 1, conflict: false),
        );
      }
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
            !_sameClass(other, item) &&
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
      if (_sameClass(a, b)) continue;
      if (a.meeting.weekday != b.meeting.weekday) continue;
      if (!rangesOverlap(a.meeting.startMinute, a.meeting.endMinute, b.meeting.startMinute, b.meeting.endMinute)) {
        continue;
      }
      final names = [blockHeading(a), blockHeading(b)]..sort();
      final key = '${names[0]}|${names[1]}|${a.meeting.weekday}';
      if (!seen.add(key)) continue;
      clashes.add(Clash(blockHeading(a), blockHeading(b), a.meeting.weekday));
    }
  }
  return clashes;
}

String blockHeading(GridBlock block) {
  if (block.course.custom) {
    final section = block.section.id.trim();
    return section.isEmpty ? block.course.title : '${block.course.title} ($section)';
  }
  final section = block.section.id.trim();
  return section.isEmpty ? block.course.code : '${block.course.code} ($section)';
}

String blockLabel(GridBlock block, {required bool narrow, required bool showTeacher}) {
  final lines = <String>[];
  if (block.course.custom) {
    lines.add(block.course.title);
    final section = block.section.id.trim();
    if (section.isNotEmpty) lines.add(section);
  } else if (narrow) {
    lines.add(block.course.code);
    if (block.section.id.isNotEmpty) lines.add(block.section.id);
  } else {
    lines.add(block.section.id.isEmpty ? block.course.code : '${block.course.code} (${block.section.id})');
  }
  if (showTeacher) {
    for (final name in block.section.instructors) {
      final trimmed = name.trim();
      if (trimmed.isNotEmpty) lines.add(trimmed);
    }
  }
  if (block.meeting.venue.isNotEmpty) lines.add(block.meeting.venue);
  return lines.join('\n');
}
