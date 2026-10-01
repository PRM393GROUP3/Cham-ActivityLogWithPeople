# Biến môi trường của app

Mỗi file `<env>.json` là một môi trường, truyền vào lúc run/build:

```bash
flutter run   --dart-define-from-file=env/dev.json
flutter build apk --release --dart-define-from-file=env/prod.json
flutter build web --release --dart-define-from-file=env/prod.json
```

- Giá trị được compile vào app → **ai cũng đọc được, không đặt secret ở đây**.
- Ghi đè riêng trên máy mình (vd. IP LAN cho điện thoại thật): tạo `env/dev.local.json`
  (đã gitignore) rồi chạy với file đó.
- Thêm biến mới: thêm key vào **tất cả** các file JSON, rồi khai báo trong `lib/core/config/env.dart`.
