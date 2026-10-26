import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/time/vn_time.dart';
import '../../domain/friend.dart';
import '../controllers/friends_controller.dart';

/// Danh sách bạn bè và huỷ kết bạn (SOC-02).
class FriendsPage extends ConsumerWidget {
  const FriendsPage({super.key});

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref, Friend friend) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Huỷ kết bạn với ${friend.displayName}?'),
        content: const Text(
          'Hai bạn sẽ không còn thấy hoạt động Công khai của nhau, và reaction giữa hai bạn bị xoá. '
          'Muốn kết bạn lại thì quét mã QR của nhau.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ lại')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD34E2F)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Huỷ kết bạn'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(friendsControllerProvider.notifier).remove(friend.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Đã huỷ kết bạn với ${friend.displayName}.'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không huỷ kết bạn được: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsControllerProvider);
    final controller = ref.read(friendsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F0),
        title: Text(
          friends.hasValue ? 'Bạn bè (${friends.value!.length})' : 'Bạn bè',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB53216),
        foregroundColor: Colors.white,
        onPressed: () => Navigator.pushNamed(context, '/add-qr'),
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Thêm bạn'),
      ),
      body: friends.when(
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message(text: '$e', actionLabel: 'Thử lại', onAction: controller.refresh),
        data: (list) => RefreshIndicator(
          onRefresh: controller.refresh,
          child: list.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    _Message(text: 'Chưa có bạn bè nào.\nBấm "Thêm bạn" để quét mã QR hoặc nhập mã mời.'),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _FriendTile(
                    friend: list[i],
                    onRemove: () => _confirmRemove(context, ref, list[i]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.onRemove});

  final Friend friend;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4EB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D6)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE6DFD5),
            child: Text(
              friend.displayName.isNotEmpty ? friend.displayName.characters.first.toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1B18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                Text(
                  'Bạn bè từ ${DateFormat('dd/MM/yyyy').format(VnTime.of(friend.since))}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8A7E74)),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Huỷ kết bạn với ${friend.displayName}',
            icon: const Icon(Icons.person_remove_outlined, color: Color(0xFFD34E2F)),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Column(
        children: [
          const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF6E655F)),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6E655F), height: 1.4)),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB53216)),
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
