import 'package:flutter/material.dart';

import '../course_filter.dart';
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
    required this.sortByRating,
    required this.subjects,
    required this.selectedSubjects,
    required this.selectedDays,
    required this.noExam,
    required this.noTest,
    required this.avoidClashes,
    required this.busy,
    required this.onToggleNoExam,
    required this.onToggleNoTest,
    required this.onToggleDay,
    required this.onToggleSort,
    required this.onToggleSubject,
    required this.onClearSubjects,
    required this.reviews,
    required this.reviewsFailed,
    required this.onSubmitReview,
    required this.onExpand,
    required this.onSection,
    required this.onOpenOutline,
  });

  final L10n strings;
  final List<Course> courses;
  final Map<String, List<String>> picks;
  final String? expandedCode;
  final TextEditingController search;
  final bool sortByRating;
  final List<String> subjects;
  final Set<String> selectedSubjects;
  final Set<int> selectedDays;
  final bool noExam;
  final bool noTest;
  final bool avoidClashes;
  final List<BusySpan> busy;
  final VoidCallback onToggleNoExam;
  final VoidCallback onToggleNoTest;
  final ValueChanged<int> onToggleDay;
  final VoidCallback onToggleSort;
  final ValueChanged<String> onToggleSubject;
  final VoidCallback onClearSubjects;
  final ReviewBook? reviews;
  final bool reviewsFailed;
  final Future<void> Function(ReviewDraft draft) onSubmitReview;
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
          _FilterPanel(
            strings: strings,
            sortByRating: sortByRating,
            selectedSubjects: selectedSubjects,
            selectedDays: selectedDays,
            noExam: noExam,
            noTest: noTest,
            onToggleNoExam: onToggleNoExam,
            onToggleNoTest: onToggleNoTest,
            onToggleDay: onToggleDay,
            onToggleSort: onToggleSort,
            onToggleSubject: onToggleSubject,
            onPickSubjects: () => _pickSubjects(context),
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
                        sections: openSections(
                          course,
                          avoidClashes: avoidClashes,
                          busy: busy,
                        ),
                        strings: strings,
                        expanded: expanded,
                        picked: pickedIds.isNotEmpty,
                        pickedSections: pickedIds,
                        reviews: reviews,
                        reviewsFailed: reviewsFailed,
                        onSubmitReview: onSubmitReview,
                        onExpand: () => onExpand(expanded ? '' : course.code),
                        onSection: (section) => onSection(course, section),
                        onOpenOutline: course.outline.isEmpty
                            ? null
                            : () => onOpenOutline(course.outline),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickSubjects(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => _SubjectDialog(
        strings: strings,
        subjects: subjects,
        selected: selectedSubjects,
        onToggle: onToggleSubject,
        onClear: onClearSubjects,
      ),
    );
  }
}

class _FilterPanel extends StatefulWidget {
  const _FilterPanel({
    required this.strings,
    required this.sortByRating,
    required this.selectedSubjects,
    required this.selectedDays,
    required this.noExam,
    required this.noTest,
    required this.onToggleNoExam,
    required this.onToggleNoTest,
    required this.onToggleDay,
    required this.onToggleSort,
    required this.onToggleSubject,
    required this.onPickSubjects,
  });

  final L10n strings;
  final bool sortByRating;
  final Set<String> selectedSubjects;
  final Set<int> selectedDays;
  final bool noExam;
  final bool noTest;
  final VoidCallback onToggleNoExam;
  final VoidCallback onToggleNoTest;
  final ValueChanged<int> onToggleDay;
  final VoidCallback onToggleSort;
  final ValueChanged<String> onToggleSubject;
  final VoidCallback onPickSubjects;

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  var _shown = true;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD7E0EA)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 4, 4, _shown ? 12 : 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.filterTools,
                      style: const TextStyle(
                        color: Color(0xFF0C3C6E),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _shown ? strings.hideFilters : strings.showFilters,
                    visualDensity: VisualDensity.compact,
                    color: const Color(0xFF0C3C6E),
                    onPressed: () => setState(() => _shown = !_shown),
                    icon: Icon(
                      _shown
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                    ),
                  ),
                ],
              ),
              if (_shown) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ChoiceButton(
                      label: strings.sortByRating,
                      icon: Icons.sort,
                      selected: widget.sortByRating,
                      onPressed: widget.onToggleSort,
                    ),
                    _ChoiceButton(
                      label: widget.selectedSubjects.isEmpty
                          ? strings.subjects
                          : strings.subjectsChosen(
                              widget.selectedSubjects.length,
                            ),
                      icon: Icons.filter_alt_outlined,
                      selected: widget.selectedSubjects.isNotEmpty,
                      onPressed: widget.onPickSubjects,
                    ),
                    _ChoiceButton(
                      label: strings.noExam,
                      icon: Icons.event_busy,
                      selected: widget.noExam,
                      onPressed: widget.onToggleNoExam,
                    ),
                    _ChoiceButton(
                      label: strings.noTest,
                      icon: Icons.rule,
                      selected: widget.noTest,
                      onPressed: widget.onToggleNoTest,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final day in const [1, 2, 3, 4, 5, 6])
                      _DayButton(
                        label: strings.dayMedium(day),
                        selected: widget.selectedDays.contains(day),
                        onPressed: () => widget.onToggleDay(day),
                      ),
                  ],
                ),
                if (widget.selectedSubjects.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final subject
                          in (widget.selectedSubjects.toList()..sort()))
                        InputChip(
                          label: Text(subject),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: const Color(0xFFE7EEF5),
                          labelStyle: const TextStyle(
                            color: Color(0xFF0C3C6E),
                            fontWeight: FontWeight.w700,
                          ),
                          deleteIconColor: const Color(0xFF0C3C6E),
                          onDeleted: () => widget.onToggleSubject(subject),
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(48, 36),
        backgroundColor: selected
            ? const Color(0xFF0C3C6E)
            : const Color(0xFFE7EEF5),
        foregroundColor: selected ? Colors.white : const Color(0xFF0C3C6E),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        backgroundColor: selected
            ? const Color(0xFF0C3C6E)
            : const Color(0xFFE7EEF5),
        foregroundColor: selected ? Colors.white : const Color(0xFF0C3C6E),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _SubjectDialog extends StatefulWidget {
  const _SubjectDialog({
    required this.strings,
    required this.subjects,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  final L10n strings;
  final List<String> subjects;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  State<_SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<_SubjectDialog> {
  final _query = TextEditingController();
  late final Set<String> _selected = {...widget.selected};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.text.trim().toUpperCase();
    final shown = q.isEmpty
        ? widget.subjects
        : widget.subjects.where((subject) => subject.contains(q)).toList();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.strings.subjects,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.strings.subjectHelp,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _query,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: widget.strings.subjectHint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final subject in shown)
                        FilterChip(
                          label: Text(subject),
                          selected: _selected.contains(subject),
                          showCheckmark: false,
                          selectedColor: const Color(0xFF0C3C6E),
                          labelStyle: TextStyle(
                            color: _selected.contains(subject)
                                ? Colors.white
                                : const Color(0xFF0C3C6E),
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) {
                            setState(() {
                              if (!_selected.add(subject))
                                _selected.remove(subject);
                            });
                            widget.onToggle(subject);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () {
                            setState(_selected.clear);
                            widget.onClear();
                          },
                    child: Text(widget.strings.clearSubjects),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0C3C6E),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(widget.strings.done),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.course,
    required this.sections,
    required this.strings,
    required this.expanded,
    required this.picked,
    required this.pickedSections,
    required this.reviews,
    required this.reviewsFailed,
    required this.onSubmitReview,
    required this.onExpand,
    required this.onSection,
    required this.onOpenOutline,
  });

  final Course course;
  final List<Section> sections;
  final L10n strings;
  final bool expanded;
  final bool picked;
  final List<String> pickedSections;
  final ReviewBook? reviews;
  final bool reviewsFailed;
  final Future<void> Function(ReviewDraft draft) onSubmitReview;
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
                        Text(
                          course.code,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(primary),
                        if (secondary != null)
                          Text(
                            secondary,
                            style: const TextStyle(
                              color: Color(0xFF667085),
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          strings.courseMeta(
                            formatUnits(course.units),
                            sections.length,
                          ),
                          style: const TextStyle(
                            color: Color(0xFF667085),
                            fontSize: 12,
                          ),
                        ),
                        if ((tally != null && tally.rated > 0) ||
                            course.hasExam == false ||
                            course.hasTest == false)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (tally != null && tally.rated > 0)
                                  _ReviewBadge(
                                    percent: tally.recommendPercent,
                                    label: strings.recommendShare(
                                      tally.recommendPercent,
                                    ),
                                  ),
                                if (course.hasExam == false)
                                  _AssessmentBadge(label: strings.noExam),
                                if (course.hasTest == false)
                                  _AssessmentBadge(label: strings.noTest),
                              ],
                            ),
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
            if (onOpenOutline != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0C3C6E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  onPressed: onOpenOutline,
                  icon: const Icon(Icons.menu_book, size: 18),
                  label: Text(strings.outline),
                ),
              ),
            if (course.prerequisites.isNotEmpty)
              _Note(
                label: strings.prerequisite,
                text: course.prerequisites.join(' | '),
              ),
            if (course.corequisites.isNotEmpty)
              _Note(
                label: strings.corequisite,
                text: course.corequisites.join(' | '),
              ),
            if (course.targetStudents.isNotEmpty)
              _Note(
                label: strings.target,
                text: course.targetStudents.join(' | '),
              ),
            CourseReviews(
              key: ValueKey(course.code),
              strings: strings,
              rows: reviews?.of(course.code) ?? const [],
              loading: reviews == null && !reviewsFailed,
              failed: reviewsFailed && reviews == null,
              courseCode: course.code,
              courseTitle: course.displayTitle(strings.zh),
              onSubmit: onSubmitReview,
            ),
            for (final section in sections)
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AssessmentBadge extends StatelessWidget {
  const _AssessmentBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE7EEF5),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0C3C6E),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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
        style: const TextStyle(
          color: Color(0xFF475467),
          fontSize: 12,
          height: 1.35,
        ),
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
        .map(
          (meeting) => strings.slot(
            strings.dayMedium(meeting.weekday),
            meeting.start,
            meeting.end,
          ),
        )
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
                Text(
                  section.id,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  times.isEmpty ? strings.noTime : times,
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
                for (final name in section.instructors)
                  Text(
                    '${strings.instructor}: $name',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                if (section.medium.isNotEmpty)
                  Text(
                    strings.medium(section.medium),
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: selected
                  ? const Color(0xFF0C3C6E)
                  : const Color(0xFFE7EEF5),
              foregroundColor: selected
                  ? Colors.white
                  : const Color(0xFF0C3C6E),
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
