import 'study_entry_summary_model.dart';
import 'study_mode.dart';

/// Type the answer.
///
/// The grading policy and the widget arrive with M5.4c. What exists here is the
/// one thing the chooser needs before then, and the reason it needs it: `fill`
/// takes only cards carrying an `example`, and that field is optional (BR-114).
/// Every other mode takes whatever is due, which is why this is the mode whose
/// count differs — and why BR-154 forbids one shared number.
final class FillModeHandler implements StudyModeHandler {
  const FillModeHandler();

  @override
  int capacityFrom(StudyEntrySummaryModel summary) => summary.fillableCount;
}
