import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_template_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

/// A hand-built template, so the repository tests do not depend on the shipped
/// assets.
///
/// **Three levels with a card-holding leaf and an empty one.** The tree has to
/// be at least three deep or `root_deck_id` errors do not show — BR-57's whole
/// point is that the root is wrong from the third level down when it is derived
/// rather than carried. The empty leaf is there because `content_type` for a
/// deck with nothing in it is `unset`, not `card`, and only a fixture with one
/// can prove the copy agrees.
DeckTemplate eightBoxFixtureTemplate({
  String templateId = 'fixture.test.tree',
  int version = 1,
  SchedulerType scheduler = SchedulerType.eightBox,
}) => DeckTemplate(
  templateId: templateId,
  version: version,
  locale: 'en',
  title: _name('Fixture deck'),
  contentSource: 'memox-fixture',
  defaultSchedulerType: scheduler,
  children: <DeckTemplateNode>[
    DeckTemplateNode.branch(
      name: _name('Branch'),
      children: <DeckTemplateNode>[
        DeckTemplateNode.leaf(
          name: _name('Words'),
          cards: <DeckTemplateCard>[
            _card('kettle', 'ấm đun nước'),
            _card('cupboard', 'tủ bát đĩa'),
            _card('sink', 'bồn rửa'),
          ],
        ),
        DeckTemplateNode.leaf(name: _name('Empty'), cards: const []),
      ],
    ),
  ],
);

DeckName _name(String raw) => DeckName.parse(raw).name!;

DeckTemplateCard _card(String front, String back) => DeckTemplateCard(
  front: CardText.parse(front, side: CardSide.front).text!,
  back: CardText.parse(back, side: CardSide.back).text!,
);
