import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../download.dart';
import '../l10n.dart';
import '../reviews.dart';

final _softButton = TextButton.styleFrom(
  visualDensity: VisualDensity.compact,
  backgroundColor: const Color(0xFFE7EEF5),
  foregroundColor: const Color(0xFF0C3C6E),
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
);

class CourseReviews extends StatelessWidget {
  const CourseReviews({
    super.key,
    required this.strings,
    required this.rows,
    required this.loading,
    required this.failed,
    required this.courseCode,
    required this.courseTitle,
    required this.onSubmit,
  });

  final L10n strings;
  final List<CourseReview> rows;
  final bool loading;
  final bool failed;
  final String courseCode;
  final String courseTitle;
  final Future<void> Function(ReviewDraft draft) onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE4E7EC)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _body(),
              const SizedBox(height: 8),
              _AddReview(strings: strings, courseCode: courseCode, courseTitle: courseTitle, onSubmit: onSubmit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (loading) {
      return Row(
        children: [
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Text(strings.reviewsLoading, style: const TextStyle(color: Color(0xFF667085), fontSize: 13)),
        ],
      );
    }
    if (failed) {
      return Text(strings.reviewsFailed, style: const TextStyle(color: Color(0xFF667085), fontSize: 13, height: 1.35));
    }
    if (rows.isEmpty) {
      return Text(strings.noReviews, style: const TextStyle(color: Color(0xFF667085), fontSize: 13, height: 1.35));
    }
    return _ReviewBody(strings: strings, rows: rows);
  }
}

class _AddReview extends StatefulWidget {
  const _AddReview({
    required this.strings,
    required this.courseCode,
    required this.courseTitle,
    required this.onSubmit,
  });

  final L10n strings;
  final String courseCode;
  final String courseTitle;
  final Future<void> Function(ReviewDraft draft) onSubmit;

  @override
  State<_AddReview> createState() => _AddReviewState();
}

class _AddReviewState extends State<_AddReview> {
  var _open = false;
  var _sending = false;
  var _sent = false;
  var _error = false;
  var _missing = false;
  ReviewVote? _vote;
  late final TextEditingController _code;
  late final TextEditingController _title;
  late final TextEditingController _lecturer;
  late final TextEditingController _comment;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.courseCode);
    _title = TextEditingController(text: widget.courseTitle);
    _lecturer = TextEditingController();
    _comment = TextEditingController();
  }

  @override
  void dispose() {
    _code.dispose();
    _title.dispose();
    _lecturer.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final vote = _vote;
    if (normalizeCourseCode(_code.text).isEmpty || vote == null || _comment.text.trim().isEmpty) {
      setState(() => _missing = true);
      return;
    }
    setState(() {
      _sending = true;
      _error = false;
      _missing = false;
    });
    try {
      await widget.onSubmit(
        ReviewDraft(
          code: _code.text,
          title: _title.text,
          lecturer: _lecturer.text,
          vote: vote,
          comment: _comment.text,
        ),
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
        _open = false;
        _comment.clear();
        _lecturer.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_sent) Text(strings.reviewSent, style: const TextStyle(color: Color(0xFF146C36), fontSize: 12, height: 1.35)),
        if (!_open)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              style: _softButton,
              onPressed: _sending
                  ? null
                  : () => setState(() {
                      _open = true;
                      _sent = false;
                    }),
              child: Text(strings.addReview),
            ),
          )
        else ...[
          TextField(
            controller: _code,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: strings.reviewCode,
              hintText: strings.reviewCodeHint,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: strings.reviewTitleField, isDense: true, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _lecturer,
            decoration: InputDecoration(labelText: strings.reviewLecturerField, isDense: true, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 8),
          _VoteButton(
            label: strings.recommendVote,
            selected: _vote == ReviewVote.recommend,
            color: const Color(0xFF146C36),
            fill: const Color(0xFFE5F6EC),
            onPressed: () => setState(() => _vote = ReviewVote.recommend),
          ),
          const SizedBox(height: 6),
          _VoteButton(
            label: strings.notRecommendVote,
            selected: _vote == ReviewVote.notRecommend,
            color: const Color(0xFFB42318),
            fill: const Color(0xFFFDECEC),
            onPressed: () => setState(() => _vote = ReviewVote.notRecommend),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(labelText: strings.commentLabel, isDense: true, border: const OutlineInputBorder()),
          ),
          if (_missing) ...[
            const SizedBox(height: 6),
            Text(strings.reviewRequired, style: const TextStyle(color: Color(0xFFB42318), fontSize: 12, height: 1.35)),
          ],
          if (_error) ...[
            const SizedBox(height: 6),
            Text(strings.reviewSendFailed, style: const TextStyle(color: Color(0xFFB42318), fontSize: 12, height: 1.35)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: _sending ? null : () => setState(() => _open = false),
                child: Text(strings.cancel),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _sending ? null : _send,
                child: Text(_sending ? strings.sendingReview : strings.sendReview),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.fill,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final Color color;
  final Color fill;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: selected ? fill : Colors.white,
        side: BorderSide(color: selected ? color : const Color(0xFFD0D5DD)),
        alignment: Alignment.centerLeft,
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _ReviewBody extends StatefulWidget {
  const _ReviewBody({required this.strings, required this.rows});

  final L10n strings;
  final List<CourseReview> rows;

  @override
  State<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends State<_ReviewBody> {
  var _showComments = false;
  var _showAll = false;

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final rows = widget.rows;
    final tally = _tally(rows);
    final visible = _showAll || rows.length <= 4 ? rows : rows.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(strings.reviewsTitle, style: const TextStyle(fontWeight: FontWeight.w700))),
            Text(strings.reviewCount(rows.length), style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
          ],
        ),
        if (tally.rated > 0) ...[
          const SizedBox(height: 10),
          _Pie(strings: strings, tally: tally),
        ],
        if (tally.unknown > 0) ...[
          const SizedBox(height: 6),
          Text(strings.otherVotes(tally.unknown), style: const TextStyle(color: Color(0xFF667085), fontSize: 12, height: 1.35)),
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            style: _softButton,
            onPressed: () => setState(() => _showComments = !_showComments),
            child: Text(_showComments ? strings.hideReviews : strings.showReviews),
          ),
        ),
        if (_showComments) ...[
          for (final review in visible) _ReviewCard(strings: strings, review: review),
          if (rows.length > 4)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(_showAll ? strings.showFewerReviews : strings.showAllReviews(rows.length)),
              ),
            ),
        ],
      ],
    );
  }
}

ReviewTally _tally(List<CourseReview> rows) {
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

class _Pie extends StatelessWidget {
  const _Pie({required this.strings, required this.tally});

  final L10n strings;
  final ReviewTally tally;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(96, 96),
                painter: _PiePainter(recommend: tally.recommend, notRecommend: tally.notRecommend),
              ),
              Text(
                '${tally.recommendPercent}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: tally.recommendPercent >= 50 ? const Color(0xFF146C36) : const Color(0xFFB42318),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Legend(
                color: const Color(0xFF1F8A4C),
                label: strings.recommendVote,
                percent: tally.recommendPercent,
                count: tally.recommend,
              ),
              const SizedBox(height: 8),
              _Legend(
                color: const Color(0xFFD14343),
                label: strings.notRecommendVote,
                percent: tally.notRecommendPercent,
                count: tally.notRecommend,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.percent, required this.count});

  final Color color;
  final String label;
  final int percent;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: label, style: const TextStyle(fontSize: 12, height: 1.3)),
                TextSpan(
                  text: '  $percent% · $count',
                  style: const TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.recommend, required this.notRecommend});

  final int recommend;
  final int notRecommend;

  @override
  void paint(Canvas canvas, Size size) {
    final total = recommend + notRecommend;
    if (total == 0) return;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    final recommendSweep = math.pi * 2 * recommend / total;
    canvas.drawArc(rect.deflate(7), -math.pi / 2, recommendSweep, false, paint..color = const Color(0xFF1F8A4C));
    canvas.drawArc(
      rect.deflate(7),
      -math.pi / 2 + recommendSweep,
      math.pi * 2 - recommendSweep,
      false,
      paint..color = const Color(0xFFD14343),
    );
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) {
    return oldDelegate.recommend != recommend || oldDelegate.notRecommend != notRecommend;
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.strings, required this.review});

  final L10n strings;
  final CourseReview review;

  @override
  Widget build(BuildContext context) {
    final voteColor = switch (review.vote) {
      ReviewVote.recommend => const Color(0xFF146C36),
      ReviewVote.notRecommend => const Color(0xFFB42318),
      ReviewVote.unknown => const Color(0xFF475467),
    };
    final voteFill = switch (review.vote) {
      ReviewVote.recommend => const Color(0xFFE5F6EC),
      ReviewVote.notRecommend => const Color(0xFFFDECEC),
      ReviewVote.unknown => const Color(0xFFF2F4F7),
    };
    final voteText = review.verdict.isEmpty ? strings.unknownVote : review.verdict;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: voteFill, borderRadius: BorderRadius.circular(99)),
                child: Text(voteText, style: TextStyle(color: voteColor, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              Text(review.timestamp.isEmpty ? strings.notProvided : review.timestamp, style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          _Field(label: strings.reviewCourse, value: _courseLine(review, strings)),
          _Field(label: strings.lecturerLabel, value: review.lecturer.isEmpty ? strings.notProvided : review.lecturer),
          const SizedBox(height: 4),
          Text(strings.commentLabel, style: const TextStyle(color: Color(0xFF667085), fontSize: 12)),
          const SizedBox(height: 2),
          _CommentText(text: review.comment.isEmpty ? strings.notProvided : review.comment),
        ],
      ),
    );
  }
}

String _courseLine(CourseReview review, L10n strings) {
  final code = review.code.isEmpty ? strings.notProvided : review.code.trim();
  if (review.title.isEmpty) return code;
  return '$code · ${review.title}';
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(color: Color(0xFF667085), fontSize: 12, height: 1.35)),
            TextSpan(text: value, style: const TextStyle(fontSize: 13, height: 1.35)),
          ],
        ),
      ),
    );
  }
}

class _CommentText extends StatefulWidget {
  const _CommentText({required this.text});

  final String text;

  @override
  State<_CommentText> createState() => _CommentTextState();
}

class _CommentTextState extends State<_CommentText> {
  final List<TapGestureRecognizer> _links = [];

  @override
  void dispose() {
    for (final link in _links) {
      link.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _release();
    final pattern = RegExp(r'https?://[^\s<>"]+');
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in pattern.allMatches(widget.text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: widget.text.substring(start, match.start)));
      }
      var url = match.group(0)!;
      var trailing = '';
      while (url.isNotEmpty && '.,);'.contains(url[url.length - 1])) {
        trailing = url[url.length - 1] + trailing;
        url = url.substring(0, url.length - 1);
      }
      final recognizer = TapGestureRecognizer()..onTap = () => openExternal(url);
      _links.add(recognizer);
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(color: Color(0xFF0C3C6E), decoration: TextDecoration.underline),
          recognizer: recognizer,
        ),
      );
      if (trailing.isNotEmpty) spans.add(TextSpan(text: trailing));
      start = match.end;
    }
    if (start < widget.text.length) spans.add(TextSpan(text: widget.text.substring(start)));
    return SelectableText.rich(
      TextSpan(style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF101828)), children: spans),
    );
  }

  void _release() {
    for (final link in _links) {
      link.dispose();
    }
    _links.clear();
  }
}
