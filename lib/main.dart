import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'course_filter.dart';
import 'custom_class.dart';
import 'download.dart';
import 'key_value_store.dart';
import 'l10n.dart';
import 'widgets/lecturer_browser.dart';
import 'models.dart';
import 'reviews.dart';
import 'schedule.dart';
import 'storage.dart';
import 'widgets/course_browser.dart';
import 'widgets/custom_class_dialog.dart';
import 'visits.dart';
import 'wallpaper.dart';
import 'widgets/timetable_grid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TimetableApp(store: createStore()));
}

class TimetableApp extends StatefulWidget {
  const TimetableApp({super.key, required this.store});

  final KeyValueStore store;

  @override
  State<TimetableApp> createState() => _TimetableAppState();
}

class _TimetableAppState extends State<TimetableApp> {
  late String _lang;
  Catalog? _catalog;
  var _loading = true;
  String? _error;
  final Map<String, List<String>> _picks = {};
  final _search = TextEditingController();
  final _boardKey = GlobalKey();
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _vertical = ScrollController();
  final _horizontal = ScrollController();
  var _query = '';
  var _expanded = '';
  var _sortByRating = false;
  final Set<String> _subjects = {};
  final Set<int> _days = {};
  var _noExam = false;
  var _noTest = false;
  final List<CustomClass> _custom = [];
  var _showTeachers = false;
  var _exporting = '';

  /// 0 courses, 1 lecturers, 2 timetable.
  var _place = 0;
  ReviewBook? _reviews;
  var _reviewsFailed = false;

  L10n get strings => L10n(_lang);

  @override
  void initState() {
    super.initState();
    final saved = widget.store.getString('hkbu.lang');
    _lang = saved == 'en' || saved == 'zh'
        ? saved!
        : widget.store.preferredLanguage();
    _custom.addAll(CustomClass.decode(widget.store.getString('hkbu.custom')));
    _showTeachers = widget.store.getString('hkbu.showTeachers') == '1';
    _search.addListener(() {
      setState(() => _query = _search.text);
    });
    _load();
    _loadReviews();
  }

  @override
  void dispose() {
    _search.dispose();
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final catalog = await Catalog.load();
      if (!mounted) return;
      final saved = _readPicks();
      final cleaned = <String, List<String>>{};
      for (final entry in saved.entries) {
        final course = catalog.byCode[entry.key];
        if (course == null) continue;
        final ids = <String>{
          for (final id in entry.value)
            if (course.sectionById(id) != null) id,
        };
        if (ids.isEmpty) continue;
        cleaned[entry.key] = (ids.toList()..sort());
      }
      setState(() {
        _catalog = catalog;
        _picks
          ..clear()
          ..addAll(cleaned);
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = strings.loadError;
      });
    }
  }

  Future<void> _submitReview(ReviewDraft draft) async {
    await submitReview(draft);
    await Future<void>.delayed(const Duration(seconds: 3));
    await _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final book = await loadReviewBook();
      if (!mounted) return;
      setState(() {
        _reviews = book;
        _reviewsFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _reviewsFailed = true);
    }
  }

  Map<String, List<String>> _readPicks() {
    final raw = widget.store.getString('hkbu.picks');
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final result = <String, List<String>>{};
      for (final item in list) {
        if (item is! Map) continue;
        final code = item['code'];
        if (code is! String) continue;
        final ids = result.putIfAbsent(code, () => []);
        final sections = item['sections'];
        if (sections is List) {
          ids.addAll(sections.whereType<String>());
        } else if (item['section'] is String) {
          ids.add(item['section'] as String);
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  void _savePicks() {
    final data = [
      for (final entry in _picks.entries)
        {'code': entry.key, 'sections': entry.value},
    ];
    widget.store.setString('hkbu.picks', jsonEncode(data));
  }

  void _saveCustom() {
    widget.store.setString(
      'hkbu.custom',
      jsonEncode([for (final item in _custom) item.toJson()]),
    );
  }

  void _toggleTeachers() {
    setState(() => _showTeachers = !_showTeachers);
    widget.store.setString('hkbu.showTeachers', _showTeachers ? '1' : '0');
  }

  Future<void> _addCustom() async {
    final pageContext = _pageContext;
    if (pageContext == null) return;
    final created = await showCustomClassDialog(pageContext, strings);
    if (created == null || !mounted) return;
    setState(() {
      _custom.add(created);
      _place = 2;
    });
    _saveCustom();
  }

  void _removeCustom(String id) {
    setState(() => _custom.removeWhere((item) => item.id == id));
    _saveCustom();
  }

  void _setLanguage(String code) {
    setState(() => _lang = code);
    widget.store.setString('hkbu.lang', code);
  }

  void _toggleSection(Course course, Section section) {
    setState(() {
      final current = List<String>.from(_picks[course.code] ?? const []);
      if (current.contains(section.id)) {
        current.remove(section.id);
      } else {
        current.add(section.id);
        current.sort();
      }
      if (current.isEmpty) {
        _picks.remove(course.code);
      } else {
        _picks[course.code] = current;
      }
    });
    _savePicks();
  }

  void _removeSection(String code, String sectionId) {
    setState(() {
      final current = List<String>.from(_picks[code] ?? const []);
      current.remove(sectionId);
      if (current.isEmpty) {
        _picks.remove(code);
      } else {
        _picks[code] = current;
      }
    });
    _savePicks();
  }

  BuildContext? get _pageContext =>
      _navigatorKey.currentState?.overlay?.context;

  Future<void> _clear() async {
    final pageContext = _pageContext;
    if (pageContext == null) return;
    final confirmed = await showDialog<bool>(
      context: pageContext,
      builder: (context) => AlertDialog(
        title: Text(strings.clearTitle),
        content: Text(strings.clearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.clear),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _picks.clear();
      _custom.clear();
      _place = 0;
    });
    _savePicks();
    _saveCustom();
  }

  Future<void> _download() async {
    await _export(wallpaper: false);
  }

  Future<void> _downloadWallpaper() async {
    await _export(wallpaper: true);
  }

  Future<void> _export({required bool wallpaper}) async {
    final boundary = _boardKey.currentContext?.findRenderObject();
    if ((!wallpaper && boundary is! RenderRepaintBoundary) || !mounted) return;
    setState(() => _exporting = wallpaper ? 'wallpaper' : 'png');
    try {
      final bytes = wallpaper
          ? await _captureWallpaper()
          : await _encodePng(
              await _captureImage(boundary! as RenderRepaintBoundary),
            );
      final filename = wallpaper
          ? wallpaperPngName(DateTime.now())
          : timetablePngName(DateTime.now());
      if (!mounted) return;
      if (savesPngWithShareSheet) {
        presentPng(
          bytes,
          filename,
          hint: strings.saveImageHint,
          saveLabel: strings.saveToPhotos,
          closeLabel: strings.close,
        );
      } else {
        savePng(bytes, filename);
        _showMessage(wallpaper ? strings.wallpaperSaved : strings.downloaded);
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage(strings.downloadFailed);
    } finally {
      if (mounted) setState(() => _exporting = '');
    }
  }

  void _showMessage(String message) {
    final pageContext = _pageContext;
    if (pageContext == null) return;
    ScaffoldMessenger.of(pageContext)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<ui.Image> _captureImage(RenderRepaintBoundary boundary) async {
    final shortSide = MediaQuery.sizeOf(context).shortestSide;
    final ratios = shortSide < 700 ? const [2.0, 1.0] : const [3.0, 2.0, 1.0];
    Object? lastError;
    for (final ratio in ratios) {
      try {
        return await boundary.toImage(pixelRatio: ratio);
      } catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? StateError('empty image');
  }

  Future<Uint8List> _captureWallpaper() async {
    final catalog = _catalog;
    final overlay = _navigatorKey.currentState?.overlay;
    if (catalog == null || overlay == null) throw StateError('no timetable');
    final blocks = layoutBlocks(
      catalog,
      _picks,
      extras: [for (final item in _custom) item.toCourse()],
    );
    final days = [
      1,
      2,
      3,
      4,
      5,
      6,
      if (blocks.any((block) => block.meeting.weekday == 7)) 7,
    ];
    final metrics = wallpaperMetrics(days.length);
    final key = GlobalKey();
    final width = metrics.widthFor(days.length);
    final height = metrics.height;
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        top: 0,
        child: IgnorePointer(
          child: SizedBox(
            width: 1,
            height: 1,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: width,
                maxWidth: width,
                minHeight: height,
                maxHeight: height,
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: TimetableGrid(
                      days: days,
                      blocks: blocks,
                      strings: strings,
                      metrics: metrics,
                      showTeachers: _showTeachers,
                      onBlockTap: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      final boundary = key.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary)
        throw StateError('wallpaper not ready');
      return await _encodePng(await boundary.toImage(pixelRatio: 1));
    } finally {
      entry.remove();
    }
  }

  Future<Uint8List> _encodePng(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null || data.lengthInBytes == 0)
      throw StateError('empty image');
    return data.buffer.asUint8List();
  }

  void _focusCourse(GridBlock block) {
    if (block.course.custom) return;
    _showCourse(block.course.code);
  }

  void _showCourse(String code) {
    _search.value = TextEditingValue(
      text: code,
      selection: TextSelection.collapsed(offset: code.length),
    );
    setState(() {
      _subjects.clear();
      _days.clear();
      _noExam = false;
      _noTest = false;
      _expanded = code;
      _place = 0;
    });
  }

  void _toggleNoExam() => setState(() => _noExam = !_noExam);

  void _toggleNoTest() => setState(() => _noTest = !_noTest);

  void _toggleDay(int day) {
    setState(() {
      if (!_days.add(day)) _days.remove(day);
    });
  }

  void _toggleSubject(String subject) {
    setState(() {
      if (!_subjects.add(subject)) _subjects.remove(subject);
    });
  }

  List<String> get _allSubjects {
    final catalog = _catalog;
    if (catalog == null) return const [];
    return {for (final course in catalog.courses) subjectOf(course.code)}
        .toList()
      ..sort();
  }

  List<Course> get _visible {
    final catalog = _catalog;
    if (catalog == null) return const [];
    return visibleCourses(
      courses: catalog.courses,
      query: _query,
      subjects: _subjects,
      days: _days,
      sortByRating: _sortByRating,
      noExam: _noExam,
      noTest: _noTest,
      reviews: _reviews,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: strings.title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'NotoSansTC',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C3C6E)),
        scaffoldBackgroundColor: const Color(0xFFF3F5F7),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Header(
                strings: strings,
                exporting: _exporting,
                canClear: _picks.isNotEmpty || _custom.isNotEmpty,
                onLanguage: _setLanguage,
                onDownload: _catalog == null ? null : _download,
                onWallpaper: _catalog == null ? null : _downloadWallpaper,
                onClear: _clear,
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(strings.loading),
          ],
        ),
      );
    }
    if (_error != null || _catalog == null) {
      return Center(child: Text(_error ?? strings.loadError));
    }

    final blocks = layoutBlocks(
      _catalog!,
      _picks,
      extras: [for (final item in _custom) item.toCourse()],
    );
    final clashes = findClashes(blocks);
    final days = [
      1,
      2,
      3,
      4,
      5,
      6,
      if (blocks.any((block) => block.meeting.weekday == 7)) 7,
    ];
    final browser = CourseBrowser(
      strings: strings,
      courses: _visible,
      picks: _picks,
      expandedCode: _expanded.isEmpty ? null : _expanded,
      search: _search,
      sortByRating: _sortByRating,
      subjects: _allSubjects,
      selectedSubjects: _subjects,
      selectedDays: _days,
      noExam: _noExam,
      noTest: _noTest,
      onToggleNoExam: _toggleNoExam,
      onToggleNoTest: _toggleNoTest,
      onToggleDay: _toggleDay,
      onToggleSort: () => setState(() => _sortByRating = !_sortByRating),
      onToggleSubject: _toggleSubject,
      onClearSubjects: () => setState(_subjects.clear),
      reviews: _reviews,
      reviewsFailed: _reviewsFailed,
      onSubmitReview: _submitReview,
      onExpand: (code) => setState(() => _expanded = code),
      onSection: _toggleSection,
      onOpenOutline: openExternal,
      onAddCustom: _addCustom,
    );
    final board = _Board(
      strings: strings,
      picks: _picks,
      catalog: _catalog!,
      blocks: blocks,
      clashes: clashes,
      days: days,
      boardKey: _boardKey,
      vertical: _vertical,
      horizontal: _horizontal,
      onRemove: _removeSection,
      onBlockTap: _focusCourse,
      customs: _custom,
      onRemoveCustom: _removeCustom,
      showTeachers: _showTeachers,
      onToggleTeachers: _toggleTeachers,
      onAddCustom: _addCustom,
    );
    final lecturers = LecturerBrowser(strings: strings, onCourse: _showCourse);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1040) {
          return Row(
            children: [
              SizedBox(
                width: 390,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: _ViewSwitch(
                        labels: [strings.coursesTab, strings.lecturersTab],
                        selected: _place == 1 ? 1 : 0,
                        onChanged: (index) => setState(() => _place = index),
                      ),
                    ),
                    Expanded(child: _place == 1 ? lecturers : browser),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: board),
            ],
          );
        }
        final courseCount = _picks.length + _custom.length;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: _ViewSwitch(
                labels: [
                  strings.coursesTab,
                  strings.lecturersTab,
                  courseCount == 0
                      ? strings.timetableTab
                      : '${strings.timetableTab} · $courseCount',
                ],
                selected: _place,
                onChanged: (index) => setState(() => _place = index),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _place,
                sizing: StackFit.expand,
                children: [browser, lecturers, board],
              ),
            ),
            if (_place == 0 && courseCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0C3C6E),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () => setState(() => _place = 2),
                  child: Text(strings.viewTimetable(courseCount)),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _VisitCount extends StatefulWidget {
  const _VisitCount({required this.strings});

  final L10n strings;

  @override
  State<_VisitCount> createState() => _VisitCountState();
}

class _VisitCountState extends State<_VisitCount> {
  var _count = visitBase;

  @override
  void initState() {
    super.initState();
    loadVisitCount().then((count) {
      if (mounted) setState(() => _count = count);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.strings.visits(formatVisitCount(_count)),
      style: const TextStyle(
        color: Color(0xFFD6E4F0),
        fontSize: 12,
        height: 1.3,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.strings,
    required this.exporting,
    required this.canClear,
    required this.onLanguage,
    required this.onDownload,
    required this.onWallpaper,
    required this.onClear,
  });

  final L10n strings;
  final String exporting;
  final bool canClear;
  final ValueChanged<String> onLanguage;
  final VoidCallback? onDownload;
  final VoidCallback? onWallpaper;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0C3C6E),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final busy = exporting.isNotEmpty;
            final credit = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.credit,
                  style: const TextStyle(
                    color: Color(0xFFD6E4F0),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () => openExternal(strings.creditInstagramUrl),
                  child: Text(
                    strings.creditInstagram,
                    style: const TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                _VisitCount(strings: strings),
              ],
            );
            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LangSwitch(current: strings.code, onChanged: onLanguage),
                const SizedBox(width: 4),
                if (compact) ...[
                  IconButton(
                    tooltip: strings.download,
                    visualDensity: VisualDensity.compact,
                    onPressed: busy ? null : onDownload,
                    icon: exporting == 'png'
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download, color: Colors.white),
                  ),
                  IconButton(
                    tooltip: strings.wallpaper,
                    visualDensity: VisualDensity.compact,
                    onPressed: busy ? null : onWallpaper,
                    icon: exporting == 'wallpaper'
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.wallpaper, color: Colors.white),
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: busy ? null : onDownload,
                    icon: exporting == 'png'
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download, color: Colors.white),
                    label: Text(
                      strings.download,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : onWallpaper,
                    icon: exporting == 'wallpaper'
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.wallpaper, color: Colors.white),
                    label: Text(
                      strings.wallpaper,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
                IconButton(
                  tooltip: strings.clear,
                  visualDensity: compact
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  onPressed: canClear ? onClear : null,
                  icon: Icon(
                    Icons.delete_outline,
                    color: canClear ? Colors.white : Colors.white38,
                  ),
                ),
              ],
            );
            if (!compact) {
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          strings.semester,
                          style: const TextStyle(
                            color: Color(0xFFD6E4F0),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        credit,
                      ],
                    ),
                  ),
                  actions,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    actions,
                  ],
                ),
                Text(
                  strings.semester,
                  style: const TextStyle(
                    color: Color(0xFFD6E4F0),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                credit,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE7EEF5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            _tab(labels[index], index == selected, () => onChanged(index)),
        ],
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: selected ? Colors.white : const Color(0xFF0C3C6E),
            backgroundColor: selected
                ? const Color(0xFF0C3C6E)
                : Colors.transparent,
            minimumSize: const Size.fromHeight(36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _LangSwitch extends StatelessWidget {
  const _LangSwitch({required this.current, required this.onChanged});

  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [_button('EN', 'en'), _button('繁', 'zh')]),
    );
  }

  Widget _button(String label, String code) {
    final selected = current == code;
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: selected ? const Color(0xFF0C3C6E) : Colors.white,
        backgroundColor: selected ? Colors.white : Colors.transparent,
        minimumSize: const Size(40, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => onChanged(code),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({
    required this.strings,
    required this.picks,
    required this.catalog,
    required this.blocks,
    required this.clashes,
    required this.days,
    required this.boardKey,
    required this.vertical,
    required this.horizontal,
    required this.onRemove,
    required this.onBlockTap,
    required this.customs,
    required this.onRemoveCustom,
    required this.showTeachers,
    required this.onToggleTeachers,
    required this.onAddCustom,
  });

  final L10n strings;
  final Map<String, List<String>> picks;
  final Catalog catalog;
  final List<GridBlock> blocks;
  final List<Clash> clashes;
  final List<int> days;
  final GlobalKey boardKey;
  final ScrollController vertical;
  final ScrollController horizontal;
  final void Function(String code, String sectionId) onRemove;
  final ValueChanged<GridBlock> onBlockTap;
  final List<CustomClass> customs;
  final ValueChanged<String> onRemoveCustom;
  final bool showTeachers;
  final VoidCallback onToggleTeachers;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    final entries = picks.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final units = entries.fold<double>(
      0,
      (sum, entry) => sum + (catalog.byCode[entry.key]?.units ?? 0),
    );
    final unscheduled = [
      for (final entry in entries)
        for (final id in entry.value)
          if (catalog.byCode[entry.key]?.sectionById(id)?.hasTime == false)
            '${entry.key} ($id)',
    ];

    final compact = MediaQuery.sizeOf(context).width < 1040;
    final chips = <Widget>[
      for (final entry in entries)
        for (final sectionId in entry.value)
          InputChip(
            label: Text('${entry.key} ($sectionId)'),
            visualDensity: compact
                ? VisualDensity.compact
                : VisualDensity.standard,
            deleteButtonTooltipMessage: strings.remove,
            onDeleted: () => onRemove(entry.key, sectionId),
          ),
      for (final item in customs)
        InputChip(
          label: Text(
            item.section.trim().isEmpty
                ? item.title
                : '${item.title} (${item.section})',
          ),
          visualDensity: compact
              ? VisualDensity.compact
              : VisualDensity.standard,
          deleteButtonTooltipMessage: strings.remove,
          onDeleted: () => onRemoveCustom(item.id),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (clashes.isNotEmpty)
          _Banner(
            color: const Color(0xFFFDECEC),
            border: const Color(0xFFE7B3B0),
            title: strings.clashTitle,
            lines: [
              for (final clash in clashes.take(4))
                strings.clash(clash.left, clash.right, clash.weekday),
            ],
          ),
        if (unscheduled.isNotEmpty)
          _Banner(
            color: const Color(0xFFFFF7E8),
            border: const Color(0xFFF5D48A),
            title: strings.unscheduledTitle,
            lines: unscheduled,
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            8,
            compact ? 12 : 16,
            0,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: showTeachers
                      ? const Color(0xFF0C3C6E)
                      : const Color(0xFFE7EEF5),
                  foregroundColor: showTeachers
                      ? Colors.white
                      : const Color(0xFF0C3C6E),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                onPressed: onToggleTeachers,
                icon: const Icon(Icons.person_outline, size: 18),
                label: Text(strings.showTeacher),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: const Color(0xFFE7EEF5),
                  foregroundColor: const Color(0xFF0C3C6E),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                onPressed: onAddCustom,
                icon: const Icon(Icons.add, size: 18),
                label: Text(strings.addOwnClass),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            8,
            compact ? 12 : 16,
            0,
          ),
          child: chips.isEmpty
              ? Text(
                  strings.emptyHint,
                  style: const TextStyle(color: Color(0xFF475467)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.count(
                        entries.length + customs.length,
                        formatUnits(units),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (compact)
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final chip in chips)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: chip,
                              ),
                          ],
                        ),
                      )
                    else
                      Wrap(spacing: 8, runSpacing: 8, children: chips),
                  ],
                ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            8,
            compact ? 12 : 16,
            0,
          ),
          child: Text(
            strings.venueNote,
            style: const TextStyle(color: Color(0xFF667085), fontSize: 12),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Scrollbar(
                controller: vertical,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: vertical,
                  child: Scrollbar(
                    controller: horizontal,
                    thumbVisibility: true,
                    notificationPredicate: (notification) =>
                        notification.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: horizontal,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 8 : 16,
                              8,
                              compact ? 8 : 16,
                              8,
                            ),
                            child: RepaintBoundary(
                              key: boardKey,
                              child: ColoredBox(
                                color: Colors.white,
                                child: TimetableGrid(
                                  days: days,
                                  blocks: blocks,
                                  strings: strings,
                                  metrics: TimetableMetrics.forWidth(
                                    constraints.maxWidth - (compact ? 16 : 32),
                                    days.length,
                                    compact: compact,
                                  ),
                                  onBlockTap: onBlockTap,
                                  showTeachers: showTeachers,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.border,
    required this.title,
    required this.lines,
  });

  final Color color;
  final Color border;
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          for (final line in lines) Text(line),
        ],
      ),
    );
  }
}
