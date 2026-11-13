import 'package:flutter_test/flutter_test.dart';
import 'package:hkbu_timetable/reviews.dart';

void main() {
  test('reviews match a course code ignoring spaces and case', () {
    const csv = '''
Timestamp,Course Code,Course Title,Tutor / Lecturer,Reg / Don't Reg ?,Comment / Reason
2022/6/3 上午 2:52:07, BUSI2005,Organisational Behavior,Chang Song,Recommend｜推薦,"Lecturer is pretty good, but the exam was clear."
2024/11/21 上午 3:07:16,busi2005,Organisational Behavior,Angela,Not Recommend｜不推薦,"唔推薦
因為分緊"
2017/11/17 上午 1:13:56,OTHER1005,Other,Ann,Not Recommend｜不推薦,skip
''';

    final book = ReviewBook.parse(csv);
    final rows = book.of('busi 2005');

    expect(rows, hasLength(2));
    expect(rows.first.vote, ReviewVote.notRecommend);
    expect(rows.first.comment, contains('因為分緊'));
    expect(rows.last.lecturer, 'Chang Song');
    expect(rows.last.comment, contains('exam was clear'));

    final tally = book.tally('BUSI2005');
    expect(tally.recommend, 1);
    expect(tally.notRecommend, 1);
    expect(tally.recommendPercent, 50);
    expect(tally.notRecommendPercent, 50);
    expect(book.of('OTHER1005'), hasLength(1));
  });

  test('not recommend is not counted as recommend', () {
    expect(voteOf('Not Recommend｜不推薦'), ReviewVote.notRecommend);
    expect(voteOf('Recommend｜推薦'), ReviewVote.recommend);
    expect(voteOf(''), ReviewVote.unknown);
  });

  test('recommendation percent uses only the two choices', () {
    const csv = '''
Timestamp,Course Code,Course Title,Tutor / Lecturer,Reg / Don't Reg ?,Comment / Reason
2025/2/1 下午 9:13:01,UCLC1008,English,Rita,Recommend｜推薦,a
2025/1/1 上午 9:00:00,UCLC1008,English,Rita,Recommend｜推薦,b
2024/1/1 上午 9:00:00,UCLC1008,English,Rita,Not Recommend｜不推薦,c
''';
    final tally = ReviewBook.parse(csv).tally('UCLC1008');
    expect(tally.recommendPercent, 67);
    expect(tally.notRecommendPercent, 33);
    expect(ReviewBook.parse(csv).of('UCLC1008').first.timestamp, contains('2025/2/1'));
  });

  test('a new review is sent to the live Google Form fields', () {
    final fields = const ReviewDraft(
      code: ' busi2005 ',
      title: 'Org',
      lecturer: 'Ann',
      vote: ReviewVote.notRecommend,
      comment: ' 分緊 ',
    ).formFields();

    expect(fields['entry.875515428'], 'BUSI2005');
    expect(fields['entry.20836144'], 'Org');
    expect(fields['entry.1002790793'], 'Ann');
    expect(fields['entry.1026089525'], notRecommendVerdict);
    expect(fields['entry.452007492'], '分緊');
    expect(reviewFormResponseUrl, contains('/formResponse'));
  });
}
