# features/card

The second slice through the layering, and its job in this repo is different
from Deck's.

**Deck answers "what does a correct slice look like". Card answers "which parts
of that were the method, and which were Deck".** A single reference cannot tell
those apart — everything in it looks equally load-bearing. Card is the control
case: it was built to the same rules, ended up shaped differently in almost every
countable way, and is correct. AD-17 holds the rule; this file holds the
evidence.

So this is deliberately **not** a second copy of `deck/README.md`. Read that one
for how a slice works end to end, and `feature_blueprint.md` for the layout the
three enforcers actually accept. Read this one when you are about to bring
something across from Deck and want to know whether you have to.

---

## 1 · What business problem it owns

The flashcards inside one deck: their content, the list the user manages them
in, and the editor. UC-04, plus the flag and tag rules BR-92…BR-95 that arrived
after UC-04 was written.

What it does **not** own: the schedule (`card_review_states` belongs to Study),
the tree it sits in (Deck), and "due" (BR-22 — Card reads that definition, it
does not state it).

---

## 2 · Where it differs from Deck, and why each difference was right

Counted from the code, not remembered.

| | deck | card | What the difference means |
|---|---|---|---|
| `domain/repositories/` | 2 | **1** | Deck needs a second contract because starter templates are a separate source with a separate lifetime. One contract per *source of data*, not per feature. |
| `domain/entities/` | 2 | **6** | Card owns three entity types (card, review state, tag) against Deck's one. Entity count follows the domain, not a quota. |
| `domain/usecases/` | 14 | **21** | One per interaction, as AD-12 requires — and Card simply has more interactions. Neither number is a target. |
| `data/mappers/` | 3 | **7** | More row shapes crossing the boundary. A mapper per shape, not per feature. |
| `data/repositories/` | 4 | **2** | Deck splits its impl four ways; Card split once, when bulk management pushed the single file past the size guard. Splitting is a size response, not a rule. |
| `widgets/items/` | 7 | **1** | Deck's tile has a chip, a pill and a glyph as separate parts. Card's row does not. |
| `widgets/overlays/` | 8 | **2** | Deck is full of sheets, forms, confirm dialogs and a move picker; Card has the editor's danger zone and the bulk overlays. |
| `widgets/support/` | 1 | **4** | Reversed. Card has more cross-bucket display mapping. |
| dynamic SQL placeholders | **0** | 4 | Card's list statement composes filter + search + sort in one query; Deck's does not compose anything. |

**The bucket rows are the most useful ones.** `items/` 4→1, `overlays/` 5→1,
`support/` 1→3 — the four buckets are fixed by AD-15, but *which of them a feature
fills* is decided entirely by what it renders. A thin bucket is not an unfinished
feature, and Card proves it in three directions at once.

---

## 3 · What Card does not have, and did not need

Deck's most distinctive machinery is absent here and nothing suffered:

- **No tree.** No `parent_card_id`, no depth limit, no subtree traversal. Cards
  do not contain cards.
- **No `content_type`.** Nothing about a card settles what kind of thing it may
  hold next.
- **No scheduler columns.** Those live on the root deck (BR-06) and reach a card
  through `card_review_states`, which this feature reads and does not own.
- **No tree-shaped move.** A card *can* be moved now (BR-165), but the operation
  is a single `deck_id` write with two content-type consequences — not Deck's
  subtree relocation with its depth recount, root repointing and scheduler
  compatibility check. Same verb, an order of magnitude apart, and the second one
  was not copied over on the strength of the name.
- **`data/models/` empty**, same as Deck and for the same reason — the Drift row
  class is the data model, and AD-05 has no wire format yet.

If a third feature acquires any of the first four without its own reason, that is
the failure AD-17 names.

---

## 4 · What Card confirmed rather than invented

These came from Deck unchanged, which is what makes them method rather than
habit:

- **The dependency direction.** A controller calls a use case; it never reads a
  repository (AD-12).
- **One interaction is one read.** The card list gets its rows, its counts and
  its deck context from statements that arrive together, not from two subscriptions
  a controller composes (AD-13).
- **Validation lives in a value object.** `CardText` has a private constructor and
  a `parse` returning either the value or a typed problem, exactly as `DeckName`
  does — so the contract's signature answers "has this been validated?".
- **A failure carries its reason as a value.** `CardConflictReason`,
  `CardNotFoundReason`, `CardValidationProblem` are enums the UI matches on; no
  refusal is encoded in a message string.
- **Rules needing data *at the moment of writing* stay in the transaction.** The
  first-child lock that sets a deck's `content_type` when the first card is
  created runs inside `runInTransaction`, not in a use case above it — and so
  does every rule in BR-165, which is why `MoveCards` validates nothing before
  calling the use case.

---

## 5 · Where its business rules are

Content and validation: BR-07, BR-08 (front and back), BR-95 (the three optional
detail fields). Flag and tags: BR-92, BR-93, BR-94. Card states derived at read
time: BR-89…BR-91. Creation with its review state in one transaction: BR-09.
Editing never touching the schedule: BR-10. Moving a card within its own tree:
BR-165. Bulk writes are all-or-nothing and a selection is taken over the filtered
result: BR-166, BR-167.

`content_type` interactions — a card being the first child of an `unset` deck —
are BR-60…BR-66 and BR-163, and they belong to Deck; Card participates in that transaction but
does not state the rule.

**UC-04 is out of date against this feature** and is recorded as such in
`docs/master-flow.md` §6: it never mentions the flag or tags although BR-93 and
BR-95 both declare `Related: UC-04`. The reference is one-directional. Fixing it
means editing a `frozen for MVP` document and has not been done.

---

## 6 · Card Transfer (M99.19, AD-20)

Import v1 đứng trên một nền dùng chung: canonical schema sáu field ở
`card_transfer_field_model.dart` (header lowercase English, không localize;
tag nối `;`), decoder Strategy theo format với registry duy nhất
`cardTransferDecoderFor`, và ba stage model raw document → mapped → canonical
record. Ba contract hẹp — `CardImportSourceRepository` (picker),
`CardTransferRepository` (decode), `CardImportRepository` (commit) — để mỗi
test chỉ fake nửa nó gọi; `card_transfer_boundary_test.dart` ghim các ranh
giới bằng source scan.

Export (M99.21, BR-174…BR-181 · UC-11) đã lấp nửa còn lại **đúng như dự đoán
đó**: encoder strategy + `cardTransferEncoderFor` + `CardExportRepository` +
`CardExportDestinationRepository` đứng cạnh ba contract Import, không sửa
Import một dòng nào. Hai điều đáng ghi vì chúng khác Import:

- **Contract của encoder nằm ở `domain/models/`, implementation ở
  `data/datasources/`** — ngược với decoder, nơi cả hai ở `data/`. Lý do là
  caller: `ExportCardsUseCase` gọi encoder, nên nếu contract ở `data/` thì
  use case phải import `data/` và AD-12 gãy. Decoder không có vấn đề này vì
  chỉ repository gọi nó.
- **Tag cell có codec dùng chung hai chiều** (`CardTransferTagCodec`,
  BR-176). `;` trần không round-trip nổi một tag chứa `;`, và hai
  implementation sẽ khớp nhau ở happy path rồi lệch đúng ở `;` và `\` —
  nên Import đã được chuyển sang codec này trong cùng change, không hẹn lại.

Overlay chứ không phải screen: `showCardExportSheet` là hình dạng
presentation đầu tiên của feature không phải một `_screen.dart`. Hệ quả thật
là visual-audit harness không nhận nó — `screen_audit_coverage.dart` khám phá
subject theo `_screen.dart`, nên một companion audit cho overlay sẽ *làm gãy*
suite coverage. Geometry của sheet vì thế được ghim bằng
`card_export_alignment_test.dart` đo `getRect`, không bằng audit.

---

## 7 · Tag Management v1 (M99.23, UC-12, BR-182…BR-190)

**Nó nằm ở `features/card/` chứ không phải một feature thứ ba, và đó là một
quyết định chứ không phải sự tiện tay.** BR-93 nói tag **là nội dung của thẻ**,
và §2 của chính file này đã ghi tag vào phần Card sở hữu. `TagName`,
`TagEntity`, `tag.drift` và mọi write của `card_tags` đã ở đây từ M4.10at; tách
catalog ra một feature riêng sẽ tạo đúng thứ AD-13 cấm — hoặc một vòng phụ thuộc
domain hai chiều (catalog cần `TagName` của Card, overlay lọc của Card cần use
case của catalog), hoặc một lần di dời `TagName` ra khỏi Card, tức là một
refactor nằm ngoài scope đã nêu. Tính từ "library-level" trong BR-182 mô tả
**phạm vi dữ liệu** — mọi deck — chứ không phải thư mục.

Ba điều Tag Management làm khác phần còn lại của Card, và mỗi điều có lý do
riêng:

- **Contract thứ hai trong cùng một feature.** `TagCatalogRepository` đứng cạnh
  `CardRepository` với đúng ba method. Ranh giới thật: mọi method tag của
  `CardRepository` đều nhận `card_id` — nó nhìn tag *qua một thẻ*; không method
  nào ở đây nhận, vì catalog nhìn bảng tag đứng một mình và write của nó chạm
  mọi thẻ cùng lúc. Hệ quả đo được: `TagCatalogDao` **không có một câu lệnh nào
  chạm `cards`**, nên BR-188 là tính chất của bề mặt chứ không phải một lời hứa
  trong prose.
- **Vị từ lọc là `EXISTS`, không phải join.** `INNER JOIN card_tags` cho đúng
  tập thẻ và **sai số hàng**: một thẻ mang ba tag đã chọn chiếm ba chỗ trong
  `LIMIT` và được đếm ba lần. `DISTINCT` chữa count nhưng huỷ điểm dừng sớm mà
  index `(deck_id, created_at, id)` mua được. `card_list_tag_filter_test.dart`
  ghim cả hai bằng SQLite thật, vì không fake nào phân biệt được hai hình dạng
  SQL này.
- **Gộp là hệ quả của rename, không có action riêng** (BR-186). Ba câu lệnh
  trong một transaction, dedupe bằng chính primary key của `card_tags` qua
  `INSERT OR IGNORE`. Điều đáng ghi: **gộp không bao giờ làm một thẻ vượt trần
  mười tag** — mỗi thẻ đổi nguồn lấy đích chứ không cộng thêm — nên BR-94 không
  cần một check ở đây, và đó là phát biểu mạnh hơn việc có check.

**`TagFilter` là chỗ luật "không chọn tag nào thì không áp vị từ nào" sống, một
lần.** Bốn caller — list read, count read, select-all, và pill trên thanh filter
— nếu tự viết `if (tagIds.isNotEmpty)` thì có bốn cơ hội để một trong số đó viết
sai, và lỗi im lặng: count lọc còn list thì không, màn hình đọc "Showing 12 of
3".

## 8 · Known gaps

- **Partially in the Widgetbook catalog.** `CardImportScreen` (M99.19) and
  `TagCatalogScreen` (M99.23) are registered; `CardListScreen` and
  `CardEditorScreen` are still absent, against the Definition of Done in
  `CLAUDE.md`. Those two are covered by the strict visual audit and by review
  renders in `test/demo/`, but not by the catalog.
- **The tag filter sheet and the rename/delete overlays have no visual audit**,
  the same gap the export sheet records in §6 and for the identical reason: the
  audit harness discovers subjects by `_screen.dart` and its raster cross-check
  cannot read through a modal barrier. Their geometry is pinned by
  `tag_catalog_alignment_test.dart` (M4.14 G1…G9) and their copy by
  `tag_delete_test.dart` / `tag_rename_test.dart` instead.
- **The row's card count does not read as a secondary line**, although W2 asks
  for one. `app_theme.dart` sets `listTileTheme.textColor`, and Flutter derives
  a ListTile's subtitle colour from it — so title and subtitle come out the
  same value (`#16182B` light, `#EDEDF6` dark) in **every** `MxListTile` in the
  app, not just here. Left out of M99.23 on purpose: the fix is one theme
  property and a golden regeneration across the deck list, the card list and
  the design audit, which is a change to every screen and belongs to its own
  task rather than to a tag PR.
- **A tag filter left on a deleted tag heals only on the next `Apply`.** Until
  then the list is empty and the pill still counts the tag that is gone; the
  recovery is one tap (open the sheet, `Apply`), and the sheet drops the missing
  id for you. Healing it eagerly would mean the filter notifier watching the
  catalog, which rebuilds it — and therefore resets the window and clears the
  selection — every time any tag's count changes anywhere.
