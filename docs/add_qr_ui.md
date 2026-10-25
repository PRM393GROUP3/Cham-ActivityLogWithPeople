# Friend Connection & Add QR UI Documentation

This document describes the architecture, reusable components, data models, and integration guide for the **Add QR & Scanner Screen** (`AddQrPage`) in the **Chăm** application.

---

## 📁 Directory Structure

```text
mobile/lib/features/friends/
├── domain/
│   └── qr_code_data.dart      # QrCodeData model
└── presentation/
    ├── pages/
    │   └── add_qr_page.dart   # Main screen with Tab controller & layout
    └── widgets/
        ├── custom_qr_view.dart  # Custom dot-matrix QR painter with brand logo
        └── qr_scanner_view.dart # Viewfinder, laser animation & manual code entry
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
  data: 'CHAM-8F3K9M',
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
   - `Mã QR của tôi`: Displays the white rounded profile card with user avatar, heart badge, name, username, QR code, and action buttons (`Chia sẻ ảnh` and `Lưu vào máy`).
   - `Quét mã QR`: Displays the interactive scanner view.
3. **Smooth Transitions:** AnimatedSwitcher handles switching between tabs.

#### Parameters
| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `initialTab` | `QrTab` | `QrTab.myQr` | Tab open on initial render (`myQr` or `scanQr`). |
| `qrData` | `QrCodeData` | Default Hà My profile | Current user profile to display on the card. |
| `animateLaser` | `bool` | `true` | Flag controlling laser animation. |

---

## 3. How to Navigate to the Screen

### Option 1: Direct Navigation (Push)
From any button or menu in your app:

```dart
import 'package:cham/features/friends/presentation/pages/add_qr_page.dart';
import 'package:cham/features/friends/domain/qr_code_data.dart';

void openAddQrScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => const AddQrPage(
        qrData: QrCodeData(
          displayName: 'Hà My (Tôi)',
          username: '@hamy_cham',
          inviteCode: 'CHAM-8F3K9M',
          avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=240',
        ),
      ),
    ),
  );
}
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

## 4. Connecting with the Backend API

The backend already provides the following friend and QR invite endpoints:

### A. Fetch Current User's Invite Code
Call `GET /api/me` with bearer token:
```json
{
  "data": {
    "id": "user-uuid",
    "displayName": "Hà My",
    "inviteCode": "CHAM-8F3K9M",
    "createdAt": "2026-10-01T00:00:00.000Z"
  }
}
```
Bind the returned `displayName` and `inviteCode` to `QrCodeData`.

### B. Rotate QR Code
Call `POST /api/me/invite-code` to invalidate old QR codes and generate a new code.

### C. Connect Friend from Scanned Code
When `onCodeScanned(code)` fires from the scanner or manual input dialog:
```dart
Future<void> connectFriend(String inviteCode) async {
  try {
    final response = await apiClient.post(
      '/api/friends',
      data: {'inviteCode': inviteCode},
    );
    // 201: Successfully added new friend
    // 200: Already friends
    print('Friend connected: ${response.data}');
  } catch (e) {
    print('Connection error: $e');
  }
}
```

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
| **Secondary Text** | `#8A827B` | Username `@hamy_cham`, muted captions |
| **Button Pill Fill** | `#F2ECE4` | `Chia sẻ ảnh`, `Lưu vào máy` buttons |

