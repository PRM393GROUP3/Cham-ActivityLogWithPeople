import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../account/domain/avatar.dart';
import '../../../account/domain/username.dart';
import '../../../account/presentation/account_controller.dart';
import '../../../account/presentation/widgets/avatar_emoji_grid.dart';
import '../../../account/presentation/widgets/user_avatar.dart';

/// Màn chào lần đầu mở app: ba trang giới thiệu, trang cuối đặt tên người dùng (duy nhất), họ tên
/// và avatar emoji.
/// Đặt hồ sơ cần mạng (tạo tài khoản ẩn danh); bỏ qua được và đặt lại sau trong Hồ sơ.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _intros = [
    (
      emojis: ['☕', '🏃', '📖', '🍽️', '🌙', '🎧'],
      title: 'Mỗi việc là một chấm',
      body: 'Chạm một biểu tượng trên vòng tròn để ghi lại việc vừa làm. Không cần viết, không cần chụp ảnh.',
    ),
    (
      emojis: ['🔒'],
      title: 'Riêng tư là mặc định',
      body: 'Nhật ký nằm trên máy bạn. Chỉ những chấm bạn bật Công khai mới tới được bạn bè.',
    ),
    (
      emojis: ['❤️', '🥰', '😆', '👍'],
      title: 'Gần nhau bằng một chạm',
      body: 'Kết bạn bằng mã QR. Bạn bè chấm gì, bạn thả một cảm xúc là đủ.',
    ),
  ];

  final _pages = PageController();
  final _username = TextEditingController();
  final _name = TextEditingController();
  int _page = 0;
  String? _emoji;
  bool _saving = false;
  String? _usernameError;
  String? _nameError;
  String? _error;

  int get _pageCount => _intros.length + 1;

  @override
  void dispose() {
    _pages.dispose();
    _username.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next() => _pages.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);

  Future<void> _finish() async {
    final name = _name.text.trim();
    setState(() {
      _usernameError = usernameError(_username.text);
      _nameError = name.isEmpty
          ? 'Hãy nhập họ và tên.'
          : name.characters.length > 50
              ? 'Họ và tên tối đa 50 ký tự.'
              : null;
      _error = _emoji != null && !isSingleEmoji(_emoji!) ? 'Avatar phải là đúng một emoji.' : null;
    });
    if (_usernameError != null || _nameError != null || _error != null) return;

    setState(() => _saving = true);
    try {
      await ref.read(accountControllerProvider.notifier).updateProfile(
            displayName: name,
            username: normalizeUsername(_username.text),
            avatarEmoji: () => _emoji,
          );
      widget.onDone();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'USERNAME_TAKEN') {
          _usernameError = e.message;
        } else {
          _error = 'Chưa kết nối được. Bạn có thể bấm "Để sau" và đặt lại trong Hồ sơ.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Chưa kết nối được. Bạn có thể bấm "Để sau" và đặt lại trong Hồ sơ.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pageCount - 1;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _saving ? null : widget.onDone, child: Text(last ? 'Để sau' : 'Bỏ qua')),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final intro in _intros) _IntroSlide(emojis: intro.emojis, title: intro.title, body: intro.body),
                  _profileSlide(),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pageCount; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? const Color(0xFFFF6F52) : const Color(0xFFE2D6C8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB53216),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saving ? null : (last ? _finish : _next),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          last ? 'Bắt đầu chấm' : 'Tiếp tục',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileSlide() {
    final name = _name.text.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      children: [
        Center(
          child: UserAvatar(name: name.isEmpty ? '?' : name, emoji: _emoji, radius: 40),
        ),
        const SizedBox(height: 14),
        const Text(
          'Bạn bè sẽ gọi bạn là gì?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF261E1A)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Chọn một emoji làm gương mặt của bạn.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13.5, color: Color(0xFF7E7268)),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const ValueKey('onboarding-username'),
          controller: _username,
          maxLength: usernameMaxLength,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword, // bàn phím không gợi ý / tự viết hoa
          inputFormatters: [FilteringTextInputFormatter.allow(usernameAllowedChars)],
          decoration: InputDecoration(
            labelText: 'Tên người dùng',
            prefixText: '@',
            helperText: 'Duy nhất, bạn bè dùng để nhận ra bạn.',
            errorText: _usernameError,
            errorMaxLines: 2,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() => _usernameError = null),
        ),
        const SizedBox(height: 4),
        TextField(
          key: const ValueKey('onboarding-name'),
          controller: _name,
          maxLength: 50,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Họ và tên',
            errorText: _nameError,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() => _nameError = null),
        ),
        AvatarEmojiGrid(
          selected: _emoji,
          onPick: (e) => setState(() {
            _emoji = e;
            _error = null;
          }),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFD34E2F)),
          ),
        ],
      ],
    );
  }
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({required this.emojis, required this.title, required this.body});

  final List<String> emojis;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 220, height: 220, child: _EmojiOrbit(emojis: emojis)),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color(0xFF261E1A)),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF6E6259)),
          ),
        ],
      ),
    );
  }
}

/// Emoji xếp đều trên một vòng quanh chấm cam ở giữa — gợi lại vòng Dial; một emoji thì nằm giữa.
class _EmojiOrbit extends StatelessWidget {
  const _EmojiOrbit({required this.emojis});

  final List<String> emojis;

  @override
  Widget build(BuildContext context) {
    if (emojis.length == 1) {
      return Center(
        child: Container(
          width: 150,
          height: 150,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Color(0xFFFFF0E8), shape: BoxShape.circle),
          child: Text(emojis.single, style: const TextStyle(fontSize: 72)),
        ),
      );
    }
    return Stack(
      children: [
        Center(
          child: Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEADFD3), width: 1.5),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(color: Color(0xFFFF6F52), shape: BoxShape.circle),
          ),
        ),
        for (var i = 0; i < emojis.length; i++)
          Align(
            alignment: Alignment(
              cos(-pi / 2 + 2 * pi * i / emojis.length) * 0.76,
              sin(-pi / 2 + 2 * pi * i / emojis.length) * 0.76,
            ),
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(emojis[i], style: const TextStyle(fontSize: 22)),
            ),
          ),
      ],
    );
  }
}
