import 'package:flutter/material.dart';

import '../l10n.dart';
import '../schedule.dart';

class TimetableMetrics {
  const TimetableMetrics({
    this.timeWidth = 72,
    this.dayWidth = 156,
    this.headerHeight = 42,
    this.hourHeight = 48,
    this.fontScale = 1,
    this.polished = false,
  });

  static const gridStart = 8 * 60 + 30;
  static const gridEnd = 22 * 60 + 30;

  final double timeWidth;
  final double dayWidth;
  final double headerHeight;
  final double hourHeight;
  final double fontScale;

  /// Wallpaper drawing: navy header, quiet grid, rounded course blocks.
  final bool polished;

  int get hourCount => (gridEnd - gridStart) ~/ 60;

  double widthFor(int dayCount) => timeWidth + dayCount * dayWidth;

  double get height => headerHeight + hourCount * hourHeight;

  /// On a phone, keep columns wide enough to read a course code and scroll the week.
  factory TimetableMetrics.forWidth(
    double maxWidth,
    int dayCount, {
    required bool compact,
  }) {
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
    this.showTeachers = false,
    this.metrics = const TimetableMetrics(),
  });

  final List<int> days;
  final List<GridBlock> blocks;
  final L10n strings;
  final ValueChanged<GridBlock> onBlockTap;
  final bool showTeachers;
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
                dayLabels: [
                  for (final day in days)
                    metrics.polished
                        ? strings.dayMedium(day)
                        : strings.dayShort(day),
                ],
              ),
            ),
          ),
          for (final block in blocks)
            if (days.contains(block.meeting.weekday))
              _Block(
                block: block,
                days: days,
                metrics: metrics,
                showTeacher: showTeachers,
                onTap: () => onBlockTap(block),
              ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.block,
    required this.days,
    required this.metrics,
    required this.showTeacher,
    required this.onTap,
  });

  final GridBlock block;
  final List<int> days;
  final TimetableMetrics metrics;
  final bool showTeacher;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dayIndex = days.indexOf(block.meeting.weekday);
    final top =
        metrics.headerHeight +
        (block.meeting.startMinute - TimetableMetrics.gridStart) *
            metrics.hourHeight /
            60;
    final rawHeight =
        (block.meeting.endMinute - block.meeting.startMinute) *
        metrics.hourHeight /
        60;
    final laneWidth = metrics.dayWidth / block.laneCount;
    final left =
        metrics.timeWidth +
        dayIndex * metrics.dayWidth +
        block.lane * laneWidth;
    if (metrics.polished) {
      return _polishedBlock(
        left: left,
        top: top,
        laneWidth: laneWidth,
        rawHeight: rawHeight,
      );
    }
    final label = blockLabel(
      block,
      narrow: metrics.dayWidth < 120,
      showTeacher: showTeacher,
    );
    return Positioned(
      left: left + 1,
      top: top + 1,
      width: laneWidth - 2,
      height: rawHeight - 2,
      child: Material(
        color: block.conflict
            ? const Color(0xFFE7B3B0)
            : const Color(0xFF9BB6C9),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              4 * metrics.fontScale,
              3 * metrics.fontScale,
              4 * metrics.fontScale,
              2 * metrics.fontScale,
            ),
            child: Text(
              label,
              maxLines: showTeacher ? 6 : 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: (rawHeight < 34 ? 10 : 12) * metrics.fontScale,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _polishedBlock({
    required double left,
    required double top,
    required double laneWidth,
    required double rawHeight,
  }) {
    const insetX = 8.0;
    const insetY = 7.0;
    final width = laneWidth - insetX * 2;
    final height = rawHeight - insetY * 2;
    if (width < 12 || height < 12) return const SizedBox.shrink();
    final clash = block.conflict;
    final radius = (height * 0.14).clamp(14.0, 24.0);
    return Positioned(
      left: left + insetX,
      top: top + insetY,
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: clash ? const Color(0xFFF3D2CF) : const Color(0xFFB7D3E6),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: clash
                    ? const Color(0xFFB44741)
                    : const Color(0xFF0C3C6E),
                child: const SizedBox(width: 9),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: _FitLabel(block: block, showTeacher: showTeacher),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FitLabel extends StatelessWidget {
  const _FitLabel({required this.block, required this.showTeacher});

  final GridBlock block;
  final bool showTeacher;

  @override
  Widget build(BuildContext context) {
    final clash = block.conflict;
    final ink = clash ? const Color(0xFF4C221F) : const Color(0xFF10283F);
    final muted = clash ? const Color(0xFF6D3C38) : const Color(0xFF2C4C68);
    final spans = <InlineSpan>[];
    void add(String text, TextStyle style) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return;
      spans.add(
        TextSpan(text: spans.isEmpty ? trimmed : '\n$trimmed', style: style),
      );
    }

    final titleStyle = TextStyle(
      fontFamily: 'NotoSansTC',
      color: ink,
      fontSize: 20,
      height: 1.15,
      fontWeight: FontWeight.w700,
    );
    final subStyle = TextStyle(
      fontFamily: 'NotoSansTC',
      color: muted,
      fontSize: 18,
      height: 1.28,
      fontWeight: FontWeight.w400,
    );
    if (block.course.custom) {
      add(block.course.title, titleStyle);
      add(block.section.id, subStyle);
    } else {
      add(block.course.code, titleStyle);
      add(block.section.id, subStyle);
    }
    if (showTeacher) {
      for (final name in block.section.instructors) {
        add(name, subStyle);
      }
    }
    add(block.meeting.venue, subStyle);
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 6,
      overflow: TextOverflow.ellipsis,
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
    if (metrics.polished) {
      _paintPolished(canvas, size);
      return;
    }
    _paintPlain(canvas, size);
  }

  void _paintPolished(Canvas canvas, Size size) {
    const paper = Color(0xFFF4F7FB);
    const gutter = Color(0xFFE6EEF6);
    const band = Color(0xFFFFFFFF);
    const bandAlt = Color(0xFFF6F8FB);
    const rule = Color(0xFFD7E0EA);
    const navy = Color(0xFF0C3C6E);
    const gold = Color(0xFFF5B042);
    const timeInk = Color(0xFF536578);

    canvas.drawRect(Offset.zero & size, Paint()..color = paper);
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        metrics.headerHeight,
        metrics.timeWidth,
        size.height - metrics.headerHeight,
      ),
      Paint()..color = gutter,
    );
    for (var hour = 0; hour < metrics.hourCount; hour++) {
      canvas.drawRect(
        Rect.fromLTWH(
          metrics.timeWidth,
          metrics.headerHeight + hour * metrics.hourHeight,
          size.width - metrics.timeWidth,
          metrics.hourHeight,
        ),
        Paint()..color = hour.isEven ? band : bandAlt,
      );
    }

    final line = Paint()
      ..color = rule
      ..strokeWidth = 2;
    for (var hour = 0; hour <= metrics.hourCount; hour++) {
      final y = metrics.headerHeight + hour * metrics.hourHeight;
      canvas.drawLine(
        Offset(metrics.timeWidth, y),
        Offset(size.width, y),
        line,
      );
    }
    for (var day = 0; day <= dayLabels.length; day++) {
      final x = metrics.timeWidth + day * metrics.dayWidth;
      canvas.drawLine(
        Offset(x, metrics.headerHeight),
        Offset(x, size.height),
        line,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, metrics.headerHeight),
      Paint()..color = navy,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, metrics.headerHeight - 8, size.width, 8),
      Paint()..color = gold,
    );

    for (var hour = 0; hour < metrics.hourCount; hour++) {
      final minutes = TimetableMetrics.gridStart + hour * 60;
      final label =
          '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: timeInk,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            fontFamily: _font,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: metrics.timeWidth - 20);
      painter.paint(
        canvas,
        Offset(
          metrics.timeWidth - painter.width - 14,
          metrics.headerHeight + hour * metrics.hourHeight + 16,
        ),
      );
      painter.dispose();
    }

    for (var day = 0; day < dayLabels.length; day++) {
      final painter = TextPainter(
        text: TextSpan(
          text: dayLabels[day],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            fontFamily: _font,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: metrics.dayWidth - 8);
      painter.paint(
        canvas,
        Offset(
          metrics.timeWidth +
              day * metrics.dayWidth +
              (metrics.dayWidth - painter.width) / 2,
          (metrics.headerHeight - 8 - painter.height) / 2,
        ),
      );
      painter.dispose();
    }
  }

  void _paintPlain(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, metrics.headerHeight),
      Paint()..color = _header,
    );

    final line = Paint()
      ..color = _line
      ..strokeWidth = metrics.fontScale;
    for (var hour = 0; hour <= metrics.hourCount; hour++) {
      final y = metrics.headerHeight + hour * metrics.hourHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    canvas.drawLine(
      Offset(metrics.timeWidth, 0),
      Offset(metrics.timeWidth, size.height),
      line,
    );
    for (var day = 0; day <= dayLabels.length; day++) {
      final x = metrics.timeWidth + day * metrics.dayWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    canvas.drawRect(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = metrics.fontScale
        ..color = _line,
    );

    for (var hour = 0; hour < metrics.hourCount; hour++) {
      final minutes = TimetableMetrics.gridStart + hour * 60;
      final label =
          '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: Colors.black,
            fontSize: (metrics.timeWidth < 60 ? 11 : 13) * metrics.fontScale,
            fontFamily: _font,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: metrics.timeWidth - 6);
      painter.paint(
        canvas,
        Offset(
          4,
          metrics.headerHeight +
              hour * metrics.hourHeight +
              (metrics.hourHeight - painter.height) / 2,
        ),
      );
      painter.dispose();
    }

    for (var day = 0; day < dayLabels.length; day++) {
      final painter = TextPainter(
        text: TextSpan(
          text: dayLabels[day],
          style: TextStyle(
            color: Colors.black,
            fontSize: 16 * metrics.fontScale,
            fontWeight: FontWeight.w700,
            fontFamily: _font,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          metrics.timeWidth +
              day * metrics.dayWidth +
              (metrics.dayWidth - painter.width) / 2,
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
