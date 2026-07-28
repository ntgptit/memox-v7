# Product requirements — memox

_Status: draft — awaiting confirmation on the items marked **[cần xác nhận]** ·
Last updated: 2026-07-28_

## Problem

Người học từ vựng quên phần lớn những gì vừa học nếu ôn tập không đúng thời
điểm. Ôn thủ công bằng sổ tay hoặc file không cho biết *khi nào* cần ôn lại từ
nào, nên người học hoặc ôn quá sớm (lãng phí) hoặc quá muộn (đã quên).

## Target users

| Group | Context | What they need | Not the target |
|---|---|---|---|
| Người tự học từ vựng | Học lẻ trên điện thoại, thời gian rời rạc, kết nối không ổn định | Ôn đúng thời điểm, dùng được mọi lúc kể cả offline | Lớp học có giáo viên quản lý |
| Người ôn thi | Khối lượng từ lớn, có deadline | Theo dõi tiến độ, ưu tiên từ sắp quên | Người cần nội dung biên soạn sẵn |

**[cần xác nhận]** Người dùng tự tạo nội dung, hay app cần cung cấp bộ từ có sẵn?
Điều này quyết định có cần import/export và nguồn nội dung ban đầu hay không.

## Core value

Ôn đúng từ vào đúng thời điểm, hoạt động đầy đủ khi không có mạng.

## Platform decisions

| Decision | Choice | Consequence |
|---|---|---|
| Android | **có** — target duy nhất của bản release đầu | min SDK 23+ (yêu cầu của `flutter_secure_storage` khi cần sau này) |
| iOS | **hoãn** — sau khi Android ổn định về UX, Drift migration, test | Không cần macOS runner trong CI giai đoạn đầu → tiết kiệm runner minutes |
| Web | **chỉ dùng cho development** | Review UI và chạy E2E/visual regression bằng Flutter Web + Playwright. **Không phải production target** — không tối ưu responsive cho desktop, không phát hành |
| Desktop | không | ngoài phạm vi hiện tại |
| Data posture | **local-first, backend-ready** | Drift là source of truth. Xem `architecture.md` |
| Authentication | **không có ở MVP, kiến trúc auth-ready** | Một local profile trên thiết bị. Xem `architecture.md` |
| Roles & permissions | không, kể cả sau khi có auth | Chỉ một loại user khi backend xuất hiện |

Hệ quả quan trọng của việc Web là dev-only: nó là **công cụ test**, không phải
target. Nghĩa là không đánh đổi thiết kế Android để Web đẹp hơn, nhưng cũng
không được dùng plugin chặn Web build — nếu Web không build được thì mất luôn
kênh E2E.

## Sensitive data

| Data | Why sensitive | Protection |
|---|---|---|
| Nội dung deck/card người dùng tạo | Dữ liệu cá nhân, có thể chứa thông tin riêng tư | Chỉ nằm trên thiết bị ở giai đoạn MVP. Không log nội dung card ở bất kỳ level nào |
| Lịch sử ôn tập | Suy ra được thói quen sử dụng | Không gửi ra ngoài ở MVP; không đưa vào analytics |
| Auth token | — | Chưa tồn tại ở MVP. Khi có backend: `flutter_secure_storage`, xoá khi logout |

Ở MVP không có dữ liệu rời khỏi thiết bị, nên rủi ro chủ yếu là **log**. Nguyên
tắc: không log nội dung card, kể cả ở `debug`. Log ID thì được.

**Chưa cần** mã hoá database ở MVP — dữ liệu học từ vựng không đủ nhạy cảm để
trả giá bằng độ phức tạp của SQLCipher. Đây là quyết định cần xem lại nếu sau
này app lưu ghi chú cá nhân tự do.

---

# MVP scope

Nguyên tắc: MVP là **một vertical slice chạy được từ Drift đến màn hình**, đủ để
chứng minh kiến trúc local-first và migration hoạt động. Không phải bản đầy đủ
tính năng.

## Must-have

| # | Feature | Done when |
|---|---|---|
| M1 | Tạo/sửa/xoá deck | Deck tồn tại sau khi restart app; xoá deck xoá cascade toàn bộ card của nó |
| M2 | Tạo/sửa/xoá card trong deck | Card có mặt trước/sau; sửa không làm mất lịch sử ôn tập |
| M3 | Phiên ôn tập theo lịch SRS | Chỉ hiện card đến hạn; đánh giá kết quả cập nhật lịch ôn lần sau |
| M4 | Danh sách deck với tiến độ | Mỗi deck hiện số card đến hạn hôm nay |
| M5 | Hoạt động đầy đủ offline | Bật chế độ máy bay, mọi chức năng trên vẫn chạy bình thường |

## Should-have

| # | Feature | Done when |
|---|---|---|
| S1 | Tìm kiếm card trong deck | Tìm theo nội dung mặt trước/sau |
| S2 | Thống kê ôn tập cơ bản | Số card đã ôn, streak theo ngày |
| S3 | Đảo chiều card (nghĩa → từ) | Ôn được cả hai chiều |

## Nice-to-have

| # | Feature | Notes |
|---|---|---|
| N1 | Import/export CSV | Phụ thuộc câu hỏi về nguồn nội dung ở trên |
| N2 | Nhắc nhở ôn tập hằng ngày | Cần notification permission |
| N3 | Tag/phân loại card | |

## Explicitly out of MVP

| Feature | Why deferred | Revisit when |
|---|---|---|
| Đăng nhập / tài khoản | Không có backend; thêm auth lúc này là xây UI cho thứ chưa dùng được | Khi Spring Boot backend sẵn sàng |
| Đồng bộ đa thiết bị | Cần backend và conflict resolution | Cùng lúc với auth |
| iOS | Ổn định Android trước để tránh sửa lỗi trên hai nền tảng cùng lúc | Sau khi Android ổn định về UX + migration + test |
| Phân quyền theo role | Chỉ có một loại user, kể cả sau khi có auth | Chưa có kế hoạch |
| Chia sẻ deck giữa người dùng | Cần backend | Sau đồng bộ |
| Audio / hình ảnh trong card | Kéo theo lưu trữ file, đồng bộ file, nén ảnh — một khối lượng riêng | Sau MVP |

## Primary business flows

1. **Tạo nội dung**: mở app → tạo deck → thêm card → deck xuất hiện trong danh
   sách với số card đến hạn.
2. **Ôn tập** (luồng chính, chạy hằng ngày): mở app → thấy deck có card đến hạn
   → vào phiên ôn → xem mặt trước → lật → tự đánh giá → card được xếp lịch lại →
   hết card đến hạn → tổng kết phiên.

Luồng 2 là vertical slice đầu tiên nên xây, vì nó chạm vào toàn bộ chiều sâu
kiến trúc: Drift query có index theo hạn ôn, business logic SRS ở domain, state
matrix đầy đủ ở presentation (kể cả empty — "hôm nay không còn gì để ôn", là
trạng thái người dùng gặp thường xuyên nhất sau vài tuần).

## Câu hỏi mở — chặn T1.2 (use cases)

1. **[cần xác nhận]** **Thuật toán SRS nào?** Ảnh hưởng trực tiếp đến schema
   (cột nào cần lưu trên mỗi card) và business rules:
   - **Leitner** (hộp 1–5, nhân đôi khoảng cách): đơn giản nhất, dễ test, dễ
     giải thích cho người dùng.
   - **SM-2** (thuật toán kinh điển của Anki): cần lưu `easeFactor`, `interval`,
     `repetitions`. Cân bằng tốt giữa hiệu quả và độ phức tạp.
   - **FSRS**: hiện đại và chính xác hơn, nhưng nhiều tham số và khó test hơn
     đáng kể.

   Với mục tiêu "chạy ổn định, test ổn định trước khi làm backend", tôi nghiêng
   về **SM-2**: đủ tốt để dùng thật, thuần tuý là hàm thuần khiết nên unit test
   rất sạch, và có thể đổi sang FSRS sau nếu tách đúng thành một `use_case`.
2. **[cần xác nhận]** Người dùng tự tạo nội dung hay cần bộ từ có sẵn?
3. **[cần xác nhận]** Thang đánh giá khi ôn: 2 mức (nhớ/quên) hay 4 mức (Again/
   Hard/Good/Easy)? SM-2 thường dùng 4 mức.
