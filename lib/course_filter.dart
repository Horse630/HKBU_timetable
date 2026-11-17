import 'models.dart';
import 'reviews.dart';

/// Letter heading of a course code, such as COMP in COMP4006.
String subjectOf(String code) {
  final match = RegExp(r'^[A-Za-z]+').firstMatch(code);
  return (match?.group(0) ?? code).toUpperCase();
}

List<Course> visibleCourses({
  required List<Course> courses,
  required String query,
  required Set<String> subjects,
  required Set<int> days,
  required bool sortByRating,
  ReviewBook? reviews,
}) {
  final q = query.trim().toLowerCase();
  final filtered = courses.where((course) {
    if (subjects.isNotEmpty && !subjects.contains(subjectOf(course.code))) return false;
    if (days.isNotEmpty && !meetsOn(course, days)) return false;
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
  for (final section in course.sections) {
    for (final meeting in section.meetings) {
      if (days.contains(meeting.weekday)) return true;
    }
  }
  return false;
}
