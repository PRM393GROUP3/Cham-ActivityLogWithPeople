# Kế Hoạch & Kịch Bản Kiểm Thử Quy Trình Ứng Dụng (Workflow Test Guide)

Tài liệu này hướng dẫn chi tiết các kịch bản kiểm thử quy trình người dùng (User Workflows), kiểm thử điều hướng (Navigation Integration Tests) và quy trình tự động hóa kiểm thử (CI/CD Test Workflow) cho ứng dụng **Chăm**.

---

## 🧭 Bản Đồ Quy Trình Người Dùng (End-to-End User Flow)

```mermaid
flowchart TD
    Start([Khởi Động Ứng Dụng]) --> Home[🏠 Màn Hình Chính - Activity Dial]

    %% Flow 1: Ghi nhận nhanh
    Home -->|Chạm 1 nút thói quen| Toast[Hiển thị Toast: Đã chấm +1]
    Toast --> UpdateCount[Cập nhật số chấm hôm nay +1]
    Home -->|Chạm Banner Hôm nay / Nút FAB| History[📋 Bảng Lịch Sử Hôm Nay]
    History -->|Nhấn icon Thùng rác| DeleteLog[Xóa bản ghi & Trừ số chấm]
    History -->|Chạm công tắc Riêng tư| MakePublic[Chuyển Công khai → gửi lên server / chờ gửi khi offline]
    MakePublic -->|Chạm lại| MakePrivate[Về Riêng tư → thu hồi khỏi feed bạn bè]

    %% Flow 2: Vuốt sang Bảng tin
    Home -->|Vuốt sang trái / Bấm icon Bảng tin| Feed[👥 Bảng Tin Bạn Bè]
    Feed -->|Chạm Avatar Stories| FilterFeed[Lọc hoạt động theo bạn bè]
    Feed -->|Chạm emoji phản ứng| React[Thả / đổi / gỡ reaction 👍 ❤️ 🥰 😆 😮 😢 😡]
    Feed -->|Vuốt sang phải / Nút Back ←| Home

    %% Flow 3: Kết nối bạn bè QR
    Home & Feed -->|Chạm Avatar Profile| ProfileModal[👤 Hồ Sơ Ẩn Danh]
    ProfileModal -->|Bấm 'Mở Mã QR & Quét'| QRPage[📱 Màn Hình QR & Quét Bạn Bè]
    QRPage -->|Tab 1: Mã QR của tôi| MyQR[Xem mã QR cá nhân & Chia sẻ ảnh]
    QRPage -->|Tab 2: Quét mã QR| Scanner[Quét mã bạn bè / Nhập mã thủ công]
    Scanner -->|Nhập mã hợp lệ + xác nhận| AddFriendSuccess[Kết bạn ngay — SnackBar "Đã kết bạn với …"]
    QRPage -->|Nút Back ←| ProfileModal

    %% Flow 4: Cài đặt Widget
    Home & Feed -->|Chạm icon Bánh răng ⚙️| Settings[⚙️ Cài Đặt Ứng Dụng]
    Settings -->|Chọn 'Cài đặt Widget'| WidgetPage[🧩 Xem Trước & Cài Đặt Widget]
    WidgetPage -->|Chuyển tab 2x2 hoặc 4x2| PreviewWidget[Xem trước tương tác Widget]
    WidgetPage -->|Bấm 'Thêm Widget'| AddWidgetGuide[Modal hướng dẫn thêm vào Android Launcher]
    WidgetPage -->|Nút Back ←| Home
```

---

## 🧪 Ma Trận Kịch Bản Kiểm Thử Quy Trình (Workflow Test Cases)

### Kịch Bản 1: Ghi Nhận Nhanh 1-Chạm & Quản Lý Lịch Sử (Core Logging Flow)
* **Mục tiêu:** Kiểm tra khả năng tạo bản ghi tức thì không cần form (LOG-03) và xóa bản ghi không có Undo (HIS-02, LOG-04).

| Bước | Hành động | Kết quả kỳ vọng | Trạng thái |
| :---: | :--- | :--- | :---: |
| 1.1 | Mở ứng dụng vào màn hình chính `ActivityDialPage`. | Hiển thị 19 nút thói quen trên 3 vòng quỹ đạo, thẻ tổng kết ngày hôm nay và nút tâm `+ CHẤM`. | Đạt |
| 1.2 | Chạm vào nút `☕ Cà phê` trên quỹ đạo trong (R1). | Nút nảy hiệu ứng co giãn (bounce scale); xuất hiện Toast `Đã chấm: Cà phê (+1 chấm) — Đã lưu`; số chấm trên thẻ hôm nay tăng thêm 1. | Đạt |
| 1.3 | Chạm vào thẻ banner **"HÔM NAY"** hoặc nút tròn FAB đen ở góc dưới phải. | Mở `TodayLogsSheet` hiển thị danh sách các bản ghi của ngày hôm nay kèm giờ ghi nhận (ví dụ `14:30`). | Đạt |
| 1.4 | Nhấn biểu tượng thùng rác màu đỏ cạnh bản ghi vừa tạo. | Bản ghi bị xóa ngay lập tức; tổng số chấm hôm nay được tính lại tương ứng; không có nút Undo. | Đạt |
| 1.5 | Quan sát công tắc trên mỗi bản ghi mới. | Mọi bản ghi mới đều là **🔒 Riêng tư**; chưa có gì gửi lên server (SOC-03). | Đạt (test tự động) |
| 1.6 | Chạm công tắc **Riêng tư** của một bản ghi (đang online). | Đổi thành **🌐 Công khai**, dòng trạng thái *"Bạn bè đã thấy"*; bạn bè thấy bản ghi trong feed. | Đạt (test tự động + API) |
| 1.7 | Chạm công tắc **Công khai** để về Riêng tư. | Đổi thành **🔒 Riêng tư**; bản ghi biến mất khỏi feed bạn bè (SOC-04). | Đạt (test tự động + API) |

---

### Kịch Bản 2: Vuốt Chuyển Bảng Tin & Tương Tác Xã Hội (Feed & Reactions Flow)
* **Mục tiêu:** Kiểm tra cử chỉ vuốt ngang giữa Trang Chủ và Bảng Tin (SOC-04).

| Bước | Hành động | Kết quả kỳ vọng | Trạng thái |
| :---: | :--- | :--- | :---: |
| 2.1 | Tại màn hình chính, đặt ngón tay và vuốt từ phải sang trái (Swipe Left). | Màn hình trượt mượt mà sang `FeedPage` (Bảng tin hoạt động xã hội). | Đạt |
| 2.2 | Quan sát thanh lọc trên đầu Bảng tin và chạm vào một người bạn (vd. `Minh Thư`). | Thanh lọc lấy từ danh sách bạn bè thật; bảng tin chỉ hiển thị bản ghi Công khai của người đó. | Đạt (test tự động) |
| 2.3 | Chạm `❤️` trên thẻ hoạt động, rồi chạm `😆`, rồi chạm lại `😆`. | Lần 1 thả ❤️ (nền hồng `#FADCD9`, số đếm +1); lần 2 đổi sang 😆 (❤️ −1); lần 3 gỡ reaction. Mỗi người tối đa 1 reaction (AC-07). | Đạt (test tự động + API) |
| 2.3b | Thả reaction khi server từ chối (vd. mất mạng). | Reaction tự hoàn tác, hiện SnackBar báo lỗi. | Đạt (test tự động) |
| 2.4 | Vuốt từ trái sang phải (Swipe Right) hoặc chạm nút `←` trên Header. | Trượt mượt mà quay trở lại màn hình chính `ActivityDialPage`. | Đạt |

---

### Kịch Bản 3: Kết Nối Bạn Bè Bằng QR & Quét Mã (Friend Connection Flow)
* **Mục tiêu:** Kiểm tra hiển thị QR cá nhân và luồng quét QR kết bạn hai chiều (SOC-01).

| Bước | Hành động | Kết quả kỳ vọng | Trạng thái |
| :---: | :--- | :--- | :---: |
| 3.1 | Tại màn hình chính hoặc bảng tin, chạm vào icon Avatar tròn màu nâu đỏ. | Mở `UserProfileSheet` hiển thị tên và mã mời (10 ký tự); hiện *"Chưa có"* nếu chưa dùng tính năng xã hội lần nào. | Đạt |
| 3.2 | Chạm vào nút **"Mở Mã QR & Quét Bạn Bè"**. | Điều hướng vào màn hình `AddQrPage` với tab mặc định là **"Mã QR của tôi"**. | Đạt |
| 3.3 | Kiểm tra các thành phần trên thẻ QR. | Thấy tên, dòng `Mã mời: …` của tài khoản thật, hình QR dot-matrix kèm logo Chấm ở tâm, nút `Chia sẻ ảnh` và `Lưu vào máy`. Lần đầu mở khi mất mạng: thông báo cần mạng + nút **Thử lại**. | Đạt (test tự động) |
| 3.4 | Chạm tab **"Quét mã QR"**. | Chuyển sang giao diện máy quét với khung nhắm góc bo tròn và tia laser quét chuyển động lên xuống. | Đạt |
| 3.5 | Nhấn nút **"Bật đèn"**. | Nút đổi trạng thái thành **"Tắt đèn"** với màu nhấn cam sáng. | Đạt |
| 3.6 | Nhấn nút **"Nhập mã"**, gõ mã mời của một người khác và bấm **"Kết nối bạn bè"**. | Hộp thoại **"Kết bạn?"**; bấm **"Kết bạn"** → thành bạn ngay, SnackBar *"Đã kết bạn với …"*; feed hiện cả các bản Công khai cũ của người đó. Mã sai → SnackBar lỗi. | Đạt (test tự động + API) |
| 3.7 | Bấm nút `←` ở góc trên bên trái. | Quay lại màn hình trước đó. | Đạt |

---

### Kịch Bản 4: Cấu Hình Widget Màn Hình Chính (Widget Setup Flow)
* **Mục tiêu:** Kiểm tra giao diện xem trước và cấu hình widget ngoài màn hình chính (WID-01).

| Bước | Hành động | Kết quả kỳ vọng | Trạng thái |
| :---: | :--- | :--- | :---: |
| 4.1 | Tại thanh Header, chạm vào biểu tượng bánh răng cài đặt `⚙️`. | Hộp thoại cài đặt mở ra, có mục **"Cài đặt Widget (2×2, 4×2)"**. | Đạt |
| 4.2 | Chạm vào mục **"Cài đặt Widget"**. | Điều hướng vào màn hình `WidgetSelectionPage`. | Đạt |
| 4.3 | Chạm tab **"Nhỏ (2×2)"** và **"Vừa (4×2)"**. | Chuyển đổi mượt mà giữa bản xem trước widget 2x2 (chấm log nhanh 1 nút) và 4x2 (thống kê danh sách thói quen & chuỗi streak). | Đạt |
| 4.4 | Chạm nút **"Thêm Widget"**. | Hiển thị bảng hướng dẫn từng bước ghim widget ra màn hình chính Android. | Đạt |
| 4.5 | Bấm nút `←`. | Quay lại màn hình chính. | Đạt |

---

### Kịch Bản 5: Chia Sẻ Khi Mất Mạng (Offline Sharing Flow)
* **Mục tiêu:** Kiểm tra hàng đợi gửi (DAT-03, BR-02, AC-05).

| Bước | Hành động | Kết quả kỳ vọng | Trạng thái |
| :---: | :--- | :--- | :---: |
| 5.1 | Bật chế độ máy bay, chạm một nút thói quen. | Bản ghi Riêng tư được lưu ngay, Toast "Đã lưu" (AC-01). | Đạt (test tự động) |
| 5.2 | Mở lịch sử, chuyển bản ghi sang **Công khai**. | Công tắc đổi ngay; dòng trạng thái *"Chưa gửi được, sẽ thử lại"* (màu đỏ); nút **Thử lại** xuất hiện ở đầu bảng. | Đạt (test tự động) |
| 5.3 | Tắt app, tắt chế độ máy bay, mở lại app. | Bản ghi được gửi tự động với **thời điểm ghi gốc**; trạng thái *"Bạn bè đã thấy"*; bạn bè chỉ thấy **1** bản. | Đạt (test tự động) |
| 5.4 | Khi offline, chuyển Công khai rồi về Riêng tư, sau đó có mạng. | Chỉ gửi thao tác thu hồi; bạn bè không bao giờ thấy bản ghi. | Đạt (test tự động) |
| 5.5 | Xoá một bản ghi Công khai. | Bản ghi bị thu hồi khỏi feed bạn bè (BR-03). | Đạt (test tự động) |

> "Đạt (test tự động)" = được kiểm tra bằng `flutter test` với API giả; "+ API" = đã chạy thêm với backend local thật.
> Các bước chưa được chạy tay trên thiết bị Android thật.

---

## 🤖 Thực Thi Kiểm Thử Tự Động (Automated Testing Execution)

Tất cả các bài kiểm thử tự động đã được lập trình đầy đủ bằng Flutter Test Framework.

### 1. Lệnh Chạy Toàn Bộ Test Suite
Di chuyển vào thư mục `mobile` và chạy:

```bash
cd mobile
flutter test
```

### 2. Chi Tiết Các Tệp Kiểm Thử Thành Phần

**Mobile** (`cd mobile`). Các test gọi API dùng bản giả trong `test/helpers/fakes.dart`, không cần backend.

| Tệp kiểm thử | Phạm vi kiểm tra |
| :--- | :--- |
| [`main_navigation_test.dart`](../mobile/test/main_navigation_test.dart) | Vuốt ngang trang chủ ⇄ feed (dữ liệu feed/bạn bè từ API giả), điều hướng hồ sơ → QR |
| [`activity_dial_test.dart`](../mobile/test/activity_dial_test.dart) | 19 loại sự kiện trên 3 quỹ đạo; serialization bản ghi; bản ghi mới / bản cũ đều Riêng tư |
| [`today_logs_sheet_test.dart`](../mobile/test/today_logs_sheet_test.dart) | Công tắc Riêng tư ⇄ Công khai, trạng thái gửi, nút Thử lại (NFR-03) |
| [`sharing_test.dart`](../mobile/test/sharing_test.dart) | Hàng đợi gửi: gộp theo bản ghi, còn sau khi mở lại app, gửi lại khi có mạng, thu hồi khi xoá (DAT-03, BR-02, BR-03, AC-05) |
| [`feed_test.dart`](../mobile/test/feed_test.dart) | Bộ 7 reaction, parse `/api/feed`, thả/đổi/gỡ + hoàn tác khi lỗi, kết bạn bằng mã |
| [`add_qr_test.dart`](../mobile/test/add_qr_test.dart) | Tab Mã QR / Quét mã; mã mời thật từ tài khoản; offline lần đầu; nhập mã → kết bạn ngay |
| [`core_utils_test.dart`](../mobile/test/core_utils_test.dart) | Giờ Việt Nam UTC+7 (AC-08), thời gian tương đối, UUID v4 |
| [`widget_selection_test.dart`](../mobile/test/widget_selection_test.dart) | Xem trước widget 2x2, 4x2 và modal hướng dẫn |

Chạy riêng một tệp: `flutter test test/<tên_tệp>.dart`

**Backend** (`cd backend && npm test`, chạy trong Workers runtime với D1 tạm):

| Tệp kiểm thử | Phạm vi kiểm tra |
| :--- | :--- |
| [`users.test.ts`](../backend/test/users.test.ts) | Đăng ký ẩn danh và xác thực bằng token, từ chối token sai, tên trống |
| [`friends.test.ts`](../backend/test/friends.test.ts) | Kết bạn trực tiếp bằng mã (idempotent, không phân biệt hoa thường), từ chối mã của mình / mã sai / mã đã đổi, huỷ kết bạn 2 chiều |
| [`shares.test.ts`](../backend/test/shares.test.ts) | Công khai cho tất cả bạn bè, chặn chọn người nhận, gửi lại không trùng, thu hồi, bạn mới thấy bản cũ, phân trang, 7 reaction |

---

## ⚙️ Tích Hợp Quy Trình CI/CD Tự Động (.github/workflows)

Để đảm bảo mọi Pull Request vào `main-onlymerge` đều được tự động chạy toàn bộ các bài kiểm thử giao diện và luồng điều hướng, tệp cấu hình GitHub Actions cho Mobile được thiết lập như sau:

Tạo tệp `.github/workflows/mobile.yml`:

```yaml
name: Mobile CI

on:
  push:
    branches: [ main-onlymerge ]
  pull_request:
    branches: [ main-onlymerge ]

jobs:
  test:
    name: Run Flutter Tests & Lints
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Install Dependencies
        working-directory: mobile
        run: flutter pub get

      - name: Analyze Project
        working-directory: mobile
        run: flutter analyze

      - name: Run Widget & Navigation Tests
        working-directory: mobile
        run: flutter test
```
