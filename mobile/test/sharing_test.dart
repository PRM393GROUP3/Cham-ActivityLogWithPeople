import 'package:cham/features/account/data/account_api.dart';
import 'package:cham/features/activity_dial/domain/activity_event_type.dart';
import 'package:cham/features/activity_dial/domain/activity_log.dart';
import 'package:cham/features/activity_dial/presentation/activity_dial_controller.dart';
import 'package:cham/features/sharing/data/share_api.dart';
import 'package:cham/features/sharing/data/share_outbox.dart';
import 'package:cham/features/sharing/domain/share_op.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ShareOutbox (DAT-03, BR-02)', () {
    final at = DateTime.utc(2026, 10, 1, 1, 30);
    final publish = ShareOp.publish(recordId: 'r1', emoji: '☕', name: 'Cà phê', occurredAt: at);

    test('keeps only the latest intent per record and survives a reload', () async {
      await ShareOutbox().put(publish);
      await ShareOutbox().put(const ShareOp.revoke('r1'));
      await ShareOutbox().put(const ShareOp.revoke('r2'));

      final ops = await ShareOutbox().load(); // instance mới = đọc lại từ storage
      expect(ops, unorderedEquals([const ShareOp.revoke('r1'), const ShareOp.revoke('r2')]));
    });

    test('complete() does not drop a newer op queued while the old one was in flight', () async {
      final outbox = ShareOutbox();
      await outbox.put(publish);
      await outbox.put(const ShareOp.revoke('r1')); // người dùng đổi ý trong lúc đang gửi
      await outbox.complete(publish);
      expect(await outbox.load(), [const ShareOp.revoke('r1')]);

      await outbox.complete(const ShareOp.revoke('r1'));
      expect(await outbox.load(), isEmpty);
    });

    test('publish op keeps the original occurredAt through JSON, even from local time', () {
      final local = ShareOp.publish(recordId: 'r1', emoji: '☕', name: 'Cà phê', occurredAt: at.toLocal());
      final restored = ShareOp.fromJson(local.toJson());
      expect(restored, local);
      expect(restored.occurredAt!.isAtSameMomentAs(at), isTrue);
    });
  });

  group('ActivityDialController sharing flow', () {
    late FakeShareApi shareApi;
    late FakeAccountApi accountApi;
    late ProviderContainer container;

    ActivityDialController controller() => container.read(activityDialControllerProvider.notifier);
    ActivityLog logById(String id) => container.read(activityDialControllerProvider).logs.firstWhere((l) => l.id == id);

    setUp(() async {
      shareApi = FakeShareApi();
      accountApi = FakeAccountApi();
      container = ProviderContainer(overrides: [
        shareApiProvider.overrideWithValue(shareApi),
        accountApiProvider.overrideWithValue(accountApi),
      ]);
      addTearDown(container.dispose);
      container.read(activityDialControllerProvider);
      await settle();
    });

    final coffee = ActivityEventType.defaultTypes.firstWhere((t) => t.id == 'coffee');

    test('one tap creates a Private record and sends nothing (LOG-03, AC-06)', () async {
      final log = await controller().quickLog(coffee);
      await settle();

      expect(log.visibility, ShareVisibility.private);
      expect(shareApi.sent, isEmpty);
      expect(accountApi.calls, 0, reason: 'Private use must not need an account (DAT-01)');
    });

    test('making a record Public registers lazily and sends it with the original time (SOC-03)', () async {
      final log = await controller().quickLog(coffee);
      await controller().setVisibility(log.id, ShareVisibility.public);

      expect(accountApi.calls, 1);
      expect(shareApi.sent.single.type, ShareOpType.publish);
      expect(shareApi.sent.single.recordId, log.id);
      expect(shareApi.sent.single.occurredAt!.isAtSameMomentAs(log.occurredAt), isTrue);
      expect(logById(log.id).syncStatus, ShareSyncStatus.synced);
      expect(await ShareOutbox().load(), isEmpty);
    });

    test('offline: stays queued as failed, then sends once back online (AC-05)', () async {
      final log = await controller().quickLog(coffee);
      shareApi.online = false;
      await controller().setVisibility(log.id, ShareVisibility.public);

      expect(logById(log.id).visibility, ShareVisibility.public);
      expect(logById(log.id).syncStatus, ShareSyncStatus.failed);
      expect((await ShareOutbox().load()).single.recordId, log.id);

      shareApi.online = true;
      await controller().syncShares();
      await controller().syncShares(); // gửi lại không tạo thêm gì

      expect(shareApi.sent.map((o) => o.recordId), [log.id]);
      expect(logById(log.id).syncStatus, ShareSyncStatus.synced);
    });

    test('Public → Private while offline only sends the revoke (SOC-04)', () async {
      final log = await controller().quickLog(coffee);
      shareApi.online = false;
      await controller().setVisibility(log.id, ShareVisibility.public);
      await controller().setVisibility(log.id, ShareVisibility.private);

      shareApi.online = true;
      await controller().syncShares();
      expect(shareApi.sent, [ShareOp.revoke(log.id)]);
      expect(logById(log.id).visibility, ShareVisibility.private);
    });

    test('deleting a Public record revokes it; deleting a Private one sends nothing (BR-03)', () async {
      final public = await controller().quickLog(coffee);
      final private = await controller().quickLog(coffee);
      await controller().setVisibility(public.id, ShareVisibility.public);
      shareApi.sent.clear();

      await controller().deleteLog(private.id);
      expect(shareApi.sent, isEmpty);

      await controller().deleteLog(public.id);
      expect(shareApi.sent, [ShareOp.revoke(public.id)]);
      expect(container.read(activityDialControllerProvider).logs.any((l) => l.id == public.id), isFalse);
    });

    test('queued changes are sent on the next app start (BR-02)', () async {
      final log = await controller().quickLog(coffee);
      shareApi.online = false;
      await controller().setVisibility(log.id, ShareVisibility.public);

      // "Mở lại app": container mới đọc lại storage và hàng đợi.
      final reopenedApi = FakeShareApi();
      final reopened = ProviderContainer(overrides: [
        shareApiProvider.overrideWithValue(reopenedApi),
        accountApiProvider.overrideWithValue(FakeAccountApi()),
      ]);
      addTearDown(reopened.dispose);
      reopened.read(activityDialControllerProvider);
      await settle();

      expect(reopenedApi.sent.map((o) => o.recordId), [log.id]);
      final restored = reopened.read(activityDialControllerProvider).logs.firstWhere((l) => l.id == log.id);
      expect(restored.syncStatus, ShareSyncStatus.synced);
    });
  });
}
