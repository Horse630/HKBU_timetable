class L10n {
  const L10n(this.code);

  final String code;

  bool get zh => code == 'zh';

  String get title => zh ? '浸大時間表' : 'HKBU Timetable';

  String get semester => zh ? '2026–27 年度第二學期' : 'Semester 2, 2026–27';

  String get searchHint => zh ? '搜尋科目編號或名稱' : 'Search code or title';

  String get add => zh ? '加入' : 'Add';

  String get remove => zh ? '移除' : 'Remove';

  String get switchTo => zh ? '改選' : 'Switch';

  String get download => zh ? '下載圖片' : 'Download PNG';

  String get clear => zh ? '清除' : 'Clear';

  String get close => zh ? '關閉' : 'Close';

  String get cancel => zh ? '取消' : 'Cancel';

  String get confirm => zh ? '確定' : 'Clear';

  String courseMeta(String unitText, int count) {
    if (zh) return '$unitText 學分 · $count 班';
    final unitLabel = unitText == '1' ? 'unit' : 'units';
    final sectionLabel = count == 1 ? 'section' : 'sections';
    return '$unitText $unitLabel · $count $sectionLabel';
  }

  String get noResults => zh ? '找不到科目' : 'No courses found';

  String get loading => zh ? '正在載入課程…' : 'Loading courses…';

  String get loadError => zh ? '無法載入課程資料' : 'Could not load course data';

  String get emptyHint =>
      zh ? '在左邊選擇班別，就會加到時間表。' : 'Choose a section on the left to place it on the timetable.';

  String get selected => zh ? '已選科目' : 'Selected';

  String get clashTitle => zh ? '時間衝突' : 'Time clash';

  String get noTime => zh ? '這班未有上課時間，不會顯示在時間表上。' : 'This section has no class time, so it is not shown on the grid.';

  String get unscheduledTitle => zh ? '未有上課時間' : 'No class time';

  String get venueNote => zh
      ? '課室尚未公布。學校公布後，格子裡會顯示課室。'
      : 'Rooms have not been announced yet. They will appear in the grid when the university publishes them.';

  String get downloaded => zh ? '已下載時間表圖片' : 'Timetable image downloaded';

  String get downloadFailed => zh ? '下載失敗，請再試一次' : 'Download failed. Please try again.';

  String get clearTitle => zh ? '清除全部已選科目？' : 'Clear every selected course?';

  String get clearBody => zh ? '時間表會回復空白。' : 'The timetable will be empty.';

  String get outline => zh ? '課程大綱' : 'Outline';

  String get prerequisite => zh ? '先修' : 'Pre-req';

  String get corequisite => zh ? '共修' : 'Co-req';

  String get target => zh ? '修讀對象' : 'Target students';

  String get instructor => zh ? '講師' : 'Instructor';

  String get language => zh ? '語言' : 'Language';

  String count(int courses, String unitText) {
    if (zh) return '$courses 科 · $unitText 學分';
    final unitLabel = unitText == '1' ? 'unit' : 'units';
    return '$courses courses · $unitText $unitLabel';
  }

  String clash(String left, String right, int weekday) => zh
      ? '$left 與 $right 在${dayLong(weekday)}時間重疊'
      : '$left and $right overlap on ${dayLong(weekday)}';

  String dayShort(int weekday) {
    const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const zhs = ['一', '二', '三', '四', '五', '六', '日'];
    return zh ? zhs[weekday - 1] : en[weekday - 1];
  }

  String dayMedium(int weekday) => zh ? '週${dayShort(weekday)}' : dayShort(weekday);

  String dayLong(int weekday) {
    const en = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return zh ? '星期${dayShort(weekday)}' : en[weekday - 1];
  }

  String medium(String value) {
    if (!zh) return value;
    const names = {
      'English': '英語',
      'Putonghua': '普通話',
      'Cantonese': '粵語',
      'Japanese': '日語',
      'French': '法語',
      'German': '德語',
      'Spanish': '西班牙語',
      'English & Putonghua': '英語及普通話',
    };
    return names[value] ?? value;
  }

  String slot(String day, String start, String end) => '$day $start–$end';
}
