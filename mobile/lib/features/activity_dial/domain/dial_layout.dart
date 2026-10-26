import 'activity_event_type.dart';

/// Số nút mỗi vòng (trong, giữa, ngoài) khi có đủ 19 loại — đúng thiết kế gốc.
const dialBaseCapacity = [6, 6, 7];

/// Bán kính tương đối của 3 vòng (khớp `OrbitalDialWidget`): vòng rộng hơn chứa được nhiều nút hơn.
const _ringRadius = [67.0, 117.0, 162.0];

/// Tối đa số loại sự kiện: quá mức này nhãn tên trên vòng ngoài chồng lên nhau ở màn hình ~390px.
const maxEventTypes = 36;

/// Số nút trên từng vòng khi có [count] loại sự kiện. Lấp 6 / 6 / 7 trước; mỗi loại thêm từ thứ 20
/// vào vòng đang thưa nhất so với bán kính (thường là vòng ngoài, rồi vòng giữa).
List<int> dialRingSizes(int count) {
  final sizes = [0, 0, 0];
  var left = count;
  for (var i = 0; i < sizes.length; i++) {
    sizes[i] = left < dialBaseCapacity[i] ? left : dialBaseCapacity[i];
    left -= sizes[i];
  }
  while (left > 0) {
    var best = 0;
    for (var i = 1; i < sizes.length; i++) {
      if ((sizes[i] + 1) / _ringRadius[i] < (sizes[best] + 1) / _ringRadius[best]) best = i;
    }
    sizes[best]++;
    left--;
  }
  return sizes;
}

/// Đặt mọi loại sự kiện lên vòng Dial theo thứ tự người dùng sắp xếp (LOG-05): lấp vòng trong,
/// rồi vòng giữa, rồi vòng ngoài theo [dialRingSizes]; các nút trên mỗi vòng chia đều, bắt đầu
/// từ đỉnh 12 giờ (vòng đã nhận thêm nút thì lệch nửa bước).
List<ActivityEventType> layoutDial(List<ActivityEventType> ordered) {
  final sizes = dialRingSizes(ordered.length);
  final placed = <ActivityEventType>[];
  var index = 0;
  for (var ring = 0; ring < sizes.length; ring++) {
    final step = sizes[ring] == 0 ? 0.0 : 360 / sizes[ring];
    // Vòng có nhiều nút hơn thiết kế gốc được xoay nửa bước, để nút của hai vòng cạnh nhau
    // so le nhau và nhãn tên ít chồng lên nhau.
    final start = sizes[ring] > dialBaseCapacity[ring] ? -90 + step / 2 : -90.0;
    for (var i = 0; i < sizes[ring]; i++) {
      placed.add(ordered[index++].copyWith(orbit: ring + 1, angleDegree: start + step * i));
    }
  }
  return placed;
}

/// Vòng mà loại ở vị trí [index] (theo thứ tự trong Cài đặt) sẽ nằm khi có [count] loại: 1, 2 hoặc 3.
int dialRingOf(int index, int count) {
  final sizes = dialRingSizes(count);
  var end = 0;
  for (var ring = 0; ring < sizes.length; ring++) {
    end += sizes[ring];
    if (index < end) return ring + 1;
  }
  return sizes.length;
}
