import 'package:flutter/material.dart';

import '../custom_class.dart';
import '../l10n.dart';

Future<CustomClass?> showCustomClassDialog(BuildContext context, L10n strings) {
  return showDialog<CustomClass>(
    context: context,
    builder: (context) => _CustomClassDialog(strings: strings),
  );
}

class _CustomClassDialog extends StatefulWidget {
  const _CustomClassDialog({required this.strings});

  final L10n strings;

  @override
  State<_CustomClassDialog> createState() => _CustomClassDialogState();
}

class _CustomClassDialogState extends State<_CustomClassDialog> {
  final _title = TextEditingController();
  final _section = TextEditingController();
  final _teacher = TextEditingController();
  final _times = customTimeOptions();
  var _day = 1;
  var _start = '09:30';
  var _end = '11:20';
  var _invalid = false;

  @override
  void dispose() {
    _title.dispose();
    _section.dispose();
    _teacher.dispose();
    super.dispose();
  }

  void _changeStart(String? value) {
    if (value == null) return;
    setState(() {
      _start = value;
      if (!_times.contains(_end) || _times.indexOf(_end) <= _times.indexOf(_start)) {
        final next = _times.indexOf(_start) + 1;
        if (next < _times.length) _end = _times[next];
      }
    });
  }

  void _save() {
    final title = _title.text.trim();
    final startIndex = _times.indexOf(_start);
    final endIndex = _times.indexOf(_end);
    if (title.isEmpty || endIndex <= startIndex) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(
      context,
      CustomClass(
        id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
        title: title,
        section: _section.text.trim(),
        weekday: _day,
        start: _start,
        end: _end,
        teacher: _teacher.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return AlertDialog(
      title: Text(strings.ownClassTitle),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: strings.courseTitleField, border: const OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _section,
                decoration: InputDecoration(labelText: strings.sectionOptional, border: const OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _day,
                decoration: InputDecoration(labelText: strings.timeSlot, border: const OutlineInputBorder(), isDense: true),
                items: [
                  for (final day in const [1, 2, 3, 4, 5, 6])
                    DropdownMenuItem(value: day, child: Text(strings.dayMedium(day))),
                ],
                onChanged: (value) => setState(() => _day = value ?? _day),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _start,
                      decoration: InputDecoration(labelText: strings.startTime, border: const OutlineInputBorder(), isDense: true),
                      items: [for (final time in _times) DropdownMenuItem(value: time, child: Text(time))],
                      onChanged: _changeStart,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _end,
                      decoration: InputDecoration(labelText: strings.endTime, border: const OutlineInputBorder(), isDense: true),
                      items: [for (final time in _times) DropdownMenuItem(value: time, child: Text(time))],
                      onChanged: (value) => setState(() => _end = value ?? _end),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _teacher,
                decoration: InputDecoration(labelText: strings.teacherOptional, border: const OutlineInputBorder(), isDense: true),
              ),
              if (_invalid) ...[
                const SizedBox(height: 8),
                Text(strings.ownClassRequired, style: const TextStyle(color: Color(0xFFB42318), fontSize: 12, height: 1.35)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(strings.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0C3C6E)),
          onPressed: _save,
          child: Text(strings.addToTimetable),
        ),
      ],
    );
  }
}
