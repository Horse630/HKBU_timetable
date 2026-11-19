import 'widgets/timetable_grid.dart';

/// Phone wallpaper, 20:9. The picture is only the timetable grid.
const wallpaperWidth = 1080.0;
const wallpaperHeight = 2400.0;

String wallpaperPngName(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return 'hkbu-wallpaper-${time.year}-${two(time.month)}-${two(time.day)}-${two(time.hour)}${two(time.minute)}.png';
}

/// Sizes the week so it fills a 1080×2400 image, with nothing around it.
TimetableMetrics wallpaperMetrics(int dayCount) {
  final days = dayCount < 1 ? 6 : dayCount;
  const timeWidth = 132.0;
  const headerHeight = 118.0;
  const hourHeight = 163.0;
  return TimetableMetrics(
    timeWidth: timeWidth,
    dayWidth: (wallpaperWidth - timeWidth) / days,
    headerHeight: headerHeight,
    hourHeight: hourHeight,
    polished: true,
  );
}
