# Hướng Dẫn Sử Dụng & Tài Liệu Kỹ Thuật Màn Hình Chính (Activity Dial Screen)

Tài liệu mô tả kiến trúc, các thành phần UI, luồng thao tác sử dụng và cách chạy thử nghiệm màn hình chính **Chấm — Màn hình chính (Wear OS Dial)** trong ứng dụng **Chăm**.

---

## 📁 Cấu Trúc Thư Mục

```text
mobile/lib/features/activity_dial/
├── data/
│   └── activity_local_storage.dart     # Lưu trữ local-first (SharedPreferences/JSON)
├── domain/
│   ├── activity_event_type.dart        # 19 loại thói quen phân bổ theo 3 quỹ đạo
│   └── activity_log.dart               # Bản ghi sự kiện (id, typeId, timestamp)
└── presentation/
    ├── activity_dial_controller.dart   # Riverpod Notifier quản lý state & logging
    ├── pages/
    │   └── activity_dial_page.dart     # Màn hình chính tích hợp toàn bộ UI
    └── widgets/
        ├── orbital_dial_widget.dart    # Vòng tròn quỹ đạo chính
        ├── orbital_dial_painter.dart   # CustomPainter vẽ các đường dashed ring
        ├── radial_dial_node.dart       # Nút thói quen có hiệu ứng co giãn (bounce scale)
        ├── center_cham_hub.dart        # Nút trung tâm "+ CHẤM" có ánh sáng hào quang
        ├── today_summary_card.dart     # Thẻ chào thứ trong tuần & đếm số chấm
        ├── today_logs_sheet.dart       # Modal xem lại lịch sử chấm & xóa bản ghi
        └── user_profile_sheet.dart     # Modal hồ sơ cá nhân & mã mời kết bạn
```

---

## 🎯 Đáp Ứng Yêu Cầu SRS (Software Requirements Specification)

| Mã yêu cầu | Mô tả chi tiết | Cách triển khai trên màn hình |
| :--- | :--- | :--- |
| **LOG-01** | Mỗi sự kiện có emoji và tên | `ActivityEventType` định nghĩa emoji, tên tiếng Việt và màu sắc riêng biệt. |
| **LOG-03** | Chạm nút tạo ngay bản ghi, không mở form | Chạm trực tiếp vào nút trên vòng xoay ghi nhận ngay lập tức với thời điểm hiện tại. |
| **LOG-04** | Không có Undo; chỉ cho phép xóa bản ghi | Nhật ký trong `TodayLogsSheet` cho phép xóa từng bản ghi, không hỗ trợ sửa nội dung/giờ. |
| **HIS-01** | Hiển thị lịch sử trong ngày & lần ghi gần nhất | `TodaySummaryCard` hiển thị số chấm hôm nay; `TodayLogsSheet` hiển thị danh sách chi tiết theo giờ. |
| **HIS-02** | Xóa bản ghi cập nhật lại lịch sử và số chấm | Xóa trong `TodayLogsSheet` sẽ tự động trừ tổng số chấm của ngày trong thời gian thực. |
| **DAT-01** | Lưu local-first, hoạt động khi offline | `ActivityLocalStorage` lưu trữ tức thì trên thiết bị, không bắt buộc có kết nối mạng. |
| **SOC-01** | Mã mời kết bạn cá nhân | `UserProfileSheet` cung cấp mã mời `CHAM-XXXXXX` để bạn bè kết nối qua QR. |

---

## 📱 Hướng Dẫn Sử Dụng Chi Tiết (User Guide)

### 1. Ghi Nhận Nhanh 1-Chạm (One-Tap Logging)
- **Thao tác:** Chạm trực tiếp vào bất kỳ nút thói quen nào trên vòng tròn quỹ đạo (ví dụ: `☕ Cà phê`, `💧 Uống nước`, `🏃 Chạy bộ`).
- **Phản hồi tức thì:**
  - Nút thói quen có hiệu ứng co giãn tự nhiên (scale bounce animation).
  - Xuất hiện thông báo nổi (Snackbar): `"Đã chấm: [Emoji] [Tên thói quen] (+1 chấm) — Đã lưu"`.
  - Huy hiệu số chấm hôm nay trên thẻ banner trên cùng tự động tăng thêm 1.

### 2. Bố Cục Vòng Tròn Quỹ Đạo (Orbital Dial)
Các thói quen được phân bổ trên 3 quỹ đạo đồng tâm xoay quanh nút trung tâm:
- **Tâm vòng tròn (`+ CHẤM`):** Nút màu cam san hô phát sáng; chạm vào mở nhanh lịch sử ngày hôm nay.
- **Quỹ đạo trong (Inner Ring - R1):** Các thói quen có tần suất cao trong ngày:
  - ☕ Cà phê, 💧 Uống nước, 🚽 Đi vệ sinh, 🚬 Thuốc lá, 🚶 Đi bộ.
- **Quỹ đạo giữa (Middle Ring - R2):** Các hoạt động sinh hoạt & làm việc:
  - 📖 Đọc sách, 🏋️ Tập gym, 😴 Đi ngủ, 🍫 Ăn vặt, 🧘 Thiền, ✍️ Học bài, 💻 Làm việc.
- **Quỹ đạo ngoài (Outer Ring - R3):** Các hoạt động thể thao, chăm sóc nhà cửa:
  - 🏃 Chạy bộ, 🛒 Đi chợ, 🪴 Tưới cây, 🚿 Tắm rửa, 🧹 Dọn dẹp, 🎵 Nghe nhạc, 💸 Chi tiêu.

### 3. Xem Lịch Sử Hôm Nay & Xóa Bản Ghi Nhầm
- **Cách mở:** 
  - Cách 1: Chạm vào thẻ banner **"HÔM NAY"** ở đầu màn hình.
  - Cách 2: Chạm vào nút tròn màu đen **FAB (Floating Action Button)** ở góc dưới bên phải.
  - Cách 3: Chạm vào nút tâm `+ CHẤM`.
- **Thao tác trong bảng lịch sử:**
  - Xem danh sách từng lần chấm kèm thời gian cụ thể (ví dụ: `14:25`).
  - Xem thống kê số lần của từng thói quen trong ngày.
  - **Xóa bản ghi:** Nhấn vào biểu tượng thùng rác màu đỏ cạnh bản ghi để xóa (hệ thống sẽ cập nhật lại số lượng ngay lập tức).

### 4. Xem Mã Mời Kết Bạn & Hồ Sơ Cá Nhân
- **Cách mở:** Chạm vào biểu tượng **Avatar tròn màu nâu đỏ** ở góc trên bên phải thanh tiêu đề.
- **Chức năng:**
  - Hiển thị tên hiển thị (`Tôi`), mã người dùng ẩn danh (UUID).
  - Hiển thị **Mã mời kết bạn** cá nhân (ví dụ: `CHAM-7K9M2P`).
  - Nút **"Sao chép mã"**: Copy mã vào clipboard để gửi cho bạn bè.

### 5. Cài Đặt Hệ Thống
- **Cách mở:** Chạm vào biểu tượng **Bánh răng cài đặt (⚙️)** ở góc trên bên phải.
- **Thông tin:** Hiển thị trạng thái hoạt động offline (`Local-First`), cơ chế ghi 1-chạm và tự động đồng bộ khi có Internet.

---

## 💻 Hướng Dẫn Kỹ Thuật & Chạy Ứng Dụng (Developer Guide)

### 1. Khởi Chạy Ứng Dụng
Di chuyển vào thư mục `mobile` và chạy Flutter:

```bash
cd mobile
flutter pub get
flutter run
```

### 2. Chạy Bộ Kiểm Thử (Unit & Widget Tests)
Để kiểm tra tính toàn vẹn của logic chấm điểm, tính toán chuỗi ngày và các tương tác UI:

```bash
cd mobile
flutter test test/activity_dial_test.dart
```

### 3. Cấu Hình Route Mặc Định Trong App
Màn hình được đặt làm màn hình khởi động tại [`mobile/lib/app.dart`](file:///c:/Users/admin/StudioProjects/Cham-ActivityLogWithPeople/mobile/lib/app.dart):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/activity_dial/presentation/pages/activity_dial_page.dart';

void main() {
  runApp(
    const ProviderScope(
      child: ChamApp(),
    ),
  );
}

class ChamApp extends StatelessWidget {
  const ChamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chăm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFB53216),
        scaffoldBackgroundColor: const Color(0xFFFAF6F0),
      ),
      home: const ActivityDialPage(),
    );
  }
}
```

---

## 🎨 Bảng Mã Màu Thiết Kế (Color Palette)

| Tên màu | Mã Hex | Vị trí áp dụng |
| :--- | :--- | :--- |
| **Nền chính (Warm Cream)** | `#FAF6F0` | Nền tổng thể của ứng dụng |
| **Thẻ thông tin (Off-white)** | `#FFFDF9` | Thẻ tóm tắt hôm nay, bottom sheet, modal |
| **Cam San Hô (Coral)** | `#FF6F52` / `#FF694A` | Dấu chấm logo, nút tâm `+ CHẤM`, badge "Đã lưu" |
| **Nâu Đỏ (Terracotta)** | `#A93B24` / `#B53216` | Avatar người dùng, viền điểm nhấn |
| **Chữ chính (Deep Charcoal)**| `#1F1A17` / `#2B221D` | Tiêu đề "Chấm", tên thói quen, số đếm |
| **Chữ phụ & Đường kẻ** | `#7D726A` / `#E8E0D5` | Nhãn phụ, các đường quỹ đạo nét đứt (dashed ring) |
| **Nút nổi FAB (Dark Circle)**| `#221C18` | Nút tròn mở nhanh lịch sử ở góc phải |

