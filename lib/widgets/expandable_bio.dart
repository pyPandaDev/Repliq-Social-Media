import 'package:flutter/material.dart';

class ExpandableBio extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;

  const ExpandableBio({
    required this.text,
    this.style,
    this.maxLines = 2,
    super.key,
  });

  @override
  State<ExpandableBio> createState() => _ExpandableBioState();
}

class _ExpandableBioState extends State<ExpandableBio> {
  bool _isExpanded = false;
  late TextSpan textSpan;
  bool _hasOverflow = false;

  @override
  void initState() {
    super.initState();
    textSpan = TextSpan(
      text: widget.text,
      style: widget.style ?? const TextStyle(color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPainter = TextPainter(
      text: textSpan,
      maxLines: widget.maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width * 0.6);

    _hasOverflow = textPainter.didExceedMaxLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _hasOverflow ? () => setState(() => _isExpanded = !_isExpanded) : null,
          child: Text(
            widget.text,
            style: widget.style ?? const TextStyle(color: Colors.grey),
            maxLines: _isExpanded ? null : widget.maxLines,
            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            softWrap: true,
          ),
        ),
        if (_hasOverflow) ...[
          const SizedBox(height: 2),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Text(
              _isExpanded ? 'Show less' : 'Show more',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
} 