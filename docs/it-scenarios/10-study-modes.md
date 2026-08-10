# Kịch bản IT — Sáu chế độ học

| | |
|---|---|
| **Status** | active |
| **Purpose** | Chứng minh từng cách hỏi có đúng thao tác, kết cục và những hành vi bị cấm đã chốt; không làm lẫn chế độ học với thuật toán xếp lịch |
| **Scope** | Khung phiên dùng chung, `Browse`, `Self assess`, `Match`, `Guess`, `Recall`, `Fill`, trạng thái sau trả lời và hỗ trợ tiếp cận cơ bản |
| **Source of truth for** | Kịch bản IT về hành vi nhìn thấy của sáu chế độ học |
| **Depends on** | `README.md`, `00-agent-execution-guide.md`, `../business-rules.md` (BR-99, BR-106…138, BR-153), `../wireframes/m5-study-modes.md`, `../use-cases.md` (UC-05) |
| **Updated by task** | Bổ sung kịch bản IT cho chức năng học, rà soát đệ quy ba vòng và chuẩn hóa tiếng Việt ngày 2026-08-08 |
| **Last updated** | 2026-08-08 |

## IT-MODE-001 — Khung phiên luôn nói rõ chế độ, bộ thẻ, loại phiên và tiến độ

- **Ưu tiên:** P1
- **Tiền điều kiện:** `S-STUDY-MIXED-EB-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Mở Học mới và quan sát thanh trên/dòng ngữ cảnh | Có nút đóng ✕, nhãn `Browse`, tên bộ thẻ, loại phiên Học mới và tiến độ chỉ của tập `New` |
| 2 | Chuyển giai đoạn trong phiên học mới | Nhãn chế độ, ngữ cảnh và tiến độ đổi theo giai đoạn nhưng vẫn giữ đúng bộ thẻ và phiên |
| 3 | Chủ động thoát, mở Ôn tập và chọn `Recall` | Cùng khung nhưng loại phiên là Ôn tập; tiến độ chỉ của tập `Due` và vị trí số đếm được thay bằng đồng hồ `Recall` |
| 4 | Quan sát màu trước và sau một kết cục | Màu thành công/nguy hiểm chỉ xuất hiện cho kết quả đúng/sai, không dùng làm màu nhận diện chế độ trước khi trả lời |

## IT-MODE-002 — `Browse` hiện hai mặt cùng lúc, đi tiếp và xem lại bằng vuốt

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; chọn Học mới để vào Browse.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát thẻ | Mặt trước và mặt sau cùng hiện trong **một** thẻ, phân tách bằng đường kẻ và nhãn Mặt trước/Mặt sau |
| 2 | Quan sát nhãn chế độ | Nhãn là `Browse`, không phải `Review` |
| 3 | Kiểm tra hành động | Không có lật thẻ, hành động xếp lịch, nút Tiếp tục/Quay lại nhìn thấy được, biểu tượng loa hoặc biểu tượng sửa thẻ |
| 4 | Vuốt sang trái | Tiến đúng một điểm dừng; không hiện phán quyết đúng/sai |
| 5 | Vuốt sang phải | Hiện lại thẻ đã qua trong cùng round; điểm dừng và tiến độ **không** đổi |
| 6 | Vuốt trái trở lại thẻ đang sống rồi vuốt trái lần nữa | Chỉ tiến một điểm dừng; thẻ đã xem lại **không** bị ghi lượt thứ hai |
| 7 | Duyệt bằng trình đọc màn hình | Có custom action tương đương cho Tiếp tục và Thẻ trước; Thẻ trước chỉ xuất hiện khi có chỗ để lùi |

**Bước 3 và 4 từng nói ngược với BR-155.** Bảng cũ ghi "không có vuốt lùi" và
"chạm Tiếp tục", trong khi BR-155 bắt buộc `browse` — và chỉ `browse` — cho xem
lại thẻ đã qua bằng vuốt hoặc một control tương đương, còn BR-111 thì không cho
mode này có bất kỳ hành động chấm điểm nào. Cái không tồn tại là **nút** Tiếp
tục, không phải thao tác đi tiếp.

## IT-MODE-003 — `Match` giữ nguyên bàn và phân biệt ba trạng thái ô

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng giao diện tới `Match` với năm cặp.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn một thuật ngữ | Ô thuật ngữ chuyển sang trạng thái đang chọn; các ô không dịch vị trí |
| 2 | Chọn đúng ý nghĩa | Cả cặp ở lại đúng vị trí, có dấu đúng/mờ đi và không bấm lại được |
| 3 | Ghép cặp khác | Cặp đã xong không biến mất khiến hàng dưới dồn lên |
| 4 | Dựng lại giao diện nhẹ bằng xoay màn hình hoặc đưa ứng dụng ra trước nếu hồ sơ cho phép | Dấu cặp đã ghép vẫn còn trong cùng vòng |

## IT-MODE-004 — `Match` quy kết lượt cho thuật ngữ được chọn trước và giữ thẻ sai sang vòng sau

> **Tách thành** — `IT-MODE-004` (`HOST-WIDGET`) · `IT-MODE-004F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng giao diện tới vòng 1 của `Match`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn thuật ngữ của `ST-01`, rồi chọn nhầm ý nghĩa của `ST-02` | Kết quả sai thuộc `ST-01`; ý nghĩa của `ST-02` không làm `ST-02` bị đánh dấu là thẻ sai |
| 2 | Sau đó ghép đúng `ST-01`; tiếp tục làm sai rồi ghép đúng thuật ngữ `ST-03` | Hai cặp có thể hoàn tất nhưng `ST-01` và `ST-03` vẫn thuộc tập không đạt của vòng |
| 3 | Hoàn tất đúng các cặp còn lại | Vòng sau có đúng hai thẻ `ST-01`/`ST-03`, không trùng; `ST-02` không bị kéo vào vì ý nghĩa của nó từng bị chọn nhầm |
| 4 | Quan sát phản hồi và ngữ cảnh trong cả vòng | Chỉ có đúng/sai, không có `Almost`; ngữ cảnh dùng nhãn Vòng và số cặp còn lại, không dùng khái niệm Bàn |

## IT-MODE-005 — `Guess` luôn có đúng năm lựa chọn khác nghĩa và chỉ nhận lần chạm đầu

> **Tách thành** — `IT-MODE-005` (`HOST-WIDGET`) · `IT-MODE-005F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng UI tới Guess với năm `back_folded` khác nhau.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát câu hỏi | Có đúng năm lựa chọn A–E; đáp án đúng xuất hiện đúng một lần |
| 2 | Chọn một đáp án sai | Đáp án đúng hiện trạng thái thành công/✓, lựa chọn sai đã chọn hiện trạng thái nguy hiểm/✕, ba lựa chọn khác mờ |
| 3 | Chạm tiếp lựa chọn khác nhiều lần | Không thay đổi kết cục và không sinh lượt thứ hai |
| 4 | Sang câu kế | A–E phản ánh vị trí hiển thị mới, không được dùng như định danh thẻ |

## IT-MODE-006 — `Guess` bị bỏ qua khi cả tập phiên không đủ năm nghĩa

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-4`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Bắt đầu Học mới và hoàn tất `Match` | Hệ thống đánh giá điều kiện trên tập bốn thẻ của phiên |
| 2 | Quan sát giai đoạn kế | Toàn bộ giai đoạn `Guess` bị bỏ qua như trạng thái bình thường; không hiển thị câu hỏi chỉ có 2–4 lựa chọn |
| 3 | Tiếp tục tới `Recall` | Không có lỗi và không thẻ nào bị loại khỏi các giai đoạn khác |

## IT-MODE-007 — Thứ tự thẻ và lựa chọn ổn định khi Tiếp tục nhưng là hai hoán vị độc lập

- **Ưu tiên:** P1
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng giao diện tới `Guess`; có thể khởi động lại giữa lượt.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ghi thứ tự thẻ của vòng và thứ tự năm lựa chọn ở câu hiện tại | Có hai chuỗi làm mốc so sánh |
| 2 | Đưa ứng dụng xuống nền/ra trước, rồi khởi động lại tiến trình và chọn Tiếp tục | Thẻ hiện tại và năm lựa chọn giữ nguyên thứ tự |
| 3 | Sang vòng mới | Thứ tự thẻ được xáo riêng cho vòng mới |
| 4 | So các chuỗi | Đổi thứ tự thẻ không kéo theo cùng một hoán vị cho lựa chọn; hai thứ không khóa cứng vào nhau |

## IT-MODE-008 — `Recall` đo 20 giây tương tác, lật thủ công trước hạn được ưu tiên

> **Tách thành** — `IT-MODE-008` (`HOST-WIDGET`) · `IT-MODE-008F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi bằng giao diện tới một lượt `Recall` mới; đo được đồng hồ.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát lượt mới | Đáp án ẩn có nhãn ngữ nghĩa; thanh trên hiện tối đa 20 giây |
| 2 | Chờ một khoảng khi ứng dụng ở phía trước | Thời gian giảm theo thời gian tương tác; thời gian tải nội dung không bị tính vào lượt |
| 3 | Chạm Hiện đáp án trước hạn | Mặt sau hiện ra và kết cục được chốt một lần, không còn hành động khác để đổi |
| 4 | Quan sát trạng thái sau khi lật | Có lời xác nhận lượt đã chốt; màn hình không giống bị treo và chỉ vòng sau mới bắt đầu lại 20 giây |

## IT-MODE-009 — `Recall` hết giờ tự lật, khóa kết cục sai và giữ thời gian khi Tiếp tục

> **Tách thành** — `IT-MODE-009` (`HOST-WIDGET`) · `IT-MODE-009F` (`HOST-FLOW`). Lý do và ranh giới ở
> [`12-testing-pyramid-audit.md`](12-testing-pyramid-audit.md) mục C.

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-EB-5-FULL`; đi tới `Recall`, giữ ứng dụng ở phía trước tới khi đồng hồ nằm trong `12.0…12.8` giây; chưa lật.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Đưa ứng dụng xuống nền 5 giây rồi ra trước | Đồng hồ giảm không quá 1 giây do chuyển trạng thái; không mất 5 giây ở nền |
| 2 | Đóng tiến trình và chọn Tiếp tục trong cùng ngày | Quay đúng lượt, đáp án vẫn ẩn và đồng hồ tiếp tục từ thời gian còn lại, không đặt lại 20 giây |
| 3 | Không thao tác tới đúng hạn | Hệ thống tự lật, nói rõ đã hết giờ và chốt kết cục sai |
| 4 | Chạm vùng Hiện đáp án cũ hoặc thao tác lặp | Không đổi sang đúng và không sinh lượt thứ hai |

## IT-MODE-010 — `Fill` bỏ khoảng trắng, không phân biệt hoa thường nhưng giữ dấu; ô nhập rỗng không tiến lượt

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-FILL-V2`; ba nhánh rỗng/hoa-thường/dấu nạp lại bộ dữ liệu sạch và mở Ôn tập > `Fill`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở nhánh rỗng, để trống hoặc nhập chỉ khoảng trắng rồi chạm Kiểm tra | Không ghi kết cục, không tiến độ; lỗi/hướng dẫn nằm tại ô nhập |
| 2 | Nạp lại bộ dữ liệu; nhập `  cÔnG  ` rồi chạm Kiểm tra | Được chấm đúng do bỏ khoảng trắng hai đầu và hạ chữ hoa/thường theo Unicode |
| 3 | Nạp lại bộ dữ liệu; nhập `cong` rồi chạm Kiểm tra | Bị chấm sai vì chính sách giữ dấu |
| 4 | Khởi động lại sau nhánh sai | Kết quả đã chấm còn hiệu lực; nội dung thô người dùng gõ không được điền lại như một câu trả lời đã lưu |

## IT-MODE-011 — Gợi ý không tự đổi kết quả và `Fill` chỉ nhận một lần gửi

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-FILL-V2`; mở Ôn tập và chọn `Fill`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chạm Gợi ý | Gợi ý xuất hiện; tiến độ và lịch chưa đổi |
| 2 | Nhập đáp án sai rồi chạm Kiểm tra | Kết quả vẫn sai; dùng gợi ý không biến nó thành đúng |
| 3 | Quan sát trạng thái sau chấm | Ô nhập đóng; hiện mặt sau thật của thẻ cùng trạng thái sai, không mời nhập lại trong cùng lượt |
| 4 | Chạm Kiểm tra lặp hoặc cố sửa ô nhập | Không sinh lần gửi/kết cục thứ hai |

## IT-MODE-012 — `Self assess` chỉ hiện hành động sau khi người dùng lật

- **Ưu tiên:** P0
- **Tiền điều kiện:** `SETUP-STUDY-ALL-MODES`; ở bộ thẻ gốc SM-2, chọn Học mới và đi hết `Browse` để tới `Self assess`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Quan sát ban đầu | Chỉ mặt trước và hành động lật; mặt sau cùng bốn hành động đều chưa hiện |
| 2 | Chạm lật | Mặt sau và `Again`/`Hard`/`Good`/`Easy` cùng xuất hiện |
| 3 | Chọn một hành động | Chỉ hành động người dùng chọn được dùng; giao diện khóa trong lúc ghi để chống bấm đôi |
| 4 | Ở một bộ thẻ Eight Box, mở màn chọn Ôn tập | Không có `Self assess` và không xuất hiện bốn nút SM-2; Eight Box chỉ đưa bốn chế độ chấm nhị phân đã định nghĩa |

## IT-MODE-013 — Các chế độ học dùng được với trình đọc màn hình và cỡ chữ lớn

- **Ưu tiên:** P1
- **Tiền điều kiện:** `SETUP-STUDY-ALL-MODES`; bật được dịch vụ hỗ trợ tiếp cận/trình đọc màn hình Android; cỡ chữ 200%.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Duyệt thanh trên bằng trình đọc màn hình | Đọc được nút đóng phiên, chế độ, ngữ cảnh và tiến độ/đồng hồ bằng chữ; không chỉ bằng màu/biểu tượng |
| 2 | Duyệt `Match`/`Guess` | Mỗi lựa chọn có nhãn rõ; A–E không che nghĩa; trạng thái được chọn/đúng/sai/bị vô hiệu hóa được đọc |
| 3 | Duyệt `Recall`/`Fill` | Đọc được “đáp án đang ẩn”, đồng hồ, gợi ý, ô nhập và kết cục sau chấm |
| 4 | Quan sát ở cỡ chữ 200% | Nội dung quan trọng không bị cắt, chồng hoặc đẩy hành động ra ngoài màn; có thể cuộn tới mọi hành động |

## IT-MODE-014 — `Guess` chặn nguyên tử nếu một câu hỏi bất ngờ thiếu phương án nhiễu

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-GUESS-BLOCKED-V2`; màn chọn đã xác nhận `Guess` khả dụng.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Chọn `Guess` và đi tới câu hỏi bị bộ tạo lỗi tác động | Màn chặn có nội dung rõ; không hiển thị câu hỏi dưới năm lựa chọn |
| 2 | Quan sát tiến độ trên màn chặn | Thẻ hiện tại, điểm dừng và tiến độ chưa đổi; câu hỏi không bị tự bỏ qua |
| 3 | Kiểm tra mọi hành động trên màn chặn | Chỉ có đường rời phiên; không có Thử lại/Tiếp tục/Bỏ qua làm tiến điểm dừng trái BR-124 |
| 4 | Rời phiên, tắt lỗi, bắt đầu một phiên `Guess` mới | Câu hỏi mới dựng được với đúng năm lựa chọn; chỉ lựa chọn của người dùng trong phiên mới được chấm |

## IT-MODE-015 — `Guess` chỉ lấy phương án nhiễu hợp lệ trong cùng cây mà không lộ thẻ mới

- **Ưu tiên:** P0
- **Tiền điều kiện:** `S-STUDY-GUESS-SOURCE-V2`.

| Bước | Thao tác người dùng | Kết quả mong đợi |
|---|---|---|
| 1 | Ở bộ thẻ gốc A, chọn Ôn tập rồi `Guess` | Phiên có câu hỏi của thẻ `Due`; bốn thẻ đã học nhưng chưa đến hạn trong cùng cây có thể làm nguồn nhiễu dù không nằm trong hàng đợi ôn tập |
| 2 | Ghi năm nghĩa trên câu hỏi | Có đáp án đúng đúng một lần và bốn phương án nhiễu tham chiếu bốn thẻ khác thẻ đang hỏi |
| 3 | Đối chiếu với bộ dữ liệu dựng sẵn | Không có `new-only-secret` và không có `other-root-secret`; chức năng học không làm lộ thẻ `New` hoặc lấy nội dung từ bộ thẻ gốc khác |
| 4 | Kiểm tra cặp nghĩa chỉ khác hoa/khoảng trắng | Chỉ tối đa một biến thể xuất hiện; năm lựa chọn luôn khác nhau theo `back_folded`, không chỉ khác chuỗi hiển thị |
