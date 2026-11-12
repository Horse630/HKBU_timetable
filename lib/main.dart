import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'download.dart';
import 'key_value_store.dart';
import 'l10n.dart';
import 'models.dart';
import 'schedule.dart';
import 'storage.dart';
import 'widgets/course_browser.dart';
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
  final Map<String, String> _picks = {};
  final _search = TextEditingController();
  final _boardKey = GlobalKey();
  final _vertical = ScrollController();
  final _horizontal = ScrollController();
  var _query = '';
  var _expanded = '';
  var _downloading = false;

  L10n get strings => L10n(_lang);

  @override
  void initState() {
    super.initState();
    final saved = widget.store.getString('hkbu.lang');
    _lang = saved == 'en' || saved == 'zh' ? saved! : widget.store.preferredLanguage();
    _search.addListener(() {
      setState(() => _query = _search.text);
    });
    _load();
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
      saved.removeWhere((code, section) => catalog.byCode[code]?.sectionById(section) == null);
      setState(() {
        _catalog = catalog;
        _picks
          ..clear()
          ..addAll(saved);
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

  Map<String, String> _readPicks() {
    final raw = widget.store.getString('hkbu.picks');
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return {
        for (final item in list)
          if (item is Map && item['code'] is String && item['section'] is String)
            item['code'] as String: item['section'] as String,
      };
    } catch (_) {
      return {};
    }
  }

  void _savePicks() {
    final data = [for (final entry in _picks.entries) {'code': entry.key, 'section': entry.value}];
    widget.store.setString('hkbu.picks', jsonEncode(data));
  }

  void _setLanguage(String code) {
    setState(() => _lang = code);
    widget.store.setString('hkbu.lang', code);
  }

  void _toggleSection(Course course, Section section) {
    setState(() {
      if (_picks[course.code] == section.id) {
        _picks.remove(course.code);
      } else {
        _picks[course.code] = section.id;
      }
    });
    _savePicks();
  }

  void _remove(String code) {
    setState(() => _picks.remove(code));
    _savePicks();
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.clearTitle),
        content: Text(strings.clearBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.confirm)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(_picks.clear);
    _savePicks();
  }

  Future<void> _download() async {
    final boundary = _boardKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    setState(() => _downloading = true);
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('empty image');
      savePng(data.buffer.asUint8List(), 'hkbu-timetable.png');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.downloaded)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.downloadFailed)));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showBlock(GridBlock block) {
    final meeting = block.meeting;
    final venue = meeting.venue.isEmpty ? null : meeting.venue;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${block.course.code} (${block.section.id})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(block.course.displayTitle(strings.zh)),
            const SizedBox(height: 8),
            Text(strings.slot(strings.dayLong(meeting.weekday), meeting.start, meeting.end)),
            if (venue != null) Text(venue),
            if (block.section.instructors.isNotEmpty) Text('${strings.instructor}: ${block.section.instructors.join(', ')}'),
            if (block.section.medium.isNotEmpty) Text(strings.medium(block.section.medium)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(strings.close)),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _remove(block.course.code);
            },
            child: Text(strings.remove),
          ),
        ],
      ),
    );
  }

  List<Course> get _visible {
    final catalog = _catalog;
    if (catalog == null) return const [];
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return catalog.courses;
    return catalog.courses
        .where(
          (course) =>
              course.code.toLowerCase().contains(query) ||
              course.title.toLowerCase().contains(query) ||
              course.chineseTitle.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
                downloading: _downloading,
                canClear: _picks.isNotEmpty,
                onLanguage: _setLanguage,
                onDownload: _catalog == null ? null : _download,
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

    final blocks = layoutBlocks(_catalog!, _picks);
    final clashes = findClashes(blocks);
    final days = [1, 2, 3, 4, 5, 6, if (blocks.any((block) => block.meeting.weekday == 7)) 7];
    final browser = CourseBrowser(
      strings: strings,
      courses: _visible,
      picks: _picks,
      expandedCode: _expanded.isEmpty ? null : _expanded,
      search: _search,
      onExpand: (code) => setState(() => _expanded = code),
      onSection: _toggleSection,
      onOpenOutline: openExternal,
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
      onRemove: _remove,
      onBlockTap: _showBlock,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1040) {
          return Row(
            children: [
              SizedBox(width: 390, child: browser),
              const VerticalDivider(width: 1),
              Expanded(child: board),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(height: 340, child: browser),
            const Divider(height: 1),
            Expanded(child: board),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.strings,
    required this.downloading,
    required this.canClear,
    required this.onLanguage,
    required this.onDownload,
    required this.onClear,
  });

  final L10n strings;
  final bool downloading;
  final bool canClear;
  final ValueChanged<String> onLanguage;
  final VoidCallback? onDownload;
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
            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(strings.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                      Text(strings.semester, style: const TextStyle(color: Color(0xFFD6E4F0), fontSize: 13)),
                    ],
                  ),
                ),
                _LangSwitch(current: strings.code, onChanged: onLanguage),
                const SizedBox(width: 8),
                if (compact)
                  IconButton(
                    tooltip: strings.download,
                    onPressed: downloading ? null : onDownload,
                    icon: downloading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download, color: Colors.white),
                  )
                else
                  TextButton.icon(
                    onPressed: downloading ? null : onDownload,
                    icon: downloading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download, color: Colors.white),
                    label: Text(strings.download, style: const TextStyle(color: Colors.white)),
                  ),
                IconButton(
                  tooltip: strings.clear,
                  onPressed: canClear ? onClear : null,
                  icon: Icon(Icons.delete_outline, color: canClear ? Colors.white : Colors.white38),
                ),
              ],
            );
          },
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
      child: Row(
        children: [
          _button('EN', 'en'),
          _button('繁', 'zh'),
        ],
      ),
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
  });

  final L10n strings;
  final Map<String, String> picks;
  final Catalog catalog;
  final List<GridBlock> blocks;
  final List<Clash> clashes;
  final List<int> days;
  final GlobalKey boardKey;
  final ScrollController vertical;
  final ScrollController horizontal;
  final ValueChanged<String> onRemove;
  final ValueChanged<GridBlock> onBlockTap;

  @override
  Widget build(BuildContext context) {
    final entries = picks.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final units = entries.fold<double>(0, (sum, entry) => sum + (catalog.byCode[entry.key]?.units ?? 0));
    final unscheduled = [
      for (final entry in entries)
        if (catalog.byCode[entry.key]?.sectionById(entry.value)?.hasTime == false) '${entry.key} (${entry.value})',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (clashes.isNotEmpty)
          _Banner(
            color: const Color(0xFFFDECEC),
            border: const Color(0xFFE7B3B0),
            title: strings.clashTitle,
            lines: [for (final clash in clashes.take(4)) strings.clash(clash.left, clash.right, clash.weekday)],
          ),
        if (unscheduled.isNotEmpty)
          _Banner(
            color: const Color(0xFFFFF7E8),
            border: const Color(0xFFF5D48A),
            title: strings.unscheduledTitle,
            lines: unscheduled,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: entries.isEmpty
              ? Text(strings.emptyHint, style: const TextStyle(color: Color(0xFF475467)))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.count(entries.length, formatUnits(units)), style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in entries)
                          InputChip(
                            label: Text('${entry.key} (${entry.value})'),
                            deleteButtonTooltipMessage: strings.remove,
                            onDeleted: () => onRemove(entry.key),
                          ),
                      ],
                    ),
                  ],
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
                    notificationPredicate: (notification) => notification.metrics.axis == Axis.horizontal,
                    child: SingleChildScrollView(
                      controller: horizontal,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: RepaintBoundary(
                              key: boardKey,
                              child: ColoredBox(
                                color: Colors.white,
                                child: TimetableGrid(
                                  days: days,
                                  blocks: blocks,
                                  strings: strings,
                                  onBlockTap: onBlockTap,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(strings.venueNote, style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.border, required this.title, required this.lines});

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
