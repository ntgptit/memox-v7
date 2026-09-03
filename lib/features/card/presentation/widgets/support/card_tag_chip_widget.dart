import 'package:flutter/material.dart';

import '../../../../../shared/widgets/mx_badge.dart';

/// A read-only tag pill (BR-93).
///
/// The shared quiet badge, named for what it says: a tag on a card, on the
/// list row and on the detail screen alike. It was the third feature site
/// writing the muted-pill recipe by hand before `MxBadge` existed (M100.36
/// 11K); the class stays so the two screens keep naming the *thing* rather
/// than the paint.
class CardTagChipWidget extends StatelessWidget {
  const CardTagChipWidget({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) => MxBadge(label: name);
}
