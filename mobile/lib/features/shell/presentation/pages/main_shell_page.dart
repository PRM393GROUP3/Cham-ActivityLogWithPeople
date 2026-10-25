import 'package:flutter/material.dart';
import 'package:cham/features/activity_dial/presentation/pages/activity_dial_page.dart';
import 'package:cham/features/social/presentation/pages/feed_page.dart';

/// Shell page that enables smooth horizontal swiping between the Main Activity Dial (Page 0)
/// and the Social Feed Screen (Page 1), while preserving individual routes.
class MainShellPage extends StatefulWidget {
  const MainShellPage({
    super.key,
    this.initialPage = 0,
  });

  final int initialPage;

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToFeed() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToHome() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F0),
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: [
          ActivityDialPage(onNavigateToFeed: _goToFeed),
          FeedPage(onNavigateToHome: _goToHome),
        ],
      ),
    );
  }
}

