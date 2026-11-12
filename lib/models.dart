import 'dart:convert';

import 'package:flutter/services.dart';

const weekdays = {'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6, 'Sun': 7};

int minutesOf(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

bool rangesOverlap(int startA, int endA, int startB, int endB) {
  return startA < endB && startB < endA;
}

String formatUnits(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}

class Meeting {
  const Meeting({
    required this.weekday,
    required this.startMinute,
    required this.endMinute,
    required this.venue,
    required this.day,
    required this.start,
    required this.end,
  });

  final int weekday;
  final int startMinute;
  final int endMinute;
  final String venue;
  final String day;
  final String start;
  final String end;

  factory Meeting.fromJson(Map<String, dynamic> json) {
    final day = json['day'] as String;
    final start = json['start'] as String;
    final end = json['end'] as String;
    return Meeting(
      weekday: weekdays[day] ?? 1,
      startMinute: minutesOf(start),
      endMinute: minutesOf(end),
      venue: json['venue'] as String? ?? '',
      day: day,
      start: start,
      end: end,
    );
  }
}

class Section {
  const Section({
    required this.id,
    required this.instructors,
    required this.medium,
    required this.meetings,
  });

  final String id;
  final List<String> instructors;
  final String medium;
  final List<Meeting> meetings;

  bool get hasTime => meetings.isNotEmpty;

  factory Section.fromJson(Map<String, dynamic> json) {
    final meetings = (json['meetings'] as List<dynamic>)
        .map((item) => Meeting.fromJson(item as Map<String, dynamic>))
        .where((meeting) => meeting.endMinute > meeting.startMinute)
        .toList();
    return Section(
      id: json['id'] as String,
      instructors: (json['instructors'] as List<dynamic>).cast<String>(),
      medium: json['medium'] as String? ?? '',
      meetings: meetings,
    );
  }
}

class Course {
  const Course({
    required this.code,
    required this.title,
    required this.chineseTitle,
    required this.units,
    required this.outline,
    required this.prerequisites,
    required this.corequisites,
    required this.targetStudents,
    required this.sections,
  });

  final String code;
  final String title;
  final String chineseTitle;
  final double units;
  final String outline;
  final List<String> prerequisites;
  final List<String> corequisites;
  final List<String> targetStudents;
  final List<Section> sections;

  String displayTitle(bool zh) {
    if (zh && chineseTitle.isNotEmpty) return chineseTitle;
    return title;
  }

  Section? sectionById(String id) {
    for (final section in sections) {
      if (section.id == id) return section;
    }
    return null;
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      code: json['code'] as String,
      title: json['title'] as String? ?? '',
      chineseTitle: json['zh'] as String? ?? '',
      units: (json['units'] as num).toDouble(),
      outline: json['outline'] as String? ?? '',
      prerequisites: (json['prereq'] as List<dynamic>? ?? const []).cast<String>(),
      corequisites: (json['coreq'] as List<dynamic>? ?? const []).cast<String>(),
      targetStudents: (json['target'] as List<dynamic>? ?? const []).cast<String>(),
      sections: (json['sections'] as List<dynamic>).map((item) => Section.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

class Catalog {
  Catalog(List<Course> courses)
    : courses = List.unmodifiable(courses),
      byCode = {for (final course in courses) course.code: course};

  final List<Course> courses;
  final Map<String, Course> byCode;

  static Future<Catalog> load() async {
    final raw = await rootBundle.loadString('assets/courses.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final courses = (json['courses'] as List<dynamic>).map((item) => Course.fromJson(item as Map<String, dynamic>)).toList();
    return Catalog(courses);
  }
}
