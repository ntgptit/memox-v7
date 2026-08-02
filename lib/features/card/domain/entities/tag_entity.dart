import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_entity.freezed.dart';

/// One tag, as a chip renders it (BR-93).
///
/// Content, not schedule — a tag survives a reset, the same side of the line as
/// `front` and the flag. [name] is what the user typed, stored as-is; the folded
/// form the uniqueness index compares on stays in the data layer and never
/// reaches the domain, because nothing above the repository compares tags by
/// hand — [TagName.collidesWith] owns that.
@freezed
abstract class TagEntity with _$TagEntity {
  const factory TagEntity({required String id, required String name}) =
      _TagEntity;
}
