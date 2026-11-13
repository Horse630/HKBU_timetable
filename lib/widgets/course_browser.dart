import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../reviews.dart';
import 'course_reviews.dart';

class CourseBrowser extends StatelessWidget {
  const CourseBrowser({
    super.key,
    required this.strings,
    required this.courses,
    required this.picks,
    required this.expandedCode,
    required this.search,
    required this.reviews,
    required this.reviewsFailed,
    required this.onExpand,
    required this.onSection,
    required this.onOpenOutline,
  });

  final L10n strings;
  final List<Course> courses;
  final Map<String, List<String>> picks;
  final String? expandedCode;
  final TextEditingController search;
  final ReviewBook? reviews;
  final bool reviewsFailed;
  final ValueChanged<String> onExpand;
  final void Function(Course course, Section section) onSection;
  final ValueChanged<String> onOpenOutline;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: search,
              decoration: InputDecoration(
                hintText: strings.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: strings.clear,
                        onPressed: () {
                          search.clear();
                          onExpand('');
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: courses.isEmpty
                ? Center(child: Text(strings.noResults))
                : ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (context, index) {
                      final course = courses[index];
                      final expanded = course.code == expandedCode;
                      final pickedIds = picks[course.code] ?? const <String>[];
                      return _CourseTile(
                        course: course,
                        strings: strings,
                        expanded: expanded,
                        picked: pickedIds.isNotEmpty,
                        pickedSections: pickedIds,
                        reviews: reviews,
                        reviewsFailed: reviewsFailed,
                        onExpand: () => onExpand(expanded ? '' : course.code),
                        onSection: (section) => onSection(course, section),
                        onOpenOutline: course.outline.isEmpty ? null : () => onOpenOutline(course.outline),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.course,
    required this.strings,
    required this.expanded,
    required this.picked,
    required this.pickedSections,
    required this.reviews,
    required this.reviewsFailed,
    required this.onExpand,
    required this.onSection,
    required this.onOpenOutline,
  });

  final Course course;
  final L10n strings;
  final bool expanded;
  final bool picked;
  final List<String> pickedSections;
  final ReviewBook? reviews;
  final bool reviewsFailed;
  final VoidCallback onExpand;
  final ValueChanged<Section> onSection;
  final VoidCallback? onOpenOutline;

  @override
  Widget build(BuildContext context) {
    final zh = strings.zh;
    final primary = course.displayTitle(zh);
    final tally = reviews?.tally(course.code);
    final secondary = zh && course.chineseTitle.isNotEmpty
        ? course.title
        : (!zh && course.chineseTitle.isNotEmpty ? course.chineseTitle : null);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: picked ? const Color(0xFFE8F2FA) : Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onExpand,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(course.code, style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(primary),
                        if (secondary != null)
                          Text(secondary, style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(
                          strings.courseMeta(formatUnits(course.units), course.sections.length),
                          style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
                        ),
                        if (tally != null && tally.rated > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _ReviewBadge(percent: tally.recommendPercent, label: strings.recommendShare(tally.recommendPercent)),
                          ),
                      ],
                    ),
                  ),
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            if (course.prerequisites.isNotEmpty) _Note(label: strings.prerequisite, text: course.prerequisites.join(' | ')),
            if (course.corequisites.isNotEmpty) _Note(label: strings.corequisite, text: course.corequisites.join(' | ')),
            if (course.targetStudents.isNotEmpty) _Note(label: strings.target, text: course.targetStudents.join(' | ')),
            CourseReviews(
              key: ValueKey(course.code),
              strings: strings,
              rows: reviews?.of(course.code) ?? const [],
              loading: reviews == null && !reviewsFailed,
              failed: reviewsFailed && reviews == null,
            ),
            if (onOpenOutline != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: onOpenOutline, child: Text(strings.outline)),
              ),
            for (final section in course.sections)
              _SectionRow(
                section: section,
                strings: strings,
                selected: pickedSections.contains(section.id),
                onPressed: () => onSection(section),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ReviewBadge extends StatelessWidget {
  const _ReviewBadge({required this.percent, required this.label});

  final int percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final positive = percent >= 50;
    final color = positive ? const Color(0xFF146C36) : const Color(0xFFB42318);
    final fill = positive ? const Color(0xFFE5F6EC) : const Color(0xFFFDECEC);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Text(
        '$label: $text',
        style: const TextStyle(color: Color(0xFF475467), fontSize: 12, height: 1.35),
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.section,
    required this.strings,
    required this.selected,
    required this.onPressed,
  });

  final Section section;
  final L10n strings;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final times = section.meetings
        .map((meeting) => strings.slot(strings.dayMedium(meeting.weekday), meeting.start, meeting.end))
        .join(' · ');
    final label = selected ? strings.remove : strings.add;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.id, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(times.isEmpty ? strings.noTime : times, style: const TextStyle(fontSize: 13, height: 1.3)),
                if (section.instructors.isNotEmpty)
                  Text(
                    '${strings.instructor}: ${section.instructors.join(', ')}',
                    style: const TextStyle(color: Color(0xFF667085), fontSize: 12, height: 1.3),
                  ),
                if (section.medium.isNotEmpty)
                  Text(strings.medium(section.medium), style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: selected ? const Color(0xFF0C3C6E) : const Color(0xFFE7EEF5),
              foregroundColor: selected ? Colors.white : const Color(0xFF0C3C6E),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onPressed: onPressed,
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
