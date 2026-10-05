# Chăm – ActivityLogWithPeople
For PRM393

| Thư mục    | Stack                                                                                           |
| ---------- | ----------------------------------------------------------------------------------------------- |
| `backend/` | Cloudflare Workers + Hono, D1 + Drizzle ORM, Durable Objects (WebSocket)              |
| `mobile/`  | Flutter (Android + Web), Riverpod, Dio, web_socket_channel                                       |

Cả backend và mobile đều tổ chức theo **feature** (`features/<tên>/...`). Nghiệp vụ: [`docs/requirement-v1.md`](docs/requirement-v1.md).

- **Backend** chỉ lo phần xã hội: tài khoản ẩn danh, bạn bè (QR), chia sẻ sự kiện, reaction. Nhật ký cá nhân
  **không** lên server (DAT-01) — nó nằm ở local trên máy.
- **Mobile** hiện vẫn là feature mẫu `todos`, chưa chuyển sang API mới (xem mục 7).

---

## 1. Cài đặt môi trường

| Công cụ        | Phiên bản         | Ghi chú                                                                 |
| -------------- | ----------------- | ----------------------------------------------------------------------- |
| Node.js        | ≥ 20 (đang dùng 22) | cho backend                                                             |
| Flutter        | stable (3.47.x)   | <https://docs.flutter.dev/get-started/install>                          |
| JDK            | 17                | để build Android. Nếu máy có JDK mới hơn: `flutter config --jdk-dir <đường-dẫn-jdk-17>` |
| Android SDK    | platform 36       | Android Studio hoặc `cmdline-tools`                                     |
| Google Chrome  | bất kỳ            | để chạy bản Web                                                         |

Kiểm tra: `flutter doctor` phải có ✓ ở **Android toolchain** và **Chrome**.

> Không cần tài khoản Cloudflare để dev: `wrangler dev` giả lập D1, Durable Object ngay trên máy
> (dữ liệu lưu ở `backend/.wrangler/state`).

---

## 2. Chạy local

### Backend → `http://localhost:8787`

```bash
cd backend
npm install
npm run db:migrate:local   # tạo bảng trong D1 local (chạy lại mỗi khi có migration mới)
npm run dev
```

Kiểm tra: `curl localhost:8787/health` → `{"status":"ok"}`

### Mobile (mở terminal khác, backend phải đang chạy)

```bash
cd mobile
flutter pub get

# Web
flutter run -d chrome --dart-define-from-file=env/dev.json

# Android emulator
flutter emulators                         # xem danh sách emulator
flutter emulators --launch <tên-emulator>
flutter run -d emulator-5554 --dart-define-from-file=env/dev.json
```

- **Android emulator**: app tự đổi `localhost` → `10.0.2.2` (địa chỉ của máy host khi nhìn từ emulator).
- **Điện thoại thật** (cùng Wi-Fi với máy dev): tạo `mobile/env/dev.local.json` (đã gitignore) với
  `"API_BASE_URL": "http://<IP-LAN-của-máy>:8787"` rồi chạy `--dart-define-from-file=env/dev.local.json`.
  Backend đã listen `0.0.0.0` nên máy khác trong mạng LAN truy cập được.
- **VS Code**: chọn cấu hình `mobile (dev)` / `mobile (prod)` trong tab Run & Debug (`.vscode/launch.json`).

---

## 3. Hai môi trường: dev (local) và prod (Cloudflare)

|                   | **dev** (local)                                   | **prod** (Cloudflare thật)                              |
| ----------------- | ------------------------------------------------- | ------------------------------------------------------- |
| Backend chạy ở    | máy của bạn – `npm run dev` → `http://localhost:8787` | Cloudflare – `npm run deploy` → `https://cham-backend.<subdomain>.workers.dev` |
| D1 / Durable Object | **giả lập**, dữ liệu ở `backend/.wrangler/state` | resource thật trên Cloudflare (id trong `wrangler.jsonc`) |
| Secret            | `backend/.dev.vars`                               | `npx wrangler secret put <TÊN>`                         |
| Migration DB      | `npm run db:migrate:local`                        | `npm run db:migrate:remote`                             |
| File env của app  | `mobile/env/dev.json`                             | `mobile/env/prod.json`                                  |
| Banner trên app   | có chữ **DEV**                                    | không có                                                |

> Có id thật trong `wrangler.jsonc` **không** làm `npm run dev` ghi lên Cloudflare: `wrangler dev` mặc định
> luôn giả lập ở local. Chỉ những lệnh sau mới chạm tới dữ liệu thật: `npm run deploy`, `npm run db:migrate:remote`,
> lệnh có `--remote`, `wrangler secret ...`, `wrangler tail`.
> **Đừng** thêm `"remote": true` vào binding hay chạy `wrangler dev --remote` nếu không muốn dev ghi vào dữ liệu prod.

### Chạy môi trường dev

```bash
# Terminal 1 – backend local
cd backend
npm run db:migrate:local
npm run dev

# Terminal 2 – app trỏ vào backend local
cd mobile
flutter run -d chrome        --dart-define-from-file=env/dev.json   # Web
flutter run -d emulator-5554 --dart-define-from-file=env/dev.json   # Android emulator
```

### Chạy môi trường prod

```bash
# 1. Đưa code backend lên Cloudflare (mỗi khi backend thay đổi)
cd backend
npm run db:migrate:remote    # chỉ khi có migration mới
npm run deploy

# 2. App trỏ vào backend trên Cloudflare (không cần bật `npm run dev`)
cd mobile
flutter run -d emulator-5554 --dart-define-from-file=env/prod.json      # chạy thử, vẫn hot reload được
flutter build apk --release  --dart-define-from-file=env/prod.json      # APK để cài lên điện thoại
flutter build web --release  --dart-define-from-file=env/prod.json      # bản Web → mobile/build/web
```

Có thể kết hợp tuỳ ý — vd. app chạy debug trên emulator nhưng dùng `env/prod.json` để test với dữ liệu thật.

### Xem / kiểm tra dữ liệu

```bash
# dev
npx wrangler d1 execute cham-db --local  --command "SELECT * FROM users"
# prod
npx wrangler d1 execute cham-db --remote --command "SELECT * FROM users"
npx wrangler tail            # log realtime của Worker trên Cloudflare
```

---

## 4. Biến môi trường

### Backend

| Loại                                   | Đặt ở đâu                                    | Commit? |
| -------------------------------------- | -------------------------------------------- | ------- |
| Biến thường (vd. `CORS_ORIGIN`)        | `"vars"` trong `backend/wrangler.jsonc`      | ✅      |
| Secret khi dev local                   | `backend/.dev.vars` (copy từ `.dev.vars.example`) | ❌  |
| Secret production                      | `npx wrangler secret put <TÊN>`              | ❌      |
| Bindings (D1, Durable Object)          | `backend/wrangler.jsonc`                     | ✅      |

Sau khi thêm/sửa biến hoặc binding: `npm run cf-typegen` để cập nhật type `Env`. Trong code đọc bằng `c.env.<TÊN>`.

### Mobile

Mỗi môi trường là một file JSON trong `mobile/env/`, chọn khi run/build bằng `--dart-define-from-file`:

| File            | `APP_ENV` | `API_BASE_URL`                                     |
| --------------- | --------- | -------------------------------------------------- |
| `env/dev.json`  | `dev`     | `http://localhost:8787`                            |
| `env/prod.json` | `prod`    | URL Worker sau khi deploy                          |

Đọc trong code qua `Env.apiBaseUrl`, `Env.isProd`, `Env.appEnv` (`lib/core/config/env.dart`).
Bản không phải prod có banner **DEV** ở góc màn hình.

> ⚠️ Giá trị trong `env/*.json` được compile vào app — **ai cũng đọc được**. Không đặt secret ở mobile.

Thêm biến mới: thêm key vào **tất cả** file `env/*.json` + khai báo `String.fromEnvironment('<KEY>')` trong `env.dart`.

---

## 5. Kiến trúc code

### Tổng quan

```
┌──────────────────────┐  HTTP (REST)     ┌─────────────────── Cloudflare Worker (Hono) ───────────────────┐
│  Flutter app         │  Bearer token    │  auth → route → service → repository ──▶ D1 (SQLite, Drizzle)   │
│  - nhật ký: local    │ ───────────────▶ │                     │                                           │
│  - hàng chờ chia sẻ  │                  │                     └──▶ Durable Object UserRoom (1 / user)      │
│                      │   WebSocket      │                          gửi "hint" tới các máy của user đó      │
│                      │ ◀═══════════════ │                          (share.upserted, friends.changed, …)    │
└──────────────────────┘                  └─────────────────────────────────────────────────────────────────┘
```

**Luồng chia sẻ một bản ghi:**

1. Người dùng chạm nút → app lưu bản ghi **vào local** trước (BR-02). Nếu loại sự kiện có bật chia sẻ, thêm bản ghi vào hàng chờ.
2. Khi có mạng, app gọi `PUT /api/shares/:id` với `:id` = id của bản ghi local. PUT là idempotent → gửi lại bao nhiêu lần cũng chỉ có một bản (AC-05).
3. Worker ghi D1 rồi gửi hint `share.upserted` tới `UserRoom` của từng người được xem.
4. App của người nhận nhận hint → gọi `GET /api/feed/:id` để lấy dữ liệu (quyền xem luôn được kiểm tra ở REST, WebSocket không mang dữ liệu).

**Quyền xem** một share (một chỗ duy nhất: `ShareRepository.visibleTo`): chủ sở hữu, hoặc người **đang là bạn** của chủ
**và** (share là broadcast **hoặc** người đó nằm trong `share_targets`). Vì kiểm tra bạn bè lúc đọc, huỷ kết bạn thu hồi quyền ngay.

### Backend (`backend/`)

```
backend/
├── src/
│   ├── index.ts                  # entry của Worker: export app Hono + class Durable Object
│   ├── app.ts                    # tạo Hono app, gắn middleware (logger, CORS), mount routes, error handler
│   │
│   ├── features/                 # mỗi feature một thư mục, tự chứa đủ các tầng
│   │   ├── users/                  # đăng ký ẩn danh, /me, mã mời (QR), WebSocket của user
│   │   ├── friends/                # kết bạn bằng mã mời, danh sách, huỷ kết bạn (thu hồi quyền 2 chiều)
│   │   └── shares/                 # share của mình (/shares) + feed của bạn bè và reaction (/feed)
│   │       ├── share.route.ts        # HTTP layer: định nghĩa endpoint, validate, gọi service
│   │       ├── share.service.ts      # business logic: quyền, phát sự kiện realtime, map Row → DTO
│   │       ├── share.repository.ts   # truy cập DB bằng Drizzle, gồm luật quyền xem (visibleTo)
│   │       ├── share.schema.ts       # zod schema cho input (body, params, query)
│   │       └── share.types.ts        # kiểu dữ liệu: Row, DTO
│   │
│   ├── middleware/
│   │   ├── auth.middleware.ts    # requireAuth: Bearer token → c.var.user
│   │   └── error.middleware.ts   # chuẩn hoá mọi lỗi thành { error: { code, message, details? } }
│   │
│   ├── infrastructure/           # adapter tới dịch vụ Cloudflare, dùng chung cho mọi feature
│   │   ├── db/
│   │   │   ├── schema.ts           # định nghĩa bảng (Drizzle) — nguồn để sinh migration
│   │   │   └── client.ts           # createDb(env.DB)
│   │   └── realtime/
│   │       ├── user-room.do.ts     # Durable Object (1 / user) giữ các WebSocket (Hibernation API)
│   │       └── realtime.ts         # RealtimeEvent + createNotifier(): gửi hint tới room của các user
│   │
│   └── shared/
│       ├── errors/app-error.ts   # AppError, NotFound, Validation, Unauthorized, Forbidden, Conflict
│       ├── types/env.ts          # AppEnv: kiểu Bindings + Variables (user) cho Hono
│       └── utils/
│           ├── validator.ts        # wrapper zValidator → ném ValidationError
│           └── crypto.ts           # sinh token / hash token / mã mời
│
├── migrations/                   # SQL do drizzle-kit sinh ra, áp dụng bằng wrangler d1 migrations
├── test/                         # Vitest chạy trong Workers runtime (@cloudflare/vitest-pool-workers)
├── wrangler.jsonc                # cấu hình Worker + bindings DB, USER_ROOM
├── worker-configuration.d.ts     # type Env sinh bởi `wrangler types` (không sửa tay)
└── drizzle.config.ts
```

**Quy tắc phụ thuộc giữa các tầng:** `route → service → repository → infrastructure`

- `route` chỉ lo HTTP: đọc input đã validate, gọi service, trả JSON. Không truy cập DB trực tiếp.
- `service` chứa logic nghiệp vụ, ném `AppError` khi lỗi (vd. `NotFoundError`). Không biết gì về Hono/HTTP.
- `repository` chỉ đọc/ghi DB qua Drizzle.
- Service được tạo trong file route bằng một hàm nhỏ (vd. `shareService(c)`); user hiện tại lấy từ `c.var.user`.
- Mọi route trừ `/api/auth/register` và `/health` đều qua `requireAuth`.

**Format response:** thành công `{ "data": ... }` · lỗi `{ "error": { "code", "message", "details"? } }`

### Mobile (`mobile/`)

```
mobile/
├── env/                          # dev.json, prod.json — biến môi trường theo từng môi trường
├── lib/
│   ├── main.dart                 # runApp + ProviderScope (Riverpod)
│   ├── app.dart                  # MaterialApp, theme, banner môi trường
│   │
│   ├── core/                     # dùng chung cho mọi feature
│   │   ├── config/env.dart         # đọc APP_ENV, API_BASE_URL
│   │   └── network/
│   │       ├── api_client.dart     # dioProvider: Dio với baseUrl, timeout, interceptor lỗi
│   │       └── api_exception.dart  # map lỗi backend/network → ApiException
│   │
│   └── features/
│       └── todos/
│           ├── domain/
│           │   └── todo.dart          # model Todo + TodoEvent (sự kiện realtime)
│           ├── data/
│           │   ├── todo_api.dart      # gọi REST API
│           │   └── todo_realtime.dart # StreamProvider WebSocket, tự reconnect sau 3s
│           └── presentation/
│               ├── todo_controller.dart  # AsyncNotifier: state danh sách, optimistic update, nhận sự kiện WS
│               ├── pages/todo_page.dart  # màn hình
│               └── widgets/todo_tile.dart
└── test/
```

**Luồng dữ liệu:** `Widget ──watch──▶ Controller (Riverpod) ──▶ data (API / WebSocket) ──▶ Backend`

- `domain`: model thuần Dart, không phụ thuộc Flutter hay network.
- `data`: nói chuyện với backend, trả về model `domain`; lỗi được chuyển thành `ApiException`.
- `presentation`: controller giữ state, widget chỉ hiển thị và gọi method của controller.

---

## 6. Thêm một feature mới (vd. `notes`)

**Backend**
1. Thêm bảng trong `src/infrastructure/db/schema.ts`.
2. `npm run db:generate` → sinh file trong `migrations/`, rồi `npm run db:migrate:local`.
3. Tạo `src/features/notes/` với `note.schema.ts`, `note.types.ts`, `note.repository.ts`, `note.service.ts`, `note.route.ts` (copy cấu trúc từ `friends`).
4. Trong route: `.use(requireAuth)` nếu cần đăng nhập, tạo service bằng hàm `noteService(c)`.
5. Mount route trong `src/app.ts`: `app.route("/api/notes", noteRoutes)`.
6. Viết test trong `test/`.

**Mobile**
1. Tạo `lib/features/notes/{domain,data,presentation}` theo mẫu `todos`.
2. Thêm màn hình vào điều hướng trong `app.dart`.

---

## 7. API

Mọi endpoint (trừ `/health`, `/api/auth/register`) cần header `Authorization: Bearer <token>`.
Thời gian dạng ISO 8601. Danh sách phân trang: `?limit=1..50` (mặc định 20) và `?cursor=<nextCursor của trang trước>`,
response `{ data: [...], nextCursor: string | null }`.

**Tài khoản** — ẩn danh theo máy: lần đầu mở app gọi `register`, lưu `token` vào secure storage. Mất token = mất tài khoản.

| Method | Path                     | Body                         | Response                                   |
| ------ | ------------------------ | ---------------------------- | ------------------------------------------ |
| GET    | `/health`                |                              | `{ status: "ok" }`                         |
| POST   | `/api/auth/register`     | `{ displayName }` (1–50)     | `201 { data: { user: Me, token } }`        |
| GET    | `/api/me`                |                              | `{ data: Me }`                             |
| PATCH  | `/api/me`                | `{ displayName }`            | `{ data: Me }`                             |
| POST   | `/api/me/invite-code`    |                              | `{ data: Me }` — mã mới, QR cũ hết hiệu lực |
| WS     | `/api/me/ws?token=…`     | gửi `"ping"` → nhận `"pong"` | sự kiện JSON (bên dưới)                    |

**Bạn bè** — QR của mỗi người chứa `inviteCode` (không chứa nhật ký). Quét là thành bạn hai chiều ngay.

| Method | Path                     | Body                 | Response                                                      |
| ------ | ------------------------ | -------------------- | ------------------------------------------------------------- |
| GET    | `/api/friends`           |                      | `{ data: Friend[] }`                                          |
| POST   | `/api/friends`           | `{ inviteCode }`     | `201` mới / `200` đã là bạn · `404 INVITE_NOT_FOUND` · `400 CANNOT_FRIEND_SELF` |
| DELETE | `/api/friends/:userId`   |                      | `204` — thu hồi quyền xem share **2 chiều**, xoá target và reaction giữa 2 người |

**Share của mình** — `:id` là **id bản ghi local** (UUID).

| Method | Path               | Body                                                    | Response                          |
| ------ | ------------------ | ------------------------------------------------------- | --------------------------------- |
| GET    | `/api/shares`      |                                                         | `{ data: OwnShare[], nextCursor }` |
| GET    | `/api/shares/:id`  |                                                         | `{ data: OwnShare }` / 404        |
| PUT    | `/api/shares/:id`  | `{ emoji, name, occurredAt, targetIds? }`               | `201` tạo mới / `200` cập nhật · `409` id thuộc người khác |
| DELETE | `/api/shares/:id`  |                                                         | `204` (kể cả khi không tồn tại → retry an toàn) |

`targetIds` bỏ trống / `null` / `[]` → **broadcast** cho mọi bạn bè. Có phần tử → **multicast**, chỉ những người đó
(id không phải bạn bè bị bỏ qua, và *không* quay về broadcast). PUT lại với `targetIds` khác = đổi quyền xem;
reaction của người mất quyền bị xoá.

**Feed của bạn bè**

| Method | Path                      | Body                                    | Response                           |
| ------ | ------------------------- | --------------------------------------- | ---------------------------------- |
| GET    | `/api/feed`               |                                         | `{ data: FeedShare[], nextCursor }` — mới nhất trước theo `occurredAt` |
| GET    | `/api/feed/:id`           |                                         | `{ data: FeedShare }` / 404 nếu không có quyền |
| PUT    | `/api/feed/:id/reaction`  | `{ emoji }` ∈ `❤️ 😂 😮 😢 👍 🔥`        | `{ data: FeedShare }` — mỗi người 1 reaction, gửi lại = đổi |
| DELETE | `/api/feed/:id/reaction`  |                                         | `204`                              |

```ts
Me        = { id, displayName, inviteCode, createdAt }
Friend    = { id, displayName, since }
OwnShare  = { id, emoji, name, occurredAt, audience: "all" | "targets", targetIds: string[],
              reactions: { user: { id, displayName }, emoji, reactedAt }[], createdAt, updatedAt }
FeedShare = { id, owner: { id, displayName }, emoji, name, occurredAt,
              reactions: { emoji, count }[], myReaction: string | null }
```

Sự kiện WebSocket chỉ là **gợi ý để tải lại**, không chứa dữ liệu:
```json
{ "type": "share.upserted", "id": "..." }      // có share mới/đổi mà bạn xem được → GET /api/feed/:id
{ "type": "share.removed", "id": "..." }       // share bị xoá hoặc bạn mất quyền → bỏ khỏi feed
{ "type": "reaction.changed", "shareId": "..." } // có người react share của bạn → GET /api/shares/:id
{ "type": "friends.changed" }                  // danh sách bạn đổi → tải lại bạn bè + feed
```

---

## 8. Lệnh thường dùng

**Backend** (`cd backend`)

| Lệnh                         | Tác dụng                                               |
| ---------------------------- | ------------------------------------------------------ |
| `npm run dev`                | chạy Worker local ở `:8787`                            |
| `npm test`                   | chạy test (Vitest trong Workers runtime)               |
| `npm run typecheck`          | kiểm tra TypeScript                                    |
| `npm run db:generate`        | sinh migration sau khi sửa `schema.ts`                 |
| `npm run db:migrate:local`   | áp migration vào D1 local                              |
| `npm run cf-typegen`         | sinh lại type `Env` sau khi sửa `wrangler.jsonc`       |

Xoá sạch dữ liệu local: `rm -rf .wrangler/state && npm run db:migrate:local`

**Mobile** (`cd mobile`)

| Lệnh                                                             | Tác dụng              |
| ---------------------------------------------------------------- | --------------------- |
| `flutter analyze`                                                | lint                  |
| `flutter test`                                                   | chạy test             |
| `flutter build apk --release --dart-define-from-file=env/prod.json` | build APK production |
| `flutter build web --release --dart-define-from-file=env/prod.json` | build Web production |

---

## 9. Deploy lên Cloudflare

```bash
cd backend
npx wrangler login
npx wrangler d1 create cham-db            # dán database_id vào wrangler.jsonc
npm run db:migrate:remote
npm run deploy                            # in ra URL *.workers.dev
```

Sau đó cập nhật `API_BASE_URL` trong `mobile/env/prod.json` bằng URL vừa deploy, và đổi `CORS_ORIGIN`
trong `wrangler.jsonc` thành domain của bản Web thay vì `*`.

---

## 10. CI/CD backend (GitHub Actions)

Workflow: `.github/workflows/backend.yml` — chỉ chạy khi có thay đổi trong `backend/`.

| Sự kiện                         | Job `check` (typecheck, test, build thử) | Job `deploy` (migrate D1 + deploy) |
| ------------------------------- | ---------------------------------------- | ---------------------------------- |
| Mở / cập nhật Pull Request      | ✅                                        | ❌                                  |
| Push / merge vào `main-onlymerge` | ✅                                      | ✅ nếu `check` pass                 |
| Bấm "Run workflow" (tab Actions) | ✅                                       | ✅ (khi chạy trên `main-onlymerge`) |

### Cài đặt một lần

1. **Tạo API token** trên Cloudflare: *My Profile → API Tokens → Create Token → template "Edit Cloudflare Workers"*,
   bấm thêm quyền **Account → D1 → Edit**, phần *Account Resources* chọn đúng account → Create, copy token.
2. **Lấy Account ID**: `npx wrangler whoami` (hoặc trang Workers & Pages trên dashboard).
3. **Thêm secret vào repo**: GitHub → *Settings → Secrets and variables → Actions → New repository secret*:
   - `CLOUDFLARE_API_TOKEN`
   - `CLOUDFLARE_ACCOUNT_ID`

   Hoặc bằng CLI: `gh secret set CLOUDFLARE_API_TOKEN` và `gh secret set CLOUDFLARE_ACCOUNT_ID`.
4. *(Khuyến nghị)* **Bảo vệ nhánh**: *Settings → Branches → Add rule* cho `main-onlymerge`, bật
   "Require a pull request before merging" và "Require status checks to pass" → chọn `Typecheck & test`.
5. *(Tuỳ chọn)* **Duyệt trước khi deploy**: *Settings → Environments → `production`* (tự tạo sau lần deploy đầu)
   → thêm "Required reviewers".

### Quy trình làm việc

```
tạo nhánh → code → mở PR ──▶ CI chạy check ──▶ review + merge ──▶ CI check lại ──▶ migrate D1 + deploy ──▶ gọi /health
```

- Migration D1 chạy **trước** khi code mới lên, nên viết migration tương thích ngược (thêm cột/bảng;
  không xoá hay đổi tên cột trong cùng một lần deploy).
- Xem lịch sử và log tại tab **Actions** của repo; log runtime của Worker: `npx wrangler tail`.
- Muốn quay lại bản trước: `npx wrangler rollback` (chỉ rollback code, không rollback migration).

---

## 11. Lưu ý

- `compatibility_date` trong `wrangler.jsonc` không được mới hơn ngày mà runtime của test pool hỗ trợ — nếu `npm test` báo lỗi compatibility date thì lùi ngày lại.
- `backend/.npmrc` bật `legacy-peer-deps` vì npm 10 lỗi khi resolve peer deps của `@cloudflare/vitest-pool-workers`.
- Durable Object dùng SQLite backend (`new_sqlite_classes`) — bắt buộc với gói Free.
- Không dùng R2 vì Cloudflare yêu cầu liên kết thẻ thanh toán để bật R2. Khi cần lưu file, cân nhắc lại.
- Không thêm `"remote": true` vào binding trong `wrangler.jsonc` — nó làm `npm run dev` đọc/ghi thẳng dữ liệu production.
