import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/user_provider.dart';
import '../services/realtime_service.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'chat_screen.dart';
import 'create_post_screen.dart';
import 'modern_feed_screen.dart';
import 'modern_profile_screen.dart';
import 'search_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  StreamSubscription<Map<String, dynamic>>? _profileSubscription;

  final List<Widget> _screens = const [
    ModernFeedScreen(),
    SearchScreen(),
    CreatePostScreen(),
    ChatScreen(),
    ModernProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
        return;
      }

      feedProvider.loadFeed(token);
      notificationProvider.loadNotifications(token);

      final userId =
          authProvider.user?['_id']?.toString() ??
          authProvider.user?['id']?.toString();
      if (userId != null && userId.isNotEmpty) {
        RealtimeService.instance.connect(userId: userId);
        _notificationSubscription = RealtimeService.instance.notifications
            .listen((notification) {
              notificationProvider.addNotification(notification);
            });
        _profileSubscription = RealtimeService.instance.profileUpdates.listen((
          profile,
        ) {
          final updatedUserId = profile['_id']?.toString();
          if (updatedUserId == null || updatedUserId != userId) {
            return;
          }

          authProvider.mergeUser(profile);
          userProvider.mergeCurrentUser(profile);
        });
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _profileSubscription?.cancel();
    RealtimeService.instance.disconnect();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
