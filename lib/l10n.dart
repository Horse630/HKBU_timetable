class L10n {
  const L10n(this.code);

  final String code;

  bool get zh => code == 'zh';

  String get title => zh ? '浸大時間表' : 'HKBU Timetable';

  String get semester => zh ? '2026–27 年度第二學期' : 'Semester 2, 2026–27';

  String get credit => zh ? '由四年級計算機科學學生 Ma Chun Kit 製作' : 'Made by Ma Chun Kit, a Year 4 Computer Science student';

  String get creditEmail => '23230215@life.hkbu.edu.hk';

  String get searchHint => zh ? '搜尋科目編號或名稱' : 'Search code or title';

  String get add => zh ? '加入' : 'Add';

  String get remove => zh ? '移除' : 'Remove';

  String get download => zh ? '下載圖片' : 'Download PNG';

  String get saveToPhotos => zh ? '儲存到照片' : 'Save to Photos';

  String get saveImageHint => zh
      ? '長按圖片，然後點「加入照片」或「儲存圖片」。也可以按「儲存到照片」。'
      : 'Long-press the image, then tap Add to Photos or Save Image. You can also tap Save to Photos.';

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

  String get emptyHint => zh ? '選擇班別後，就會加到時間表。' : 'Choose a section to place it on the timetable.';

  String get coursesTab => zh ? '選科' : 'Courses';

  String get timetableTab => zh ? '時間表' : 'Timetable';

  String viewTimetable(int courses) {
    if (zh) return '查看時間表 · $courses 科';
    final label = courses == 1 ? 'course' : 'courses';
    return 'View timetable · $courses $label';
  }

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

  String get reviewsTitle => zh ? '同學評價' : 'Student reviews';

  String reviewCount(int count) {
    if (zh) return '共 $count 則';
    return count == 1 ? '1 review' : '$count reviews';
  }

  String get noReviews => zh ? '這科暫時沒有評價。' : 'No reviews for this course yet.';

  String get reviewsLoading => zh ? '正在載入評價…' : 'Loading reviews…';

  String get reviewsFailed => zh ? '評價暫時載入唔到。請重新整理頁面。' : 'Reviews could not be loaded. Refresh the page.';

  String get reviewsSource => zh
      ? '評價來自公開試算表。重新載入頁面後會看到新的意見。'
      : 'Reviews come from a public spreadsheet. Reload the page to see new comments.';

  String get recommendVote => 'Recommend｜推薦';

  String get notRecommendVote => 'Not Recommend｜不推薦';

  String recommendShare(int percent) => zh ? '推薦 $percent%' : 'Recommend $percent%';

  String get unknownVote => zh ? '未標明' : 'Unspecified';

  String otherVotes(int count) => zh ? '另有 $count 則未標明推薦或不推薦。' : '$count reviews did not choose recommend or not.';

  String showAllReviews(int count) => zh ? '顯示全部 $count 則' : 'Show all $count';

  String get showFewerReviews => zh ? '收起' : 'Show less';

  String get lecturerLabel => zh ? '講師' : 'Lecturer';

  String get commentLabel => zh ? '意見' : 'Comment';

  String get reviewCourse => zh ? '科目' : 'Course';

  String get notProvided => zh ? '未填' : 'Not filled in';

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
