import 'package:flutter/material.dart';

import '../l10n.dart';
import '../schedule.dart';

class TimetableMetrics {
  const TimetableMetrics({
    this.timeWidth = 72,
    this.dayWidth = 156,
    this.headerHeight = 42,
    this.hourHeight = 48,
  });

  static const gridStart = 8 * 60 + 30;
  static const gridEnd = 22 * 60 + 30;

  final double timeWidth;
  final double dayWidth;
  final double headerHeight;
  final double hourHeight;

  int get hourCount => (gridEnd - gridStart) ~/ 60;

  double widthFor(int dayCount) => timeWidth + dayCount * dayWidth;

  double get height => headerHeight + hourCount * hourHeight;

  /// On a phone, keep columns wide enough to read a course code and scroll the week.
  factory TimetableMetrics.forWidth(double maxWidth, int dayCount, {required bool compact}) {
    if (!compact || dayCount <= 0) return const TimetableMetrics();
    const timeWidth = 46.0;
    const minDayWidth = 96.0;
    final fitted = (maxWidth - timeWidth) / dayCount;
    return TimetableMetrics(
      timeWidth: timeWidth,
      dayWidth: fitted >= minDayWidth ? fitted : minDayWidth,
      headerHeight: 36,
      hourHeight: 42,
    );
  }
}

class TimetableGrid extends StatelessWidget {
  const TimetableGrid({
    super.key,
    required this.days,
    required this.blocks,
    required this.strings,
    required this.onBlockTap,
    this.metrics = const TimetableMetrics(),
  });

  final List<int> days;
  final List<GridBlock> blocks;
  final L10n strings;
  final ValueChanged<GridBlock> onBlockTap;
  final TimetableMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: metrics.widthFor(days.length),
      height: metrics.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                metrics: metrics,
                dayLabels: [for (final day in days) strings.dayShort(day)],
              ),
            ),
          ),
          for (final block in blocks)
            if (days.contains(block.meeting.weekday))
              _Block(block: block, days: days, metrics: metrics, onTap: () => onBlockTap(block)),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.block, required this.days, required this.metrics, required this.onTap});

  final GridBlock block;
  final List<int> days;
  final TimetableMetrics metrics;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayIndex = days.indexOf(block.meeting.weekday);
    final top =
        metrics.headerHeight + (block.meeting.startMinute - TimetableMetrics.gridStart) * metrics.hourHeight / 60;
    final rawHeight = (block.meeting.endMinute - block.meeting.startMinute) * metrics.hourHeight / 60;
    final laneWidth = metrics.dayWidth / block.laneCount;
    final left = metrics.timeWidth + dayIndex * metrics.dayWidth + block.lane * laneWidth;
    final venue = block.meeting.venue;
    final label = metrics.dayWidth < 120
        ? '${block.course.code}\n${block.section.id}'
        : '${block.course.code} (${block.section.id})';
    return Positioned(
      left: left + 1,
      top: top + 1,
      width: laneWidth - 2,
      height: rawHeight - 2,
      child: Material(
        color: block.conflict ? const Color(0xFFE7B3B0) : const Color(0xFF9BB6C9),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 3, 4, 2),
            child: Text(
              venue.isEmpty ? label : '$label\n$venue',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: rawHeight < 34 ? 10 : 12,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.metrics, required this.dayLabels});

  final TimetableMetrics metrics;
  final List<String> dayLabels;

  static const _line = Color(0xFFD0D0D0);
  static const _header = Color(0xFFF5B042);
  static const _font = 'NotoSansTC';

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, metrics.headerHeight),
      Paint()..color = _header,
    );

    final line = Paint()
      ..color = _line
      ..strokeWidth = 1;
    for (var hour = 0; hour <= metrics.hourCount; hour++) {
      final y = metrics.headerHeight + hour * metrics.hourHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    canvas.drawLine(Offset(metrics.timeWidth, 0), Offset(metrics.timeWidth, size.height), line);
    for (var day = 0; day <= dayLabels.length; day++) {
      final x = metrics.timeWidth + day * metrics.dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    canvas.drawRect(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _line,
    );

    for (var hour = 0; hour < metrics.hourCount; hour++) {
      final minutes = TimetableMetrics.gridStart + hour * 60;
      final label = '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: Colors.black, fontSize: metrics.timeWidth < 60 ? 11 : 13, fontFamily: _font),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: metrics.timeWidth - 6);
      painter.paint(
        canvas,
        Offset(4, metrics.headerHeight + hour * metrics.hourHeight + (metrics.hourHeight - painter.height) / 2),
      );
      painter.dispose();
    }

    for (var day = 0; day < dayLabels.length; day++) {
      final painter = TextPainter(
        text: TextSpan(
          text: dayLabels[day],
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: _font),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          metrics.timeWidth + day * metrics.dayWidth + (metrics.dayWidth - painter.width) / 2,
          (metrics.headerHeight - painter.height) / 2,
        ),
      );
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    if (oldDelegate.metrics != metrics) return true;
    if (oldDelegate.dayLabels.length != dayLabels.length) return true;
    for (var i = 0; i < dayLabels.length; i++) {
      if (oldDelegate.dayLabels[i] != dayLabels[i]) return true;
    }
    return false;
  }
}
