import 'reviews_fetch_stub.dart' if (dart.library.html) 'reviews_fetch_web.dart' as reviews_fetch;

const reviewSheetCsvUrl =
    'https://docs.google.com/spreadsheets/d/1B7BvLKzICgBnusgDYfi0BGWnxypEjLL89k_SXT8D6yU/export?format=csv&gid=1117900362';

const reviewFormResponseUrl =
    'https://docs.google.com/forms/d/e/1FAIpQLSfmmEvZT7l2RZzD_Y1tIIVEasAL_p3QVkuLb-_FKe_2SKiLMQ/formResponse';

const recommendVerdict = 'Recommend｜推薦';
const notRecommendVerdict = 'Not Recommend｜不推薦';

enum ReviewVote { recommend, notRecommend, unknown }

class CourseReview {
  const CourseReview({
    required this.timestamp,
    required this.time,
    required this.code,
    required this.title,
    required this.lecturer,
    required this.verdict,
    required this.vote,
    required this.comment,
  });

  final String timestamp;
  final DateTime? time;
  final String code;
  final String title;
  final String lecturer;
  final String verdict;
  final ReviewVote vote;
  final String comment;

  bool get recommend => vote == ReviewVote.recommend;
}

class ReviewTally {
  const ReviewTally({required this.recommend, required this.notRecommend, required this.unknown});

  final int recommend;
  final int notRecommend;
  final int unknown;

  int get total => recommend + notRecommend + unknown;

  int get rated => recommend + notRecommend;

  int get recommendPercent => rated == 0 ? 0 : (recommend * 100 / rated).round();

  int get notRecommendPercent => rated == 0 ? 0 : 100 - recommendPercent;
}

class ReviewBook {
  ReviewBook(Map<String, List<CourseReview>> byCode) : byCode = Map.unmodifiable(byCode);

  final Map<String, List<CourseReview>> byCode;

  List<CourseReview> of(String code) => byCode[normalizeCourseCode(code)] ?? const [];

  ReviewTally tally(String code) {
    final rows = of(code);
    var recommend = 0;
    var notRecommend = 0;
    var unknown = 0;
    for (final row in rows) {
      switch (row.vote) {
        case ReviewVote.recommend:
          recommend++;
        case ReviewVote.notRecommend:
          notRecommend++;
        case ReviewVote.unknown:
          unknown++;
      }
    }
    return ReviewTally(recommend: recommend, notRecommend: notRecommend, unknown: unknown);
  }

  static ReviewBook parse(String csv) {
    final table = parseCsv(csv);
    if (table.isEmpty) return ReviewBook({});
    final header = [for (final cell in table.first) _headerKey(cell)];
    final timestamp = header.indexOf('timestamp');
    final code = header.indexOf('course code');
    final title = header.indexOf('course title');
    final lecturer = header.indexOf('tutor / lecturer');
    final verdict = header.indexOf("reg / don't reg ?");
    final comment = header.indexOf('comment / reason');
    if (code < 0 || verdict < 0) {
      throw const FormatException('Review sheet is missing Course Code or the recommendation column.');
    }

    final grouped = <String, List<CourseReview>>{};
    for (final row in table.skip(1)) {
      final rawCode = _cell(row, code);
      final normalized = normalizeCourseCode(rawCode);
      if (normalized.isEmpty) continue;
      final review = CourseReview(
        timestamp: _cell(row, timestamp),
        time: parseSheetTime(_cell(row, timestamp)),
        code: rawCode,
        title: _cell(row, title),
        lecturer: _cell(row, lecturer),
        verdict: _cell(row, verdict),
        vote: voteOf(_cell(row, verdict)),
        comment: _cell(row, comment),
      );
      (grouped[normalized] ??= []).add(review);
    }
    for (final rows in grouped.values) {
      rows.sort((a, b) {
        final left = a.time;
        final right = b.time;
        if (left == null && right == null) return 0;
        if (left == null) return 1;
        if (right == null) return -1;
        return right.compareTo(left);
      });
    }
    return ReviewBook(grouped);
  }
}

class ReviewDraft {
  const ReviewDraft({
    required this.code,
    required this.title,
    required this.lecturer,
    required this.vote,
    required this.comment,
  });

  final String code;
  final String title;
  final String lecturer;
  final ReviewVote vote;
  final String comment;

  Map<String, String> formFields() {
    return {
      'entry.875515428': normalizeCourseCode(code),
      'entry.20836144': title.trim(),
      'entry.1002790793': lecturer.trim(),
      'entry.1026089525': vote == ReviewVote.recommend ? recommendVerdict : notRecommendVerdict,
      'entry.452007492': comment.trim(),
      'fvv': '1',
      'pageHistory': '0',
    };
  }
}

Future<ReviewBook> loadReviewBook() async {
  final url = '$reviewSheetCsvUrl&cb=${DateTime.now().millisecondsSinceEpoch}';
  final csv = await reviews_fetch.fetchReviewsCsv(url);
  return ReviewBook.parse(csv);
}

Future<void> submitReview(ReviewDraft draft) {
  final fields = draft.formFields();
  if (fields['entry.875515428']!.isEmpty || fields['entry.452007492']!.isEmpty || draft.vote == ReviewVote.unknown) {
    throw ArgumentError('A review needs a course code, a recommendation, and a comment.');
  }
  return reviews_fetch.submitReviewForm(reviewFormResponseUrl, fields);
}

String normalizeCourseCode(String value) => value.replaceAll(RegExp(r'\s+'), '').toUpperCase();

ReviewVote voteOf(String raw) {
  final text = raw.trim().toLowerCase();
  if (text.isEmpty) return ReviewVote.unknown;
  if (text.contains('not recommend') || text.contains('不推薦') || text.contains("don't reg") || text.contains('dont reg')) {
    return ReviewVote.notRecommend;
  }
  if (text.contains('recommend') || text.contains('推薦')) return ReviewVote.recommend;
  return ReviewVote.unknown;
}

DateTime? parseSheetTime(String raw) {
  final text = raw.trim();
  final match = RegExp(r'^(\d{4})/(\d{1,2})/(\d{1,2})\s+(上午|下午|AM|PM)\s+(\d{1,2}):(\d{2}):(\d{2})$', caseSensitive: false)
      .firstMatch(text);
  if (match == null) return null;
  var hour = int.parse(match.group(5)!);
  final marker = match.group(4)!.toUpperCase();
  final afternoon = marker == '下午' || marker == 'PM';
  if (afternoon && hour < 12) hour += 12;
  if (!afternoon && hour == 12) hour = 0;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
    hour,
    int.parse(match.group(6)!),
    int.parse(match.group(7)!),
  );
}

List<List<String>> parseCsv(String input) {
  var source = input;
  if (source.startsWith('\uFEFF')) source = source.substring(1);
  final rows = <List<String>>[];
  final row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < source.length; i++) {
    final char = source[i];
    if (quoted) {
      if (char == '"') {
        if (i + 1 < source.length && source[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(char);
      }
      continue;
    }
    if (char == '"') {
      quoted = true;
    } else if (char == ',') {
      row.add(field.toString());
      field.clear();
    } else if (char == '\n') {
      row.add(field.toString());
      field.clear();
      rows.add(List<String>.of(row));
      row.clear();
    } else if (char != '\r') {
      field.write(char);
    }
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(List<String>.of(row));
  }
  return rows;
}

String _headerKey(String value) => value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

String _cell(List<String> row, int index) {
  if (index < 0 || index >= row.length) return '';
  return row[index].trim();
}
