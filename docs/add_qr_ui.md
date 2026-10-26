# Friend Connection & Add QR UI Documentation

This document describes the architecture, reusable components, data models, and integration guide for the **Add QR & Scanner Screen** (`AddQrPage`) in the **Chăm** application.

---

## 📁 Directory Structure

```text
mobile/lib/features/friends/
├── domain/
│   ├── friend.dart                    # Friend { id, displayName, since }
│   ├── invite_qr.dart                 # InviteQr: nội dung QR `CHAM:<mã>`, encode / decode
│   └── qr_code_data.dart              # QrCodeData: dữ liệu hiển thị trên thẻ QR
├── data/
│   └── friends_api.dart               # GET/POST /api/friends, DELETE /api/friends/:userId
└── presentation/
    ├── controllers/
    │   └── friends_controller.dart    # FriendsController (AsyncNotifier): danh sách, add(code), remove(id)
    ├── pages/
    │   ├── add_qr_page.dart           # Màn hình QR của tôi + quét / nhập mã
    │   └── friends_page.dart          # Danh sách bạn bè, huỷ kết bạn
    └── widgets/
        ├── custom_qr_view.dart        # QR chuẩn (qr_flutter), chấm tròn + logo, mức sửa lỗi H
        └── qr_scanner_view.dart       # Camera (mobile_scanner), đèn, quét từ ảnh, nhập mã
```

---

## 1. Data Model (`domain/qr_code_data.dart`)

### `QrCodeData`
Represents the personal QR profile information of the current user.

```dart
class QrCodeData {
  final String displayName;
  final String username;
  final String inviteCode;
  final String? avatarUrl;
  final String instruction;

  const QrCodeData({
    required this.displayName,
    required this.username,
    required this.inviteCode,
    this.avatarUrl,
    this.instruction = 'Đưa mã này để bạn bè quét kết nối một chạm.',
  });

  QrCodeData copyWith({
    String? displayName,
    String? username,
    String? inviteCode,
    String? avatarUrl,
    String? instruction,
  });
}
```

---

## 2. Reusable Widgets

### A. `CustomQrView` (`widgets/custom_qr_view.dart`)
Renders a custom canvas-painted QR code matching Chăm's dot-matrix aesthetic.

- **Finder Patterns:** 3 corner position markers (outer rounded square frame + inner rounded dot).
- **Dot-Matrix:** Circular modules deterministically arranged by the seed of `data`.
- **Center Logo Badge:** Coral/terracotta circle (`#E85835`) with white border and touch gesture icon (`Icons.touch_app_rounded`).

#### Parameters
| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `data` | `String` | Required | Content/invite code to encode into the QR visual. |
| `size` | `double` | `240` | Width and height of the QR container in logical pixels. |
| `onTap` | `VoidCallback?` | `null` | Tap callback (e.g. to copy code or show details). |

#### Usage
```dart
CustomQrView(
  data: 'H4R7N2Q8ZK',
  size: 240,
  onTap: () => print('QR tapped'),
)
```

---

### B. `QrScannerView` (`widgets/qr_scanner_view.dart`)
Renders an interactive QR scanner interface for the **"Quét mã QR"** tab.

- **Animated Laser Sweep:** Vertical laser line sweeping back and forth inside the viewfinder.
- **Viewfinder Guides:** 4 rounded corner indicators.
- **Quick Action Pills:**
  - `Bật đèn / Tắt đèn`: Toggles camera flash simulation.
  - `Chọn ảnh`: Select QR photo from device gallery.
  - `Nhập mã`: Opens a bottom sheet for manual invite code entry.

#### Parameters
| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `onCodeScanned` | `ValueChanged<String>` | Required | Invoked when a code is scanned or submitted manually. |
| `animateLaser` | `bool` | `true` | Enables laser sweep animation (set `false` in tests). |

#### Usage
```dart
QrScannerView(
  onCodeScanned: (String code) {
    print('Scanned code: $code');
  },
)
```

---

### C. `AddQrPage` (`pages/add_qr_page.dart`)
The main container screen integrating the top app bar, segmented tab switch, and tab content.

#### Features
1. **App Bar:** Back navigation arrow, screen title *"Chi Tiết Khoảnh Khắc"*, and user avatar action button.
2. **Segmented Tabs:**
   - `Mã QR của tôi`: thẻ hồ sơ với tên, **mã mời thật** của tài khoản ẩn danh (`Mã mời: …`), **QR chuẩn** chứa `CHAM:<mã>`, nút `Sao chép mã`, `Lưu ảnh QR` (chụp vùng QR + mã mời thành PNG qua `pngSaverProvider`: Android → thư viện ảnh bằng `gal`, Web → tải file) và `Đổi mã mời`.
     Lần đầu mở, trang tự đăng ký tài khoản (cần mạng); khi đang đăng ký hiện vòng xoay, lỗi mạng hiện thông báo + nút **Thử lại**.
   - `Quét mã QR`: giao diện máy quét. Nhập hoặc quét mã → hộp xác nhận **"Kết bạn"** → `POST /api/friends` → thành bạn ngay (SOC-01), SnackBar *"Đã kết bạn với …"* hoặc lỗi.

> Quét bằng camera dùng `mobile_scanner` (Android: quyền CAMERA do plugin khai báo và tự xin lúc chạy; Web: cần `localhost` / `https`). Quét từ ảnh chỉ có trên Android (`analyzeImage` không hỗ trợ Web). Mọi nội dung quét / nhập đều qua `InviteQr.decode` trước khi gọi API. Ô định vị của QR giữ hình **vuông** — kiểu tròn khiến máy quét không nhận ra mã.
3. **Smooth Transitions:** AnimatedSwitcher handles switching between tabs.

#### Parameters
| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `initialTab` | `QrTab` | `QrTab.myQr` | Tab open on initial render (`myQr` or `scanQr`). |
| `qrData` | `QrCodeData?` | `null` | `null` = lấy tên và mã mời từ tài khoản (`accountControllerProvider`). Truyền giá trị cố định chỉ để test / preview. |
| `animateLaser` | `bool` | `true` | Flag controlling laser animation. |
| `enableCamera` | `bool` | `true` | Tắt camera trong test / preview. |

---

## 3. How to Navigate to the Screen

### Option 1: Direct Navigation (Push)
Trang cần nằm dưới `ProviderScope` (đã có ở `main.dart`). App dùng route có tên:

```dart
Navigator.pushNamed(context, '/add-qr');
// hoặc
Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddQrPage()));
```

### Option 2: Set as Initial Home Route
In [`mobile/lib/app.dart`](file:///c:/Users/admin/StudioProjects/Cham-ActivityLogWithPeople/mobile/lib/app.dart):

```dart
import 'package:flutter/material.dart';
import 'features/friends/presentation/pages/add_qr_page.dart';

class ChamApp extends StatelessWidget {
  const ChamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chăm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFB53216),
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
      ),
      home: const AddQrPage(),
    );
  }
}
```

---

## 4. Kết nối với Backend (đã nối)

| Việc | Code | API |
| :--- | :--- | :--- |
| Lấy mã mời của mình | `accountControllerProvider` → `ensure()` | `POST /api/auth/register` ở lần đầu (trả `user.inviteCode` + `token`) |
| Kết bạn từ mã quét / nhập | `friendsControllerProvider.notifier.add(code)` | `POST /api/friends { inviteCode }` → `201` mới / `200` đã là bạn / `404 INVITE_NOT_FOUND` / `400 CANNOT_FRIEND_SELF` |
| Danh sách bạn bè | `friendsControllerProvider` | `GET /api/friends` → `[{ id, displayName, since }]` |
| Đổi mã mời | `accountControllerProvider.notifier.rotateInviteCode()` | `POST /api/me/invite-code` — mã cũ hết hiệu lực |
| Huỷ kết bạn | `friendsControllerProvider.notifier.remove(id)` (màn `FriendsPage`) | `DELETE /api/friends/:userId` |

Sau khi kết bạn, `FriendsController` tải lại danh sách bạn và làm mới feed (bạn mới thấy được cả các bản Công khai cũ).
Mã mời gồm 10 ký tự, vd. `H4R7N2Q8ZK`.

---

## 🎨 Color Palette Reference

| Color Name | Hex Code | Visual Component |
| :--- | :--- | :--- |
| **Scaffold Background** | `#FAF7F2` | Page background warm cream |
| **Card Background** | `#FFFFFF` | Main profile & QR card container |
| **QR Background** | `#F6F0E9` | Rounded box enclosing the QR dots |
| **Tab Bar Background** | `#EDE7DF` | Pill toggle background container |
| **Brand Terracotta** | `#B53216` | App seed, top right avatar, heart badge |
| **Coral Accent** | `#E85835` | Central QR logo, laser scanner line |
| **Primary Text** | `#2C2523` | Title, user name, action labels |
| **Secondary Text** | `#8A827B` | Dòng `Mã mời: …`, muted captions |
| **Button Pill Fill** | `#F2ECE4` | `Sao chép mã`, `Lưu ảnh QR`, `Đổi mã mời` buttons |

