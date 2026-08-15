// The one piece the card face draws twice: a half. A `part` of
// `study_card_face_section_widget.dart` so it keeps access to the library's
// private members — the split exists to satisfy the file-size guard, not to
// change anything about how it is used.
part of 'study_card_face_section_widget.dart';

/// One side of the card: a small muted label in the corner, and the text it
/// names centred in what is left.
///
/// **The label is in the corner and the content is in the middle** (§3). Both
/// halves are the same shape, so the eye reads them as two sides of one card
/// rather than as a heading and a paragraph — and the centre is where the eye
/// lands when a card flips.
///
/// **The label names the column, not the language.** The design says `KOREAN`;
/// no deck and no card carries a language, so printing one would put a field in
/// the UI that does not exist in the data. It is `Front`/`Back`, and since
/// BR-204 the label travels with its content rather than with its position — the
/// upper half of a Meaning→Korean card says `BACK`, which is what tells the two
/// directions apart for a reader who cannot read either side.
class _CardHalf extends StatelessWidget {
  const _CardHalf({
    required this.label,
    required this.text,
    required this.style,
    required this.padding,
  });

  final String label;
  final String text;
  final TextStyle? style;

  /// Asymmetric on purpose — see the card above. Vertical only; the sides
  /// belong to the card so that the rule between the halves can reach them.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: context.texts.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
            letterSpacing: AppTypography.sectionLabelTracking,
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              // The half is a fixed share of the card, so at a large text scale
              // a long meaning has to be able to move rather than overflow.
              child: Text(text, style: style, textAlign: TextAlign.center),
            ),
          ),
        ),
      ],
    ),
  );
}
