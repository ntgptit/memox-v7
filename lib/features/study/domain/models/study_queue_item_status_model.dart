/// Whether a queue row still has to be served (BR-28).
enum StudyQueueItemStatus {
  /// Not yet done with this stage, in this round.
  pending('pending'),

  /// Answered with something other than `forgotten`/`again`, or — for `browse`,
  /// which grades nothing — shown and moved past (BR-28, BR-111).
  completed('completed');

  const StudyQueueItemStatus(this.dbValue);

  /// The value stored in the database.
  final String dbValue;

  /// Maps a stored value to the enum.
  static StudyQueueItemStatus fromDbValue(String value) {
    for (final status in values) {
      if (status.dbValue == value) return status;
    }

    throw StateError('Unknown StudyQueueItemStatus: $value');
  }
}
