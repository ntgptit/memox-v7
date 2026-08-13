/// How an export ended, once the OS has been asked to take the file
/// (UC-11 step 7, A3).
///
/// **Two values, and neither of them is "saved".** BR-181 is explicit: the app
/// hands the artifact to the share sheet and the OS never tells it what
/// happened next, so a `saved` value would be a claim nothing can support and
/// a copy string nothing can verify. [shared] means handed over; where it went
/// is not knowable from here.
enum CardExportResult {
  /// The user chose a destination and the OS accepted the file. The truthful
  /// copy is "handed to the system", never "saved to X".
  shared,

  /// The user closed the share sheet without choosing anything. This is a
  /// **cancel**, not a failure (BR-181, UC-11 A3): no error, no toast, and the
  /// export sheet returns to its initial state with the scope and format the
  /// user had picked.
  dismissed,
}
