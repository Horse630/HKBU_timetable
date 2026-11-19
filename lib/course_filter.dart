import 'models.dart';
import 'reviews.dart';

/// Letter heading of a course code, such as COMP in COMP4006.
String subjectOf(String code) {
  final match = RegExp(r'^[A-Za-z]+').firstMatch(code);
  return (match?.group(0) ?? code).toUpperCase();
}

class BusySpan {
  const BusySpan({
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
    required this.courseCode,
    required this.sectionId,
  });

  final int weekday;
  final int startMinute;
  final int endMinute;
  final String courseCode;
  final String sectionId;
}

/// Sections that do not overlap a time already on the timetable.
/// The section that occupies a slot stays visible, so it can be removed.
List<Section> openSections(
  Course course, {
  required bool avoidClashes,
  required List<BusySpan> busy,
}) {
  if (!avoidClashes || busy.isEmpty) return course.sections;
  return [
    for (final section in course.sections)
      if (!sectionClashes(course.code, section, busy)) section,
  ];
}

bool sectionClashes(String courseCode, Section section, List<BusySpan> busy) {
  for (final meeting in section.meetings) {
    for (final span in busy) {
      if (span.courseCode == courseCode && span.sectionId == section.id) {
        continue;
      }
      if (meeting.weekday != span.weekday) continue;
      if (rangesOverlap(
        meeting.startMinute,
        meeting.endMinute,
        span.startMinute,
        span.endMinute,
      )) {
        return true;
      }
    }
  }
  return false;
}

List<Course> visibleCourses({
  required List<Course> courses,
  required String query,
  required Set<String> subjects,
  required Set<int> days,
  required bool sortByRating,
  required bool noExam,
  required bool noTest,
  bool avoidClashes = false,
  List<BusySpan> busy = const [],
  ReviewBook? reviews,
}) {
  final q = query.trim().toLowerCase();
  final filtered = courses.where((course) {
    if (subjects.isNotEmpty && !subjects.contains(subjectOf(course.code))) {
      return false;
    }
    if (noExam && course.hasExam != false) return false;
    if (noTest && course.hasTest != false) return false;
    final shown = openSections(course, avoidClashes: avoidClashes, busy: busy);
    if (avoidClashes && busy.isNotEmpty && shown.isEmpty) return false;
    if (days.isNotEmpty && !_meets(shown, days)) return false;
    if (q.isEmpty) return true;
    return course.code.toLowerCase().contains(q) ||
        course.title.toLowerCase().contains(q) ||
        course.chineseTitle.toLowerCase().contains(q);
  }).toList();
  if (!sortByRating) return filtered;
  filtered.sort((a, b) {
    final byRate = _score(reviews, b.code).compareTo(_score(reviews, a.code));
    if (byRate != 0) return byRate;
    final byCount = _rated(reviews, b.code).compareTo(_rated(reviews, a.code));
    if (byCount != 0) return byCount;
    return a.code.compareTo(b.code);
  });
  return filtered;
}

int _score(ReviewBook? reviews, String code) {
  final tally = reviews?.tally(code);
  if (tally == null || tally.rated == 0) return -1;
  return tally.recommendPercent;
}

int _rated(ReviewBook? reviews, String code) => reviews?.tally(code).rated ?? 0;

bool meetsOn(Course course, Set<int> days) {
  return _meets(course.sections, days);
}

bool _meets(List<Section> sections, Set<int> days) {
  for (final section in sections) {
    for (final meeting in section.meetings) {
      if (days.contains(meeting.weekday)) return true;
    }
  }
  return false;
}
