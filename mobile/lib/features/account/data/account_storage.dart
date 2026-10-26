import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/account.dart';

final accountStorageProvider = Provider<AccountStorage>((ref) => AccountStorage());

class AccountStorage {
  static const _key = 'cham_account_v1';

  Future<Account?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return null;
    try {
      return Account.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Account account) async {
    await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(account.toJson()));
  }
}
