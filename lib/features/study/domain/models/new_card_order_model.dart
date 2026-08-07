/// The order new cards enter a `learning` session (BR-148).
///
/// Only applies to that kind of session: a `reviewing` session orders by
/// `due_at` ascending and has no choice to make (BR-23).
enum NewCardOrder {
  /// By `created_at` ascending — the order they were added. The default.
  created('created'),

  /// Shuffled.
  random('random');

  const NewCardOrder(this.dbValue);

  /// The value stored in the database.
  final String dbValue;

  /// Maps a stored value to the enum, falling back to the default.
  ///
  /// Tolerant, unlike the session enums: an unreadable ordering preference is
  /// not a reason to refuse to study. The worst case is cards arriving in the
  /// order the user did not pick.
  static NewCardOrder fromDbValue(String value) {
    for (final order in values) {
      if (order.dbValue == value) return order;
    }

    return created;
  }
}
