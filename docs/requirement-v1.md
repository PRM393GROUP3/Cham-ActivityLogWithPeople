# SRS ứng dụng ghi nhật ký sinh hoạt

Phiên bản 0.11  |  Ngày 1 tháng 11 năm 2026

## 1 Mục đích và phạm vi

Ứng dụng giúp người dùng ghi lại các hoạt động như uống cà phê, đi vệ sinh, chạy bộ hoặc đi ngủ chỉ bằng một lần chạm. Người dùng xem lịch sử và thống kê để nhận ra quy luật sinh hoạt, đồng thời có thể kết bạn bằng QR và chia sẻ các bản ghi đã chọn cho bạn bè.

Phạm vi gồm nhật ký cá nhân offline, quản lý loại sự kiện, thống kê, bạn bè, chia sẻ và reaction, widget. Các mục còn mở được liệt kê ở mục 9.2 và chưa phải quyết định sản phẩm cuối cùng.

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
| LOG-06 | Chạm nút trên vòng Dial có **phản hồi tức thì**: nút nảy, một vòng màu của loại đó lan ra, "+1" bay lên, và thông báo "Đã chấm <tên> lúc HH:mm" (giờ Việt Nam). |
| ONB-01 | Lần đầu mở app hiện **màn chào** 3 trang (ghi một chạm, riêng tư mặc định, kết bạn và reaction) và trang cuối đặt tên hiển thị + avatar emoji (SOC-06). Bỏ qua được ở mọi trang; đặt hồ sơ cần mạng, mất mạng thì báo và cho "Để sau". Chỉ hiện một lần; máy đã có dữ liệu từ bản trước (tài khoản hoặc nhật ký) không hiện. |
| LOG-04 | Không cung cấp Undo. Với bản ghi đã tạo, chỉ cho phép Delete; không sửa nội dung hoặc thời điểm. |
| LOG-05 | Trong **Cài đặt → Loại sự kiện**, người dùng **thêm, sửa (emoji, tên), xoá và kéo thả sắp xếp** mọi loại sự kiện, kể cả 19 loại mặc định. Thứ tự quyết định vị trí: **mọi loại đều nằm trên vòng Dial**: các loại đầu danh sách ở vòng trong, rồi vòng giữa, rồi vòng ngoài (6 / 6 / 7 với 19 loại; từ loại thứ 20, loại mới vào vòng đang thưa nhất so với chu vi — thường là vòng ngoài rồi vòng giữa), các nút trên mỗi vòng chia đều; tối đa 36 loại. Sửa hoặc xoá chỉ áp dụng cho lần chạm sau: **bản ghi cũ giữ emoji và tên lúc ghi** và vẫn nằm trong lịch sử (bản đã Công khai vẫn được chia sẻ). Phải còn ít nhất một loại. |
| NOTE-01 | Mỗi bản ghi có thể có một **ghi chú** dạng văn bản nhiều dòng. Chạm icon ghi chú trên bản ghi trong lịch sử để mở **tờ giấy ghi chú**; ghi chú được lưu khi rời trang hoặc bấm Lưu, được sửa hay xoá (để trống) bất cứ lúc nào. Ghi chú **chỉ lưu trên máy**, không gửi lên server kể cả khi bản ghi Công khai. Ghi chú không thay đổi thời điểm hay loại sự kiện của bản ghi (LOG-04). |
| STA-02 | Trong Lịch sử & thống kê có nút **Tạo ảnh tóm tắt** cho kỳ đang xem (Ngày / Tuần / Tháng của tôi): tổng số chấm, 3 loại nhiều nhất, biểu đồ nhỏ theo giờ (Ngày) hoặc theo ngày (Tuần, Tháng), tên và avatar. **Lưu ảnh** PNG: Android vào thư viện ảnh, Web tải file xuống. Kỳ không có bản ghi thì nút bị tắt. |
| HIS-01 | Hiển thị lịch sử theo ngày và lần ghi gần nhất của từng loại sự kiện. Mỗi bản ghi hiển thị chế độ chia sẻ (Private / Public), trạng thái gửi và dòng đầu của ghi chú (nếu có). |
| HIS-02 | Cho phép xóa bản ghi trong lịch sử; lịch sử, lần ghi gần nhất và thống kê phải được cập nhật tương ứng. |
| STA-01 | Trang **Lịch sử & thống kê** (nút 📊 trên trang chủ, hoặc "Xem lịch sử & thống kê" trong Nhật ký hôm nay) có 3 chế độ **Ngày / Tuần / Tháng**, lùi / tiến từng kỳ (không tiến quá kỳ hiện tại). Mỗi kỳ hiển thị: tổng số lần ghi; số lần theo từng loại sự kiện kèm lần ghi gần nhất của loại đó; số lần theo từng ngày (chế độ Tuần, Tháng); phân bố theo **khung 1 giờ**; danh sách các lần ghi (xoá / ghi chú / đổi chế độ chia sẻ ngay tại đây). Tuần bắt đầu **Thứ Hai**; mọi mốc ngày giờ theo giờ Việt Nam. Chỉ thống kê những gì đã ghi, hoạt động offline. |

## 4 Yêu cầu chia sẻ và dữ liệu

| Mã | Yêu cầu chức năng |
| --- | --- |
| SOC-01 | Hiển thị **mã QR cá nhân chuẩn** (nội dung `CHAM:<mã mời 10 ký tự>`, chỉ chứa mã mời) và cho phép kết bạn bằng: quét QR bằng camera, quét QR từ ảnh (chọn từ thư viện trên Android, hoặc chọn file ảnh trên Web), hoặc nhập mã mời. Mã quét được không phải của Chấm hoặc là mã của chính mình → báo lỗi, không gọi server. **Kết bạn trực tiếp**: sau khi xác nhận, hai người trở thành bạn bè ngay, không cần người kia đồng ý. Người dùng được **đổi mã mời** (mã / QR cũ hết hiệu lực, bạn bè hiện có giữ nguyên) sao chép mã, hoặc **lưu ảnh mã QR** (kèm mã mời) về máy để gửi cho bạn bè. |
| SOC-06 | Người dùng đặt **tên hiển thị** (1–50 ký tự) và **avatar là một emoji** (chọn từ gợi ý hoặc nhập emoji bất kỳ; có thể bỏ để hiện chữ cái đầu của tên) trong màn **Hồ sơ của bạn**. Bạn bè thấy tên và avatar này ở danh sách bạn bè, feed và reaction. Lưu lên server nên cần mạng. |
| SOC-02 | Màn **Bạn bè** (từ hồ sơ hoặc màn QR) hiển thị danh sách bạn bè kèm ngày kết bạn và cho phép **huỷ kết bạn** sau khi xác nhận. Huỷ kết bạn: hai bên không còn thấy bản Công khai của nhau, reaction giữa hai người bị xoá. |
| SOC-03 | Chia sẻ **theo từng bản ghi**, chỉ có 2 chế độ: **Private** (mặc định) và **Public** (tất cả bạn bè). Người dùng đổi chế độ trên bản ghi trong lịch sử. Không hỗ trợ chọn từng người nhận. |
| SOC-04 | Chuyển bản ghi từ Public về Private, hoặc xóa bản ghi Public, phải **thu hồi** sự kiện chia sẻ: không bạn bè nào còn xem được, reaction trên đó bị xóa. |
| SOC-05 | Feed gồm sự kiện Public của bạn bè **và của chính mình**, mới nhất trước. Người dùng thả reaction vào sự kiện của bạn bè; trên sự kiện của mình thì không tự thả được, nhưng xem được số đếm và **danh sách ai đã thả cảm xúc gì** (avatar, tên, emoji, thời gian). Bộ reaction giống Facebook: 👍 Thích, ❤️ Yêu thích, 🥰 Thương thương, 😆 Haha, 😮 Wow, 😢 Buồn, 😡 Phẫn nộ. Mỗi người tối đa **1 reaction** trên mỗi sự kiện, được đổi hoặc gỡ. |
| SOC-07 | **Cập nhật thời gian thực**: khi app mở và máy đã có tài khoản, app giữ kết nối WebSocket với server. Bạn bè chia sẻ / thu hồi bản ghi, kết bạn / huỷ kết bạn → feed và danh sách bạn bè tự tải lại. Bạn bè thả cảm xúc vào bài của mình → thông báo trượt xuống đầu màn hình "<tên> đã thả <emoji> vào <bài> của bạn", ở mọi màn hình. Gỡ cảm xúc không báo. Mất kết nối thì tự nối lại (1, 2, 4… tối đa 30 giây). Thả cảm xúc trong feed có hiệu ứng emoji bay lên từ nút. |
| SOC-08 | **Ngày của bạn bè**: chọn một người (hoặc "Bạn") trên thanh phía trên feed → đầu danh sách hiện vòng Dial thu nhỏ gồm các bản ghi Công khai **hôm nay** (giờ VN) của người đó, sớm nhất ở vòng trong; giữ một chấm để xem tên và giờ. Không có bản Công khai nào hôm nay thì báo như vậy. |
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

AC-02 — Trong Cài đặt thấy đủ 19 loại mặc định; mọi loại (kể cả loại thêm mới) đều hiển thị trên vòng Dial; không thêm được quá 36 loại. Thêm loại mới: chọn emoji điền tên mặc định, đổi được tên. Sửa / xoá / kéo thả một loại: trang chủ cập nhật đúng vị trí theo thứ tự và còn sau khi mở lại app; các bản ghi cũ giữ nguyên emoji, tên và vẫn ở trong lịch sử.

AC-03 — Xóa một bản ghi làm lịch sử, lần ghi gần nhất và thống kê khớp dữ liệu còn lại; không có Undo hoặc sửa bản ghi.

AC-04 — Quét QR hợp lệ làm hai người thành bạn bè ngay, không cần xác nhận. Xóa bạn làm hai người không còn thấy sự kiện Public của nhau.

AC-05 — Chuyển bản ghi sang Public khi offline, mở lại app và kết nối mạng: sự kiện được gửi với thời điểm gốc. Gửi lại nhiều lần vẫn chỉ có một bản chia sẻ.

AC-06 — Bản ghi Private không xuất hiện trên máy chủ và không bạn bè nào thấy. Bản ghi Public được tất cả bạn bè thấy; người không phải bạn bè không thấy. Chuyển về Private hoặc xóa bản ghi thì không ai còn thấy.

AC-07 — Bạn bè thả được một trong 7 reaction (👍 ❤️ 🥰 😆 😮 😢 😡) trên sự kiện Public; thả reaction khác sẽ thay reaction cũ; gỡ được reaction.

AC-08 — Lịch sử theo ngày và thống kê theo khung giờ tính theo múi giờ Việt Nam (UTC+7): bản ghi lúc 23:30 ngày 1 giờ Việt Nam thuộc ngày 1.

AC-09 — Mở ghi chú của một bản ghi, viết nhiều dòng rồi quay lại: lịch sử hiện dòng đầu ghi chú; mở lại app vẫn còn. Bản ghi Công khai có ghi chú: bạn bè không thấy ghi chú.

AC-10 — Trang Lịch sử & thống kê: chế độ Tuần bắt đầu Thứ Hai; một bản ghi lúc 23:30 Chủ Nhật giờ VN thuộc tuần đó, bản ghi 00:00 Thứ Hai thuộc tuần sau; số theo loại, theo ngày, theo giờ khớp danh sách bản ghi; xoá một bản ghi tại đây thì các số liệu cập nhật ngay.

AC-11 — Quét bằng camera mã QR cá nhân của người khác → hộp xác nhận → kết bạn ngay; quét mã QR không phải của Chấm hoặc mã của chính mình → báo lỗi. Đổi mã mời → mã cũ không kết bạn được nữa. Huỷ kết bạn trong màn Bạn bè → người đó biến khỏi danh sách và feed.

AC-12 — Đổi tên và chọn avatar emoji trong Hồ sơ → sau khi lưu, trang chủ, hồ sơ và màn QR hiện avatar mới; bạn bè thấy tên và avatar mới trong danh sách bạn bè và feed. Avatar không phải đúng một emoji (vd. chữ, nhiều emoji) bị từ chối. Bỏ avatar → hiện chữ cái đầu của tên.

AC-13 — Chuyển một bản ghi sang Công khai → bản ghi xuất hiện trong feed của chính mình với nhãn "Bạn". Khi bạn bè thả cảm xúc, bài đó hiện số đếm và "N người đã thả cảm xúc · Xem"; mở ra thấy đúng người và emoji. Không thả được cảm xúc cho bài của mình.

AC-14 — Hai máy là bạn bè, cùng mở app: máy B thả ❤️ vào bài Công khai của máy A → trong vài giây máy A hiện "B đã thả ❤️ vào … của bạn" mà không cần làm mới; feed của A cập nhật số đếm. Tắt mạng rồi bật lại: thông báo vẫn đến (app tự nối lại).

AC-15 — Chọn một người bạn trên thanh phía trên feed → thấy "Ngày của <tên>" với đúng các bản Công khai hôm nay của người đó; bản của hôm qua không có. Chọn "Tất cả" → vòng Dial biến mất.

AC-16 — Cài mới: thấy màn chào; đặt tên "Khoa" + 🐻 rồi "Bắt đầu chấm" → trang chủ hiện avatar 🐻, mở lại app không thấy màn chào nữa. Cập nhật từ bản cũ có dữ liệu: vào thẳng trang chủ.

AC-17 — Tuần có 3 lần Cà phê và 1 lần Chạy bộ → ảnh tóm tắt "Tuần của tôi" ghi 4 chấm, Cà phê đứng đầu với "3 lần"; Lưu ảnh tạo được file PNG.

## 9 Quyết định sản phẩm

### 9.1 Đã chốt

| Chủ đề | Quyết định |
| --- | --- |
| Nền tảng | Android và Web (Flutter) |
| Kết bạn | Trực tiếp qua QR, không cần người kia đồng ý |
| Phạm vi chia sẻ | Theo từng bản ghi, chọn sau khi ghi |
| Chế độ chia sẻ | Private (mặc định) / Public (tất cả bạn bè); không chọn từng người nhận |
| Thu hồi | Được: chuyển về Private hoặc xóa bản ghi |
| Loại sự kiện | Thêm / sửa / xoá / sắp xếp trong Cài đặt (cả loại mặc định); tất cả nằm trên vòng Dial theo thứ tự, tối đa 36; bản ghi cũ giữ nguyên |
| Ghi chú | Mỗi bản ghi một ghi chú, sửa được, chỉ lưu trên máy |
| Bản ghi | Chỉ tạo và xóa; không sửa, không Undo |
| Múi giờ | Việt Nam (UTC+7) |
| Reaction | Bộ 7 reaction giống Facebook, mỗi người 1 reaction trên mỗi sự kiện |
| Thời gian thực | Feed, bạn bè và thông báo reaction cập nhật qua WebSocket; server chỉ gửi gợi ý, app tải lại qua API |

### 9.2 Còn mở

1. Ngày bắt đầu tuần cho thống kê và độ rộng khung giờ — **đang áp dụng đề xuất: Thứ Hai, khung 1 giờ**; cần chủ sản phẩm xác nhận.
2. Phương thức định danh cho tính năng bạn bè (backend hiện dùng tài khoản ẩn danh: `POST /api/auth/register` cấp token, không cần email hay mật khẩu).
