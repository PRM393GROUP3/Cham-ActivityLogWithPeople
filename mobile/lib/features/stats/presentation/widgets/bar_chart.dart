import 'package:flutter/material.dart';

/// Biểu đồ cột dọc gọn nhẹ (không dùng thư viện). Cột cao nhất chạm đỉnh; số đếm hiện trên cột
/// khi còn đủ chỗ.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 120,
    this.highlightIndex,
  });

  final List<int> values;

  /// Nhãn dưới từng cột; `null` = bỏ trống (cho trục dày như 24 giờ hay 31 ngày).
  final List<String?> labels;
  final double height;

  /// Cột được tô đậm (vd. hôm nay).
  final int? highlightIndex;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold(0, (a, b) => a > b ? a : b);
    final showCounts = values.length <= 12;
    return SizedBox(
      // Số đếm (14) + 2 + cột (tối đa [height]) + 4 + nhãn (14), cộng chút dư.
      height: height + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Tooltip(
                message: '${labels[i] ?? i}: ${values[i]}',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showCounts)
                      SizedBox(
                        height: 14,
                        child: Text(
                          values[i] > 0 ? '${values[i]}' : '',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF6E6259)),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Container(
                      height: maxValue == 0 ? 2 : 2 + (height - 2) * values[i] / maxValue,
                      margin: EdgeInsets.symmetric(horizontal: values.length > 12 ? 1 : 4),
                      decoration: BoxDecoration(
                        color: values[i] == 0
                            ? const Color(0xFFEDE4D6)
                            : i == highlightIndex
                                ? const Color(0xFFB53216)
                                : const Color(0xFFF08A6E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 14,
                      child: Text(
                        labels[i] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        softWrap: false,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF8A7E74)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
