import 'dart:convert';

import 'models.dart';

class CustomClass {
  const CustomClass({
    required this.id,
    required this.title,
    required this.section,
    required this.weekday,
    required this.start,
    required this.end,
    required this.teacher,
  });

  final String id;
  final String title;
  final String section;
  final int weekday;
  final String start;
  final String end;
  final String teacher;

  Course toCourse() {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayIndex = weekday.clamp(1, 7);
    final day = names[dayIndex];
    final name = teacher.trim();
    return Course(
      code: id,
      title: title,
      chineseTitle: '',
      units: 0,
      outline: '',
      prerequisites: const [],
      corequisites: const [],
      targetStudents: const [],
      sections: [
        Section(
          id: section.trim(),
          instructors: name.isEmpty ? const [] : [name],
          medium: '',
          meetings: [
            Meeting(
              weekday: dayIndex,
              startMinute: minutesOf(start),
              endMinute: minutesOf(end),
              venue: '',
              day: day,
              start: start,
              end: end,
            ),
          ],
        ),
      ],
      custom: true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'section': section,
    'day': weekday,
    'start': start,
    'end': end,
    'teacher': teacher,
  };

  static List<CustomClass> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map && item['title'] is String && item['start'] is String && item['end'] is String)
            CustomClass(
              id: item['id'] as String? ?? item['title'] as String,
              title: (item['title'] as String).trim(),
              section: item['section'] as String? ?? '',
              weekday: item['day'] is int ? item['day'] as int : 1,
              start: item['start'] as String,
              end: item['end'] as String,
              teacher: item['teacher'] as String? ?? '',
            ),
      ].where((item) => item.title.isNotEmpty && minutesOf(item.end) > minutesOf(item.start)).toList();
    } catch (_) {
      return const [];
    }
  }
}

List<String> customTimeOptions() {
  return [
    for (var minute = 8 * 60; minute <= 22 * 60 + 30; minute += 10)
      '${(minute ~/ 60).toString().padLeft(2, '0')}:${(minute % 60).toString().padLeft(2, '0')}',
  ];
}
