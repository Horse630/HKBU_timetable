import 'dart:convert';

import 'package:flutter/services.dart';

class TaughtCourse {
  const TaughtCourse({
    required this.code,
    required this.title,
    required this.chineseTitle,
    required this.sectionId,
    required this.times,
  });

  final String code;
  final String title;
  final String chineseTitle;
  final String sectionId;
  final List<String> times;

  String displayTitle(bool zh) {
    if (zh && chineseTitle.isNotEmpty) return chineseTitle;
    return title;
  }
}

class Lecturer {
  const Lecturer({
    required this.name,
    required this.departments,
    required this.courses,
  });

  final String name;
  final List<String> departments;
  final List<TaughtCourse> courses;

  int get courseCount => {for (final course in courses) course.code}.length;
}

class DepartmentGroup {
  const DepartmentGroup({required this.name, required this.lecturers});

  final String name;
  final List<Lecturer> lecturers;
}

/// Puts each lecturer under every department they teach in.
/// A lecturer with no department is grouped under an empty name.
List<DepartmentGroup> groupLecturersByDepartment(List<Lecturer> lecturers) {
  final grouped = <String, List<Lecturer>>{};
  for (final lecturer in lecturers) {
    final places = lecturer.departments.isEmpty
        ? const ['']
        : lecturer.departments;
    for (final department in places) {
      grouped.putIfAbsent(department, () => []).add(lecturer);
    }
  }
  final groups = [
    for (final entry in grouped.entries)
      DepartmentGroup(
        name: entry.key,
        lecturers: [
          ...entry.value,
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
      ),
  ];
  groups.sort((a, b) {
    if (a.name.isEmpty) return 1;
    if (b.name.isEmpty) return -1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return groups;
}

const lecturerDataPath = 'data/courses.json';

Future<List<Lecturer>> loadLecturers() async {
  final raw = await rootBundle.loadString(lecturerDataPath);
  return lecturersFromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Groups every named instructor in the SIS course dump by name.
List<Lecturer> lecturersFromJson(Map<String, dynamic> json) {
  final grouped = <String, _LecturerBuild>{};
  for (final item in json['courses'] as List<dynamic>? ?? const []) {
    final course = item as Map<String, dynamic>;
    final code = course['code'] as String? ?? '';
    if (code.isEmpty) continue;
    final title = course['title'] as String? ?? '';
    final chineseTitle = course['chineseTitle'] as String? ?? '';
    for (final sectionItem
        in course['sections'] as List<dynamic>? ?? const []) {
      final section = sectionItem as Map<String, dynamic>;
      final sectionId = section['section'] as String? ?? '';
      final times = [
        for (final meeting in section['meetings'] as List<dynamic>? ?? const [])
          if (((meeting as Map<String, dynamic>)['dayTime'] as String? ?? '')
              .trim()
              .isNotEmpty)
            (meeting['dayTime'] as String).trim(),
      ];
      for (final instructorItem
          in section['instructors'] as List<dynamic>? ?? const []) {
        final instructor = instructorItem as Map<String, dynamic>;
        final name = (instructor['name'] as String? ?? '').trim();
        if (name.isEmpty) continue;
        final department = (instructor['department'] as String? ?? '').trim();
        final build = grouped.putIfAbsent(name, () => _LecturerBuild(name));
        if (department.isNotEmpty) build.departments.add(department);
        build.courses.add(
          TaughtCourse(
            code: code,
            title: title,
            chineseTitle: chineseTitle,
            sectionId: sectionId,
            times: times,
          ),
        );
      }
    }
  }
  final lecturers = [for (final build in grouped.values) build.finish()];
  lecturers.sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );
  return lecturers;
}

class _LecturerBuild {
  _LecturerBuild(this.name);

  final String name;
  final departments = <String>{};
  final courses = <TaughtCourse>[];

  Lecturer finish() {
    final taught = [...courses]
      ..sort((a, b) {
        final byCode = a.code.compareTo(b.code);
        if (byCode != 0) return byCode;
        return a.sectionId.compareTo(b.sectionId);
      });
    final places = departments.toList()..sort();
    return Lecturer(name: name, departments: places, courses: taught);
  }
}
