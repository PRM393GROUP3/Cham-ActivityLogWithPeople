import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/share_op.dart';

final shareOutboxProvider = Provider<ShareOutbox>((ref) => ShareOutbox());

/// Hàng đợi chia sẻ chờ gửi, lưu bền qua SharedPreferences để còn sau khi tắt app (BR-02).
/// Khoá theo id bản ghi: thêm thao tác mới cho cùng bản ghi sẽ thay thao tác cũ.
class ShareOutbox {
  static const _key = 'cham_share_outbox_v1';

  Future<List<ShareOp>> load() async => (await _read()).values.toList();

  Future<bool> contains(String recordId) async => (await _read()).containsKey(recordId);

  Future<void> put(ShareOp op) async {
    final ops = await _read();
    ops[op.recordId] = op;
    await _write(ops);
  }

  /// Xoá [op] sau khi gửi thành công. Không xoá nếu trong lúc gửi đã có thao tác mới hơn
  /// cho cùng bản ghi, để thao tác mới đó vẫn được gửi.
  Future<void> complete(ShareOp op) async {
    final ops = await _read();
    if (ops[op.recordId] == op) {
      ops.remove(op.recordId);
      await _write(ops);
    }
  }

  Future<Map<String, ShareOp>> _read() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return {
        for (final op in list.map((e) => ShareOp.fromJson(e as Map<String, dynamic>))) op.recordId: op,
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(Map<String, ShareOp> ops) async {
    await (await SharedPreferences.getInstance())
        .setString(_key, jsonEncode(ops.values.map((o) => o.toJson()).toList()));
  }
}
