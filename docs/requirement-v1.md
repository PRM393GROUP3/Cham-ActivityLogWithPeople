# SRS ứng dụng ghi nhật ký sinh hoạt

Phiên bản 0.2  |  Ngày 01 tháng 10 năm 2026

## 1 Mục đích và phạm vi

Ứng dụng giúp người dùng ghi lại các hoạt động như uống cà phê, đi vệ sinh, chạy bộ hoặc đi ngủ chỉ bằng một lần chạm. Người dùng xem lịch sử và thống kê để nhận ra quy luật sinh hoạt, đồng thời có thể kết bạn bằng QR và chia sẻ các sự kiện đã chọn.

Phạm vi gồm nhật ký cá nhân offline, quản lý loại sự kiện, thống kê, bạn bè, chia sẻ và reaction, widget. Các mục ghi “Đề xuất” hoặc “Cần chốt” chưa phải quyết định sản phẩm cuối cùng.

## 2 Đối tượng và thuật ngữ

Người dùng quản lý nhật ký của mình; bạn bè chỉ xem các sự kiện được chia sẻ cho họ. Loại sự kiện là nút có emoji hoặc sticker và tên. Bản ghi là một lần chạm vào nút, gắn với thời điểm xảy ra. Sự kiện chia sẻ là phần thông tin của bản ghi được phép gửi online.

## 3 Yêu cầu ghi nhận và xem lại

| Mã | Yêu cầu chức năng |
| --- | --- |
| LOG-01 | Mỗi loại sự kiện phải có emoji hoặc sticker và tên sự kiện. |
| LOG-02 | Khi chọn emoji, hệ thống điền tên mặc định theo tên emoji; người dùng được đổi tên. |
| LOG-03 | Chạm nút sự kiện phải tạo ngay một bản ghi với thời điểm hiện tại, không mở form và không yêu cầu nhập thêm. |
| LOG-04 | Không cung cấp Undo. Với bản ghi đã tạo, chỉ cho phép Delete; không sửa nội dung hoặc thời điểm. |
| LOG-05 | Người dùng được tạo, sửa và sắp xếp thứ tự các loại sự kiện. |
| HIS-01 | Hiển thị lịch sử theo ngày và lần ghi gần nhất của từng loại sự kiện. |
| HIS-02 | Cho phép xóa bản ghi trong lịch sử; lịch sử, lần ghi gần nhất và thống kê phải được cập nhật tương ứng. |
| STA-01 | Hiển thị số lần ghi theo tuần, tháng và phân bố bản ghi theo khung giờ để người dùng quan sát quy luật sinh hoạt. |

## 4 Yêu cầu chia sẻ và dữ liệu

| Mã | Yêu cầu chức năng |
| --- | --- |
| SOC-01 | Hiển thị QR cá nhân và cho phép quét QR của người khác để kết bạn. Cách xác nhận kết bạn cần chốt. |
| SOC-02 | Hiển thị danh sách bạn bè và cho phép xóa bạn bè khỏi danh sách. |
| SOC-03 | Hỗ trợ broadcast và multicast. Mặc định broadcast cho tất cả bạn bè. Khi chọn target, chỉ những người đã chọn có quyền xem ngoài chủ sở hữu; thay đổi target phải cập nhật quyền xem tương ứng. |
| SOC-04 | Người dùng xem các sự kiện được chia sẻ cho mình và thả reaction trên các sự kiện đó. |
| WID-01 | Cho phép chọn các nút sự kiện đưa lên widget. Chạm nút trên widget tạo bản ghi với thời điểm hiện tại, theo cùng quy tắc ghi nhanh trong app. |
| DAT-01 | Nhật ký cá nhân phải lưu local và dùng được offline. Chỉ nội dung bản ghi được người dùng chọn chia sẻ mới gửi online; không tự tải toàn bộ nhật ký lên máy chủ. |
| DAT-03 | Khi mất mạng vẫn ghi local. Sự kiện cần chia sẻ phải được lưu chờ gửi và gửi khi có mạng; việc gửi lại không được tạo bản chia sẻ trùng. |

## 5 Luồng sử dụng chính

Ghi nhanh: người dùng chạm nút trong app hoặc widget → hệ thống lưu thời điểm và loại sự kiện vào local → hiển thị đã lưu. Nếu sự kiện có cấu hình chia sẻ, hệ thống gửi online hoặc lưu chờ gửi khi mất mạng.

Xem lại: người dùng mở lịch sử hoặc thống kê → chọn ngày, tuần hoặc tháng → xem các bản ghi, lần ghi gần nhất và phân bố thời gian. Khi xóa bản ghi, các kết quả liên quan được tính lại.

## 6 Cơ chế chia sẻ và quyền xem

Đối với sự kiện được chọn chia sẻ, mặc định dùng broadcast: tất cả bạn bè có quyền xem. Nếu người dùng chọn người nhận cụ thể (target), chuyển sang multicast: chỉ những người trong danh sách target có quyền xem sự kiện, ngoài chủ sở hữu.

Khi người dùng thay đổi target, hệ thống cập nhật quyền xem của sự kiện theo danh sách mới; người ngoài danh sách không còn quyền xem. Nếu không chọn target, áp dụng broadcast. Đề xuất cấu hình chia sẻ trước theo từng loại sự kiện để thao tác ghi nhanh vẫn chỉ cần một lần chạm.

## 7 Quy tắc và chất lượng đề xuất

Các quy tắc sau bổ sung để việc triển khai và nghiệm thu nhất quán; cần xác nhận cùng chủ sản phẩm.

BR-01 — Mỗi bản ghi có mã duy nhất, loại sự kiện và thời điểm ghi. Mỗi lần chạm hợp lệ tạo một bản ghi; chống trùng do gửi lại không được gộp các lần ghi độc lập.

BR-02 — Ghi nhận luôn hoàn tất ở local trước; lỗi mạng không được làm mất bản ghi. Hàng chờ chia sẻ phải còn sau khi đóng và mở lại app, đồng thời giữ thời điểm ghi gốc khi gửi muộn.

BR-03 — Xóa bản ghi đang chờ chia sẻ phải hủy gửi bản ghi đó. Chính sách thu hồi bản đã gửi online cần chốt riêng.

NFR-01 — Ghi nhanh, quản lý loại sự kiện, lịch sử và thống kê cá nhân hoạt động khi không có Internet.

NFR-02 — Chỉ chủ dữ liệu và người nhận được phép mới truy cập được nội dung chia sẻ; QR không chứa nhật ký. Thông tin định danh và quan hệ bạn bè phục vụ tính năng xã hội được xử lý riêng.

NFR-03 — Chỉ báo “đã lưu” khi ghi local thành công; nếu thất bại phải báo lỗi. Phân biệt trạng thái đã lưu local với trạng thái gửi chia sẻ.

## 8 Tiêu chí nghiệm thu chính

AC-01 — Ở chế độ máy bay, chạm nút trong app hoặc widget tạo đúng một bản ghi đúng thời điểm, không mở form; mở lại app vẫn thấy bản ghi.

AC-02 — Tạo, sửa, sắp xếp loại sự kiện hoạt động; chọn emoji điền tên mặc định và cho phép đổi tên.

AC-03 — Xóa một bản ghi làm lịch sử, lần ghi gần nhất và thống kê khớp dữ liệu còn lại; không có Undo hoặc sửa bản ghi.

AC-04 — QR và danh sách bạn bè hoạt động theo quy tắc đã chốt; người nhận hợp lệ xem được sự kiện và thả reaction, người ngoài danh sách nhận không xem được.

AC-05 — Ghi sự kiện chia sẻ khi offline, mở lại app và kết nối mạng: sự kiện được gửi với thời điểm gốc. Gửi lại nhiều lần vẫn chỉ có một bản chia sẻ cho mỗi người nhận.

AC-06 — Sự kiện chia sẻ mặc định được tất cả bạn bè xem. Khi chọn target, chỉ chủ sở hữu và những người đã chọn xem được. Đổi target phải cập nhật quyền xem theo danh sách mới; bỏ toàn bộ target phải trở về broadcast.

## 9 Các quyết định cần chốt

1. Android, iOS hay cả hai; phương thức định danh hoặc đăng nhập cho tính năng bạn bè; kết bạn trực tiếp hay cần người kia đồng ý.
2. Phạm vi áp dụng cấu hình chia sẻ theo loại sự kiện hay từng bản ghi; quyền xem bản cũ khi thêm hoặc xóa bạn, hoặc khi xóa bản ghi; cách áp dụng thay đổi quyền khi offline.
3. Múi giờ, ngày bắt đầu tuần và khung giờ thống kê; ảnh hưởng của đổi tên loại sự kiện lên lịch sử; bộ reaction được hỗ trợ.
