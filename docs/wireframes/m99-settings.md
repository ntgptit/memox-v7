# Wireframe M99.28 — Settings v1 (study defaults · appearance · language)

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chốt cấu trúc UI của màn Settings toàn app để M99.28 xây mà không phải đoán layout, copy, geometry hay state nào |
| **Scope** | Màn `/settings`: anatomy, ba nhóm tuỳ chọn, hành động reset, mọi trạng thái, hợp đồng geometry, responsive/a11y. Ngoài phạm vi: luật nghiệp vụ (BR-210…BR-217), luồng (UC-16), branch contract (AD-19), và surface tuỳ chọn của deck — nó thuộc `StudyOptionsScreen` và chỉ được nhắc ở S6 |
| **Source of truth for** | Anatomy màn Settings · copy các nhóm Settings · hợp đồng geometry của màn Settings · responsive/a11y contract của màn Settings |
| **Depends on** | `../use-cases.md` (UC-16), `../business-rules.md` (BR-210…BR-217), `../architecture.md` (AD-15, AD-19), `m4-13-card-export.md` |
| **Updated by task** | M99.28 (phase 8 — recursive UI/UX review) |
| **Last updated** | 2026-08-14 |

Tài liệu này **không** phát biểu lại luật. Mọi ràng buộc tham chiếu bằng ID theo
`document-conventions.md` §5; chỗ nào wireframe và BR có vẻ mâu thuẫn thì BR
đúng và wireframe sai.

Settings là màn đầu tiên của app mà **mọi hàng đều là một lần ghi**. Một danh
sách deck hỏng thì người dùng thấy ngay; một hàng Settings hỏng thì nó im lặng
ghi sai một giá trị mà lần sau mới lộ ra, ở một màn hình khác. Vì vậy phần lớn
quyết định dưới đây là về **cái gì nói cho người dùng biết là đã lưu** chứ không
về sắp xếp.

## S-quyết định

| # | Quyết định | Lý do | Ngày |
|---|---|---|---|
| S1 | Ba nhóm, đúng thứ tự: `Study defaults` → `Appearance` → `Language`; mỗi nhóm là một `MxCard` dưới một nhãn nhóm | Thứ tự theo tần suất đổi thật: trần thẻ là thứ người học chỉnh trong tuần đầu, theme là thứ chỉnh một lần, ngôn ngữ là thứ hầu hết không chỉnh bao giờ. Nhóm bằng card chứ không bằng divider trần vì màn này còn phải mang một hành động phá huỷ ở cuối, và một danh sách phẳng làm nó trông như hàng thứ tám | 2026-08-13 |
| S2 | **Theme và ngôn ngữ ghi ngay khi chạm; study defaults có nút `Save`** | Không phải sự thiếu nhất quán mà là hai loại input khác nhau. Theme và ngôn ngữ là lựa chọn rời rạc và **tự xác nhận** — người dùng thấy kết quả ngay trên chính màn hình đó, nên một nút Save chỉ thêm một bước giữa hành động và bằng chứng. Trần thẻ là văn bản tự do: nó có trạng thái nửa chừng (`2` trên đường gõ `20`) và có thể sai, nên nó cần một mốc submit rõ ràng (BR-216) | 2026-08-13 |
| S3 | `New card order` đi **cùng nhóm** với trần thẻ và **cùng nút Save**, dù nó là lựa chọn rời rạc | Hai giá trị này là một cặp trong đầu người dùng ("một phiên trông như thế nào") và là một cặp trong dữ liệu (BR-211). Tách nút Save cho một nửa nghĩa là chạm order rồi rời màn hình sẽ lưu một nửa những gì họ vừa đổi — đúng loại "lưu một phần" mà BR-216 cấm | 2026-08-13 |
| S4 | Dòng BR-213 nằm **trong** nhóm Study defaults, ngay trên nút `Save`, không phải một banner đầu màn | Nó chỉ đúng cho nhóm đó. Đặt ở đầu màn thì nó cũng nói về theme và ngôn ngữ, vốn áp dụng tức thì — một câu vừa đúng vừa sai tuỳ người đọc đang nhìn nhóm nào | 2026-08-13 |
| S5 | `Reset to defaults` là **hành động chữ**, không phải card đỏ, và có bước xác nhận nói rõ nó **không** đụng tiến độ học | Đúng idiom `_DestructiveRow` mà `test/design_preview/settings_preview_test.dart` đã chốt: `danger` là màu **chữ**, không phải nền. Một khối đỏ ở cuối mọi màn Settings kéo mắt về phía dưới và đọc như một lỗi app đang báo. Câu xác nhận phải nói phạm vi vì hai hành động khác nhau ở app này có cùng chữ "reset" (BR-42 vs BR-217) | 2026-08-13 |
| S6 | `Use app defaults` của root deck **không** xuất hiện trên màn này | Nó tác động lên **một** deck; đặt nó ở màn toàn app thì phải kèm một deck picker, tức là một màn hình thứ hai trong màn hình này. Nó sống ở `StudyOptionsScreen`, nơi deck đang mở là ngữ cảnh sẵn có (BR-212) | 2026-08-13 |
| S7 | Trạng thái `saving` khoá **control của nhóm đang ghi**, không khoá cả màn | Ba nhóm là ba transaction rời nhau (BR-216). Một overlay toàn màn biến ba lần ghi độc lập thành một hàng đợi mà người dùng phải nhìn, và với một lần ghi SQLite cục bộ thì nó nhấp nháy chứ không thông báo | 2026-08-13 |
| S8 | Lỗi ghi hiện **một dải trong nhóm hỏng** kèm `Try again`, không phải snackbar | Snackbar biến mất trước khi người dùng đọc xong, và nó không nói nhóm nào hỏng. Dải ở đúng nhóm trả lời cả hai câu — cùng lý do E8 của `m4-13-card-export.md` | 2026-08-13 |
| S9 | **Mọi** lựa chọn rời rạc trên màn này — theme, ngôn ngữ **và thứ tự thẻ mới** — dùng `RadioGroup` + `RadioListTile`; **không** segmented button, **không** pill | Ba lựa chọn có nhãn dài trong tiếng Việt (`Theo hệ thống`) và segmented button co chữ lại hoặc cắt. Radio row là idiom đã có của app (`DeckSchedulerPickerWidget`) với `RadioThemeData` đã được đo (`app_radio_theme.dart`). **Quan trọng hơn cả hai lý do đó: pill không thoả MUST của W6.** `buildChipTheme` đặt `showCheckmark: false` và chỉ resolve `side` theo `disabled`/`focused`, nên pill đang chọn khác pill chưa chọn **duy nhất** ở màu nền và màu chữ. Radio mang glyph riêng nên trạng thái sống sót khi không nhìn được màu | 2026-08-13 |
| S9a | **Thứ tự thẻ mới trên màn này khác `StudyOptionsSectionWidget`, và đó là một lệch có chủ đích.** Màn tuỳ chọn của deck vẫn dùng pill | Bản đầu của S3/W5 yêu cầu hai màn "không được nhìn khác nhau", và lập luận đó đúng cho *nhịp và nhãn* nhưng sai khi nó kéo theo cả một control vi phạm W6. Sửa đúng chỗ là ở `MxPillButton`/`app_chip_theme.dart` — và ở kit web phản chiếu nó — chứ không phải nhét một câu trả lời riêng vào một feature; nên gap đó được ghi lại chứ không sửa lén ở đây. Xem ghi chú M99.28 trong `docs/wbs.md` | 2026-08-14 |

## W-cấu trúc

### W1 — Entry point và khung

Tab `Settings` (branch 3 của shell) hoặc deep link `/settings`. Màn là
`MxContentShell(title:, isScrollable: true)` — không action bar, không FAB,
không back (nó là gốc của branch).

```
┌─────────────────────────────────────┐
│  Settings                           │  ← AppBar, MxContentShell
├─────────────────────────────────────┤
│                                     │
│  STUDY DEFAULTS                     │  ← nhãn nhóm: labelMedium + sectionLabelTracking, onSurfaceVariant, VIẾT HOA (D18)
│  ┌───────────────────────────────┐  │
│  │ Cards per session             │  │
│  │ [ 20                        ] │  │  ← MxTextField, number
│  │                               │  │
│  │ New card order                │  │
│  │ (•) As added                  │  │  ← RadioListTile, S9/S9a
│  │ ( ) Shuffled                  │  │
│  │                               │  │
│  │ Applies to sessions you start │  │  ← BR-213, bodySmall
│  │ after saving.                 │  │
│  │ [        Save              ]  │  │  ← MxActionButton
│  └───────────────────────────────┘  │
│                                     │
│  APPEARANCE                         │
│  ┌───────────────────────────────┐  │
│  │ (•) System                    │  │
│  │ ( ) Light                     │  │
│  │ ( ) Dark                      │  │
│  └───────────────────────────────┘  │
│                                     │
│  LANGUAGE                           │
│  ┌───────────────────────────────┐  │
│  │ (•) System                    │  │
│  │ ( ) English                   │  │
│  │ ( ) Tiếng Việt                │  │
│  └───────────────────────────────┘  │
│                                     │
│  ⟲ Reset to defaults                │  ← danger là màu chữ (S5)
│  Puts app options back to their     │
│  defaults. Your decks and learning  │
│  progress are not affected.         │
│                                     │
└─────────────────────────────────────┘
   ↑ bottom-nav clearance: xem W5
```

### W2 — Copy

Nhãn hiển thị là ARB; bảng này chốt **nội dung**, không chốt chuỗi ARB.

| Chỗ | EN | VI |
|---|---|---|
| Nhãn nhóm 1 | `Study defaults` | `Mặc định học` |
| Trần thẻ | `Cards per session` | `Số thẻ mỗi phiên` |
| Thứ tự thẻ mới | `New card order` | `Thứ tự thẻ mới` |
| Ghi chú BR-213 | `Applies to sessions you start after saving. A session already running keeps its own limit.` | `Áp dụng cho phiên bạn bắt đầu sau khi lưu. Phiên đang chạy giữ nguyên trần của nó.` |
| Nhãn nhóm 2 | `Appearance` | `Giao diện` |
| Nhãn nhóm 3 | `Language` | `Ngôn ngữ` |
| Lựa chọn `system` | `System` | `Theo hệ thống` |
| Hành động reset | `Reset to defaults` | `Khôi phục mặc định` |
| Phụ đề reset | `Puts app options back to their defaults. Your decks and learning progress are not affected.` | `Đưa các tuỳ chọn ứng dụng về mặc định. Deck và tiến độ học của bạn không bị ảnh hưởng.` |
| Xác nhận reset | tiêu đề + đúng câu phụ đề trên + `Reset` / `Cancel` | như trên |

`Tiếng Việt` và `English` là **endonym**, viết nguyên ngữ ở cả hai bản dịch —
một người đang mắc kẹt trong ngôn ngữ họ không đọc được phải tìm ra tên ngôn ngữ
của chính mình.

### W3 — Bảy trạng thái

| # | Trạng thái | Màn hình |
|---|---|---|
| 1 | loading | `MxLoadingState` toàn thân. Không nhóm nào vẽ trước — một control hiện `System` trong lúc chưa đọc xong là một giá trị bịa (BR-210) |
| 2 | loaded, mặc định | Ba nhóm, mỗi nhóm chọn giá trị mặc định. Hành động reset **vẫn hiện** và vẫn bấm được: "đã ở mặc định" không phải trạng thái mà UI cần suy ra, và ẩn nó làm người dùng đi tìm |
| 3 | loaded, không mặc định | Như trên với giá trị đã lưu. Trần thẻ hiện số đã lưu, không hiện placeholder |
| 4 | saving | Control của **nhóm đang ghi** bị khoá; hai nhóm kia dùng được (S7). Nhóm Study defaults: nút Save vào trạng thái loading. Nhóm choice: `RadioListTile.enabled = false` cho cả nhóm đó |
| 5 | validation error | Chỉ nhóm Study defaults có được. Message dưới trường trần thẻ, draft giữ nguyên, không ghi gì (BR-211, BR-216) |
| 6 | persistence error | Dải lỗi trong nhóm hỏng + `Try again`. Các control còn lại hiển thị **giá trị đã persisted**, không phải giá trị vừa chạm hụt (BR-216) |
| 7 | read error | `MxErrorState` toàn thân + `Try again`. Không nhóm nào vẽ |

Trạng thái `System resolution` không phải một mặt riêng: nó là mặt 2 hoặc 3 được
render dưới platform brightness / locale khác nhau, và W6 mới là chỗ nó được
kiểm.

### W4 — Reset

Xác nhận qua `MxConfirmDialog` biến thể `destructive` — idiom xác nhận sẵn có
của app, cùng thứ Deck dùng cho xoá deck. **Không** dựng `AlertDialog` mới và
**không** dùng `MxActionSheet`: action sheet là menu chọn hành động, còn đây là
một câu hỏi có/không.

Nội dung đúng W2. Huỷ, chạm ra ngoài hoặc Android Back đóng dialog và không ghi
gì. Xác nhận là một submit chịu đúng BR-216: khoá double submit, và lỗi hiện
thành dải ở nhóm reset **sau khi** dialog đóng — dialog không ở lại để mang lỗi,
vì hành động đã rời khỏi nó.

Sau khi reset thành công, ba nhóm cập nhật qua **stream**, không qua một lần đọc
thứ hai do màn hình tự gọi (BR-210).

### W5 — Hợp đồng geometry

- **Một cột nội dung duy nhất.** Nhãn nhóm, mép card của cả ba nhóm, nhãn hành
  động reset và phụ đề của nó **bắt đầu và kết thúc ở đúng hai toạ độ x** — cột
  là gutter của `MxContentShell`. Không nhóm nào thụt vào so với nhóm khác.
- **Ba card có cùng mép trái và cùng mép phải.** Đây là ràng buộc đo được, không
  phải hệ quả tự nhiên: một card bọc thêm `Padding` là đủ để lệch, và mắt không
  bắt được 4px lệch giữa hai card cách nhau 24px theo chiều dọc.
- **Nội dung bên trong ba card cũng chia sẻ một cột, và hai card choice đạt điều
  đó theo cách khác card Study defaults.** Card choice MUST chỉ có padding dọc,
  để mặt chạm và lớp ink của mỗi hàng radio trải hết bề rộng card; bù lại mỗi
  hàng MUST tự mang `contentPadding` ngang bằng `AppSpacing.lg`, đúng bằng
  padding mặc định của `MxCard`. Kết quả đo được: **mép trái của hàng radio
  trùng mép trái nội dung của card Study defaults**. Bỏ padding ngang ở hàng
  (`EdgeInsets.zero`) làm chữ dính mép card; để card giữ padding mặc định làm
  vùng chạm hụt `lg` ở mỗi bên — cả hai đều là lỗi đo được, nên cả hai đều phải
  có assertion.
- **Baseline nhãn/control.** Trong nhóm Study defaults, khoảng cách nhãn →
  control là `AppSpacing.xs`; giữa hai cụm nhãn+control là `AppSpacing.lg`.
  Cùng nhịp với `StudyOptionsSectionWidget`, và cố ý: hai màn chỉnh cùng hai giá
  trị nên nhịp và nhãn phải khớp. **Cái không khớp là control của thứ tự thẻ
  mới** — xem S9a; parity là về nhịp và copy, không phải về widget.
- **Hàng radio của thứ tự thẻ mới nằm trong card đã có padding, nên nó mang
  `contentPadding` bằng 0.** Hệ quả đo được: mép trái của hàng trùng đúng mép
  trái của nhãn `Cards per session` ngay trên nó. Hai card choice làm ngược lại
  — card chỉ padding dọc, hàng tự mang `lg` ngang — và đích đến là cùng một toạ
  độ x.
- **Nhịp dọc.** Nhãn nhóm → card của nó: `AppSpacing.xs`. Card → nhãn nhóm kế
  tiếp: `AppSpacing.xl`. Card cuối → hành động reset: `AppSpacing.xl`.
- **Dải lỗi** là một band của cùng cột **bên trong card của nhóm hỏng**, không
  phải một hộp thụt vào và không phải một band ở cuối màn.
- **Bottom-nav clearance.** Màn nằm trong shell nên `NavigationBar` che phần
  dưới. Body cuộn, và ở tổ hợp hẹp nhất, hàng cuối cùng — phụ đề của reset —
  MUST cuộn tới được và MUST NOT nằm dưới bottom bar khi đã cuộn hết.

Hợp đồng này MUST được chứng minh bằng **`tester.getRect` assertion** trong
widget test — đo đúng các widget người đọc nhìn thấy (card, nhãn, hàng radio,
nút), không đo cái hộp vô hình chứa chúng. Golden chỉ là regression baseline.

### W6 — Responsive & a11y

- Kiểm ở 320 / 390 / 412dp, `textScaler` 1.0 và 2.0, light + dark, EN và VI.
  Không overflow ở bất kỳ tổ hợp nào. **320dp @ 2.0 là tổ hợp bắt buộc** — nhãn
  VI dài nhất (`Theo hệ thống`) gặp `textScaler` 2.0 ở màn hẹp nhất.
- **Trạng thái chọn MUST NOT chỉ được thể hiện bằng màu.** Radio có glyph riêng,
  nên yêu cầu này đã đạt bằng hình dạng — nhưng nó cũng là lý do S9 loại
  segmented button, vốn phân biệt bằng fill.
- **Trạng thái khoá (mặt 4) MUST NOT chỉ được thể hiện bằng màu.** Nhóm đang ghi
  phải đọc được là đang ghi qua screen reader, không chỉ nhạt đi.
- Mọi hàng chạm được MUST đạt `AppSpacing.minimumTouchTarget` (48dp).
  `RadioListTile` đạt sẵn qua `ListTileThemeData`, nhưng nó MUST được đo chứ
  không được giả định — `contentPadding: EdgeInsets.zero` của W5 chạm đúng vào
  con số đó.
- TalkBack: mỗi hàng đọc được **role** (radio), **value** (đang chọn / chưa
  chọn) và tên nhóm của nó. **Hai** nhóm — Appearance và Language — dùng chung
  nhãn `System` / `Theo hệ thống`, nên nhãn nhóm MUST vào cây semantics; nếu
  không, người dùng screen reader nghe `System` hai lần mà không biết cái nào
  là theme. (Study defaults không có lựa chọn `System`.)
- Thứ tự focus đi theo thứ tự đọc: nhóm 1 (trường → radio → Save) → nhóm 2 →
  nhóm 3 → reset.
- Đổi theme hoặc ngôn ngữ MUST áp ngay, MUST NOT nháy sang một theme thứ ba
  giữa chừng, và MUST NOT đưa người dùng về đầu màn hay về tab khác (BR-214,
  BR-215).
- Dải lỗi mang icon + chữ và là một `liveRegion` — nó xuất hiện trong lúc focus
  còn ở control vừa chạm.
- Hành động reset MUST NOT dùng chữ khiến nó bị nhầm với Reset learning progress
  (BR-217), và phụ đề của nó là câu nói rõ điều đó — nên phụ đề MUST hiện ở
  trạng thái nghỉ, không chỉ trong hộp xác nhận.
