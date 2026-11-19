import 'package:flutter/material.dart';

import '../l10n.dart';
import '../lecturers.dart';

class LecturerBrowser extends StatefulWidget {
  const LecturerBrowser({
    super.key,
    required this.strings,
    required this.onCourse,
  });

  final L10n strings;
  final ValueChanged<String> onCourse;

  @override
  State<LecturerBrowser> createState() => _LecturerBrowserState();
}

class _LecturerBrowserState extends State<LecturerBrowser> {
  final _search = TextEditingController();
  final _open = <String>{};
  final _departments = <String>{};
  final _folded = <String>{};
  late final Future<List<Lecturer>> _lecturers = loadLecturers();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return ColoredBox(
      color: Colors.white,
      child: FutureBuilder<List<Lecturer>>(
        future: _lecturers,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(strings.loadingLecturers),
                ],
              ),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text(strings.loadError));
          }
          final query = _search.text.trim().toLowerCase();
          final groups = [
            for (final group in groupLecturersByDepartment(snapshot.data!))
              if (_departments.isEmpty || _departments.contains(group.name))
                DepartmentGroup(
                  name: group.name,
                  lecturers: [
                    for (final lecturer in group.lecturers)
                      if (_matches(lecturer, query)) lecturer,
                  ],
                ),
          ].where((group) => group.lecturers.isNotEmpty).toList();
          final chosen = _departments.toList()..sort();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: strings.lecturerSearch,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: _departments.isEmpty
                          ? const Color(0xFFE7EEF5)
                          : const Color(0xFF0C3C6E),
                      foregroundColor: _departments.isEmpty
                          ? const Color(0xFF0C3C6E)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () => _pickDepartments(snapshot.data!),
                    icon: const Icon(Icons.account_balance_outlined, size: 16),
                    label: Text(
                      _departments.isEmpty
                          ? strings.departments
                          : strings.departmentsChosen(_departments.length),
                    ),
                  ),
                ),
              ),
              if (chosen.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final department in chosen)
                          InputChip(
                            label: Text(_departmentLabel(strings, department)),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: const Color(0xFFE7EEF5),
                            labelStyle: const TextStyle(
                              color: Color(0xFF0C3C6E),
                              fontWeight: FontWeight.w700,
                            ),
                            deleteIconColor: const Color(0xFF0C3C6E),
                            onDeleted: () =>
                                setState(() => _departments.remove(department)),
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: groups.isEmpty
                    ? Center(child: Text(strings.noLecturers))
                    : ListView.builder(
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          final open = !_folded.contains(group.name);
                          return _DepartmentSection(
                            group: group,
                            strings: strings,
                            open: open,
                            courseOpen: _open,
                            onToggleSection: () {
                              setState(() {
                                if (!_folded.add(group.name)) {
                                  _folded.remove(group.name);
                                }
                              });
                            },
                            onToggleCourse: (name) {
                              setState(() {
                                if (!_open.add(name)) _open.remove(name);
                              });
                            },
                            onOpenCourse: widget.onCourse,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickDepartments(List<Lecturer> lecturers) {
    final names = [
      for (final group in groupLecturersByDepartment(lecturers)) group.name,
    ];
    return showDialog<void>(
      context: context,
      builder: (context) => _DepartmentDialog(
        strings: widget.strings,
        departments: names,
        selected: _departments,
        onToggle: (department) => setState(() {
          if (!_departments.add(department)) {
            _departments.remove(department);
          }
        }),
        onClear: () => setState(_departments.clear),
      ),
    );
  }

  bool _matches(Lecturer lecturer, String query) {
    if (query.isEmpty) return true;
    if (lecturer.name.toLowerCase().contains(query)) return true;
    if (lecturer.departments.any(
      (item) => item.toLowerCase().contains(query),
    )) {
      return true;
    }
    return lecturer.courses.any(
      (course) =>
          course.code.toLowerCase().contains(query) ||
          course.title.toLowerCase().contains(query) ||
          course.chineseTitle.toLowerCase().contains(query),
    );
  }
}

String _departmentLabel(L10n strings, String name) {
  if (name.isEmpty) return strings.noDepartment;
  return name;
}

class _DepartmentSection extends StatelessWidget {
  const _DepartmentSection({
    required this.group,
    required this.strings,
    required this.open,
    required this.courseOpen,
    required this.onToggleSection,
    required this.onToggleCourse,
    required this.onOpenCourse,
  });

  final DepartmentGroup group;
  final L10n strings;
  final bool open;
  final Set<String> courseOpen;
  final VoidCallback onToggleSection;
  final ValueChanged<String> onToggleCourse;
  final ValueChanged<String> onOpenCourse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD7E0EA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DepartmentHeader(
              name: group.name,
              count: group.lecturers.length,
              strings: strings,
              open: open,
              onToggle: onToggleSection,
            ),
            if (open)
              for (final lecturer in group.lecturers)
                _LecturerTile(
                  lecturer: lecturer,
                  strings: strings,
                  open: courseOpen.contains(lecturer.name),
                  onToggle: () => onToggleCourse(lecturer.name),
                  onOpenCourse: onOpenCourse,
                ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentHeader extends StatelessWidget {
  const _DepartmentHeader({
    required this.name,
    required this.count,
    required this.strings,
    required this.open,
    required this.onToggle,
  });

  final String name;
  final int count;
  final L10n strings;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0C3C6E),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _departmentLabel(strings, name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strings.lecturerCount(count),
              style: const TextStyle(color: Color(0xFFD6E4F0), fontSize: 13),
            ),
            IconButton(
              tooltip: open ? strings.hideFilters : strings.showFilters,
              visualDensity: VisualDensity.compact,
              color: Colors.white,
              onPressed: onToggle,
              icon: Icon(
                open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepartmentDialog extends StatefulWidget {
  const _DepartmentDialog({
    required this.strings,
    required this.departments,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  final L10n strings;
  final List<String> departments;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  State<_DepartmentDialog> createState() => _DepartmentDialogState();
}

class _DepartmentDialogState extends State<_DepartmentDialog> {
  final _query = TextEditingController();
  late final Set<String> _selected = {...widget.selected};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.text.trim().toLowerCase();
    final shown = [
      for (final department in widget.departments)
        if (query.isEmpty ||
            _departmentLabel(
              widget.strings,
              department,
            ).toLowerCase().contains(query))
          department,
    ];
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.strings.departments,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.strings.departmentHelp,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _query,
                decoration: InputDecoration(
                  hintText: widget.strings.departmentHint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    for (final department in shown)
                      CheckboxListTile(
                        value: _selected.contains(department),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          _departmentLabel(widget.strings, department),
                        ),
                        onChanged: (_) {
                          setState(() {
                            if (!_selected.add(department)) {
                              _selected.remove(department);
                            }
                          });
                          widget.onToggle(department);
                        },
                      ),
                  ],
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

class _LecturerTile extends StatelessWidget {
  const _LecturerTile({
    required this.lecturer,
    required this.strings,
    required this.open,
    required this.onToggle,
    required this.onOpenCourse,
  });

  final Lecturer lecturer;
  final L10n strings;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<String> onOpenCourse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lecturer.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (lecturer.departments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                lecturer.departments.join(' · '),
                style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: open
                  ? const Color(0xFF0C3C6E)
                  : const Color(0xFFE7EEF5),
              foregroundColor: open ? Colors.white : const Color(0xFF0C3C6E),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onPressed: onToggle,
            icon: Icon(open ? Icons.expand_less : Icons.menu_book, size: 16),
            label: Text(
              '${open ? strings.hideTaughtCourses : strings.showTaughtCourses} · ${strings.lecturerCourses(lecturer.courseCount)}',
            ),
          ),
          if (open) ...[
            const SizedBox(height: 8),
            for (final course in lecturer.courses)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onOpenCourse(course.code),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.sectionId.isEmpty
                                ? course.code
                                : '${course.code} (${course.sectionId})',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(course.displayTitle(strings.zh)),
                          if (course.times.isNotEmpty)
                            Text(
                              course.times.join(' · '),
                              style: const TextStyle(
                                color: Color(0xFF667085),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
