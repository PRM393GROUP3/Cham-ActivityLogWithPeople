# SRS ứng dụng ghi nhật ký sinh hoạt

Phiên bản 0.3  |  Ngày 26 tháng 10 năm 2026

## 1 Mục đích và phạm vi

Ứng dụng giúp người dùng ghi lại các hoạt động như uống cà phê, đi vệ sinh, chạy bộ hoặc đi ngủ chỉ bằng một lần chạm. Người dùng xem lịch sử và thống kê để nhận ra quy luật sinh hoạt, đồng thời có thể kết bạn bằng QR và chia sẻ các bản ghi đã chọn cho bạn bè.

Phạm vi gồm nhật ký cá nhân offline, tạo loại sự kiện, thống kê, bạn bè, chia sẻ và reaction, widget. Các mục còn mở được liệt kê ở mục 9.2 và chưa phải quyết định sản phẩm cuối cùng.

## 2 Đối tượng và thuật ngữ

Người dùng quản lý nhật ký của mình; bạn bè chỉ xem các bản ghi được chia sẻ ở chế độ Public.

- **Loại sự kiện**: nút có emoji hoặc sticker và tên.
- **Bản ghi**: một lần chạm vào nút, gắn với thời điểm xảy ra.
- **Chế độ chia sẻ** của bản ghi:
  - **Private** (mặc định): chỉ lưu local trên máy, không gửi lên máy chủ, chỉ chủ sở hữu xem được.
  - **Public**: gửi lên máy chủ, tất cả bạn bè của chủ sở hữu xem được.
- **Sự kiện chia sẻ**: phần thông tin của bản ghi Public được gửi online (emoji, tên, thời điểm).

## 3 Yêu cầu ghi nhận và xem lại

| Mã | Yêu cầu chức năng |
| --- | --- |
| LOG-01 | Mỗi loại sự kiện phải có emoji hoặc sticker và tên sự kiện. |
| LOG-02 | Khi chọn emoji, hệ thống điền tên mặc định theo tên emoji; người dùng được đổi tên trước khi lưu loại sự kiện. |
| LOG-03 | Chạm nút sự kiện phải tạo ngay một bản ghi Private với thời điểm hiện tại, không mở form và không yêu cầu nhập thêm. |
| LOG-04 | Không cung cấp Undo. Với bản ghi đã tạo, chỉ cho phép Delete; không sửa nội dung hoặc thời điểm. |
| LOG-05 | Người dùng được tạo loại sự kiện. Sau khi tạo, **không** được sửa (emoji, tên) và **không** được sắp xếp lại thứ tự; loại sự kiện hiển thị theo thứ tự tạo. |
| HIS-01 | Hiển thị lịch sử theo ngày và lần ghi gần nhất của từng loại sự kiện. Mỗi bản ghi hiển thị chế độ chia sẻ (Private / Public) và trạng thái gửi. |
| HIS-02 | Cho phép xóa bản ghi trong lịch sử; lịch sử, lần ghi gần nhất và thống kê phải được cập nhật tương ứng. |
| STA-01 | Hiển thị số lần ghi theo tuần, tháng và phân bố bản ghi theo khung giờ để người dùng quan sát quy luật sinh hoạt. |

## 4 Yêu cầu chia sẻ và dữ liệu

| Mã | Yêu cầu chức năng |
| --- | --- |
| SOC-01 | Hiển thị QR cá nhân và cho phép quét QR của người khác để kết bạn. **Kết bạn trực tiếp**: quét QR hợp lệ là hai người trở thành bạn bè ngay, không cần người kia xác nhận. |
| SOC-02 | Hiển thị danh sách bạn bè và cho phép xóa bạn bè khỏi danh sách. |
| SOC-03 | Chia sẻ **theo từng bản ghi**, chỉ có 2 chế độ: **Private** (mặc định) và **Public** (tất cả bạn bè). Người dùng đổi chế độ trên bản ghi trong lịch sử. Không hỗ trợ chọn từng người nhận. |
| SOC-04 | Chuyển bản ghi từ Public về Private, hoặc xóa bản ghi Public, phải **thu hồi** sự kiện chia sẻ: không bạn bè nào còn xem được, reaction trên đó bị xóa. |
| SOC-05 | Người dùng xem các sự kiện Public của bạn bè và thả reaction. Bộ reaction giống Facebook: 👍 Thích, ❤️ Yêu thích, 🥰 Thương thương, 😆 Haha, 😮 Wow, 😢 Buồn, 😡 Phẫn nộ. Mỗi người tối đa **1 reaction** trên mỗi sự kiện, được đổi hoặc gỡ. |
| WID-01 | Cho phép chọn các nút sự kiện đưa lên widget. Chạm nút trên widget tạo bản ghi Private với thời điểm hiện tại, theo cùng quy tắc ghi nhanh trong app. |
| DAT-01 | Nhật ký cá nhân phải lưu local và dùng được offline. Chỉ bản ghi Public mới gửi online; không tự tải toàn bộ nhật ký lên máy chủ. |
| DAT-02 | Thời gian hiển thị, lịch sử theo ngày và thống kê dùng **múi giờ Việt Nam (UTC+7)**. Máy chủ lưu thời điểm dạng ISO 8601 có offset. |
| DAT-03 | Khi mất mạng vẫn ghi local và vẫn đổi được chế độ chia sẻ. Thay đổi cần gửi (Public, thu hồi) được lưu chờ và gửi khi có mạng; gửi lại không được tạo bản chia sẻ trùng. |

## 5 Luồng sử dụng chính

**Ghi nhanh**: người dùng chạm nút trong app hoặc widget → hệ thống lưu thời điểm và loại sự kiện vào local ở chế độ Private → hiển thị đã lưu. Không có bước chia sẻ trong lúc ghi.

**Chia sẻ**: người dùng mở lịch sử → chọn một bản ghi → chuyển sang Public → hệ thống gửi online, hoặc lưu chờ gửi khi mất mạng → tất cả bạn bè thấy sự kiện trong feed. Chuyển về Private hoặc xóa bản ghi → hệ thống thu hồi bản online.

**Xem lại**: người dùng mở lịch sử hoặc thống kê → chọn ngày, tuần hoặc tháng → xem các bản ghi, lần ghi gần nhất và phân bố thời gian. Khi xóa bản ghi, các kết quả liên quan được tính lại.

**Bạn bè**: quét QR của người khác → hai người thành bạn bè ngay → mỗi người thấy các sự kiện Public của người kia và thả reaction.

## 6 Cơ chế chia sẻ và quyền xem

| Chế độ | Lưu ở đâu | Ai xem được |
| --- | --- | --- |
| Private | Chỉ local trên máy | Chỉ chủ sở hữu |
| Public | Local + máy chủ | Chủ sở hữu và **tất cả bạn bè hiện tại** của chủ sở hữu |

Quyền xem sự kiện Public được tính theo danh sách bạn bè **tại thời điểm xem**:

- Kết bạn mới → người bạn mới thấy được cả các sự kiện Public trước đó.
- Xóa bạn → hai người không còn thấy sự kiện Public của nhau; reaction của họ trên sự kiện của nhau bị xóa.
- Public → Private, hoặc xóa bản ghi Public → thu hồi với tất cả mọi người (SOC-04).

## 7 Quy tắc và chất lượng

BR-01 — Mỗi bản ghi có mã duy nhất, loại sự kiện và thời điểm ghi. Mỗi lần chạm hợp lệ tạo một bản ghi; chống trùng do gửi lại không được gộp các lần ghi độc lập.

BR-02 — Ghi nhận luôn hoàn tất ở local trước; lỗi mạng không được làm mất bản ghi. Hàng chờ gửi phải còn sau khi đóng và mở lại app, đồng thời giữ thời điểm ghi gốc khi gửi muộn.

BR-03 — Xóa bản ghi đang chờ chia sẻ phải hủy gửi bản ghi đó. Xóa bản ghi đã Public, hoặc chuyển về Private, phải thu hồi bản online (SOC-04).

BR-04 — Mã của bản ghi được dùng làm mã của sự kiện chia sẻ, để gửi lại nhiều lần chỉ tạo hoặc cập nhật đúng một bản trên máy chủ.

NFR-01 — Ghi nhanh, tạo loại sự kiện, lịch sử và thống kê cá nhân hoạt động khi không có Internet.

NFR-02 — Chỉ chủ dữ liệu và bạn bè hiện tại mới truy cập được sự kiện Public; QR không chứa nhật ký. Thông tin định danh và quan hệ bạn bè phục vụ tính năng xã hội được xử lý riêng.

NFR-03 — Chỉ báo “đã lưu” khi ghi local thành công; nếu thất bại phải báo lỗi. Phân biệt trạng thái đã lưu local với trạng thái gửi chia sẻ (đang chờ, đã gửi, lỗi).

## 8 Tiêu chí nghiệm thu chính

AC-01 — Ở chế độ máy bay, chạm nút trong app hoặc widget tạo đúng một bản ghi Private đúng thời điểm, không mở form; mở lại app vẫn thấy bản ghi.

AC-02 — Tạo loại sự kiện hoạt động; chọn emoji điền tên mặc định và cho phép đổi tên trước khi lưu. Sau khi tạo, không có chức năng sửa hoặc sắp xếp loại sự kiện.

AC-03 — Xóa một bản ghi làm lịch sử, lần ghi gần nhất và thống kê khớp dữ liệu còn lại; không có Undo hoặc sửa bản ghi.

AC-04 — Quét QR hợp lệ làm hai người thành bạn bè ngay, không cần xác nhận. Xóa bạn làm hai người không còn thấy sự kiện Public của nhau.

AC-05 — Chuyển bản ghi sang Public khi offline, mở lại app và kết nối mạng: sự kiện được gửi với thời điểm gốc. Gửi lại nhiều lần vẫn chỉ có một bản chia sẻ.

AC-06 — Bản ghi Private không xuất hiện trên máy chủ và không bạn bè nào thấy. Bản ghi Public được tất cả bạn bè thấy; người không phải bạn bè không thấy. Chuyển về Private hoặc xóa bản ghi thì không ai còn thấy.

AC-07 — Bạn bè thả được một trong 7 reaction (👍 ❤️ 🥰 😆 😮 😢 😡) trên sự kiện Public; thả reaction khác sẽ thay reaction cũ; gỡ được reaction.

AC-08 — Lịch sử theo ngày và thống kê theo khung giờ tính theo múi giờ Việt Nam (UTC+7): bản ghi lúc 23:30 ngày 1 giờ Việt Nam thuộc ngày 1.

## 9 Quyết định sản phẩm

### 9.1 Đã chốt

| Chủ đề | Quyết định |
| --- | --- |
| Nền tảng | Android và Web (Flutter) |
| Kết bạn | Trực tiếp qua QR, không cần người kia đồng ý |
| Phạm vi chia sẻ | Theo từng bản ghi, chọn sau khi ghi |
| Chế độ chia sẻ | Private (mặc định) / Public (tất cả bạn bè); không chọn từng người nhận |
| Thu hồi | Được: chuyển về Private hoặc xóa bản ghi |
| Loại sự kiện | Chỉ tạo; không sửa, không sắp xếp |
| Bản ghi | Chỉ tạo và xóa; không sửa, không Undo |
| Múi giờ | Việt Nam (UTC+7) |
| Reaction | Bộ 7 reaction giống Facebook, mỗi người 1 reaction trên mỗi sự kiện |

### 9.2 Còn mở

1. Có cho xóa loại sự kiện không; nếu có, các bản ghi cũ của loại đó giữ lại hay xóa theo.
2. Ngày bắt đầu tuần cho thống kê (đề xuất: Thứ Hai) và độ rộng khung giờ thống kê (đề xuất: 1 giờ).
3. Phương thức định danh cho tính năng bạn bè (backend hiện dùng tài khoản ẩn danh: `POST /api/auth/register` cấp token, không cần email hay mật khẩu).
