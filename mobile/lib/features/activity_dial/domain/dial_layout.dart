import 'activity_event_type.dart';

/// Sức chứa của 3 quỹ đạo, từ trong ra ngoài.
const dialRingCapacity = [6, 6, 7];

/// Xếp các loại sự kiện theo thứ tự người dùng đặt (LOG-05): 6 loại đầu ở vòng trong, 6 loại
/// tiếp ở vòng giữa, 7 loại tiếp ở vòng ngoài, chia đều quanh vòng bắt đầu từ đỉnh 12 giờ.
/// Phần còn lại (từ loại thứ 20) trả về ở [rest] để hiển thị thành hàng bên dưới vòng Dial.
({List<ActivityEventType> dial, List<ActivityEventType> rest}) layoutDial(List<ActivityEventType> ordered) {
  final dial = <ActivityEventType>[];
  var index = 0;
  for (var ring = 0; ring < dialRingCapacity.length && index < ordered.length; ring++) {
    final count = (ordered.length - index).clamp(0, dialRingCapacity[ring]);
    final step = 360 / count;
    for (var i = 0; i < count; i++) {
      dial.add(ordered[index++].copyWith(orbit: ring + 1, angleDegree: -90 + step * i));
    }
  }
  final rest = [for (final t in ordered.skip(index)) t.copyWith(orbit: 0, angleDegree: 0)];
  return (dial: dial, rest: rest);
}
