import 'package:flutter/material.dart';

import '../l10n.dart';
import '../schedule.dart';

class TimetableMetrics {
  const TimetableMetrics._();

  static const timeWidth = 72.0;
  static const dayWidth = 156.0;
  static const headerHeight = 42.0;
  static const hourHeight = 48.0;
  static const gridStart = 8 * 60 + 30;
  static const gridEnd = 22 * 60 + 30;

  static int get hourCount => (gridEnd - gridStart) ~/ 60;

  static double widthFor(int dayCount) => timeWidth + dayCount * dayWidth;

  static double get height => headerHeight + hourCount * hourHeight;
}

class TimetableGrid extends StatelessWidget {
  const TimetableGrid({
    super.key,
    required this.days,
    required this.blocks,
    required this.strings,
    required this.onBlockTap,
  });

  final List<int> days;
  final List<GridBlock> blocks;
  final L10n strings;
  final ValueChanged<GridBlock> onBlockTap;

  @override
  Widget build(BuildContext context) {
    final width = TimetableMetrics.widthFor(days.length);
    final height = TimetableMetrics.height;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(
                dayLabels: [for (final day in days) strings.dayShort(day)],
              ),
            ),
          ),
          for (final block in blocks)
            if (days.contains(block.meeting.weekday)) _Block(block: block, days: days, onTap: () => onBlockTap(block)),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.block, required this.days, required this.onTap});

  final GridBlock block;
  final List<int> days;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayIndex = days.indexOf(block.meeting.weekday);
    final top =
        TimetableMetrics.headerHeight +
        (block.meeting.startMinute - TimetableMetrics.gridStart) * TimetableMetrics.hourHeight / 60;
    final rawHeight = (block.meeting.endMinute - block.meeting.startMinute) * TimetableMetrics.hourHeight / 60;
    final laneWidth = TimetableMetrics.dayWidth / block.laneCount;
    final left = TimetableMetrics.timeWidth + dayIndex * TimetableMetrics.dayWidth + block.lane * laneWidth;
    final venue = block.meeting.venue;
    final label = '${block.course.code} (${block.section.id})';
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
  _GridPainter({required this.dayLabels});

  final List<String> dayLabels;

  static const _line = Color(0xFFD0D0D0);
  static const _header = Color(0xFFF5B042);
  static const _font = 'NotoSansTC';

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, TimetableMetrics.headerHeight),
      Paint()..color = _header,
    );

    final line = Paint()
      ..color = _line
      ..strokeWidth = 1;
    for (var hour = 0; hour <= TimetableMetrics.hourCount; hour++) {
      final y = TimetableMetrics.headerHeight + hour * TimetableMetrics.hourHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    canvas.drawLine(Offset(TimetableMetrics.timeWidth, 0), Offset(TimetableMetrics.timeWidth, size.height), line);
    for (var day = 0; day <= dayLabels.length; day++) {
      final x = TimetableMetrics.timeWidth + day * TimetableMetrics.dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    canvas.drawRect(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _line,
    );

    for (var hour = 0; hour < TimetableMetrics.hourCount; hour++) {
      final minutes = TimetableMetrics.gridStart + hour * 60;
      final label = '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.black, fontSize: 13, fontFamily: _font),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: TimetableMetrics.timeWidth - 8);
      painter.paint(
        canvas,
        Offset(8, TimetableMetrics.headerHeight + hour * TimetableMetrics.hourHeight + (TimetableMetrics.hourHeight - painter.height) / 2),
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
          TimetableMetrics.timeWidth + day * TimetableMetrics.dayWidth + (TimetableMetrics.dayWidth - painter.width) / 2,
          (TimetableMetrics.headerHeight - painter.height) / 2,
        ),
      );
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    if (oldDelegate.dayLabels.length != dayLabels.length) return true;
    for (var i = 0; i < dayLabels.length; i++) {
      if (oldDelegate.dayLabels[i] != dayLabels[i]) return true;
    }
    return false;
  }
}
