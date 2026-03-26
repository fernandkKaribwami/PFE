import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../providers/notification_provider.dart';
import '../screens/modern_feed_screen.dart';
import '../screens/search_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/modern_profile_screen.dart';
import '../widgets/bottom_navigation_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const ModernFeedScreen(),
    const SearchScreen(),
    const CreatePostScreen(),
    const ChatScreen(),
    const ModernProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final feedProvider = Provider.of<FeedProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );

      // Load initial data
      feedProvider.loadFeed(authProvider.token!);
      notificationProvider.loadNotifications(authProvider.token!);
    });
  }

  @override
  void dispose() {
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
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('USMBA Social'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Dashboard Admin',
              onPressed: () => Navigator.pushNamed(context, '/admin'),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await authProvider.logout();
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
      extendBody: true, // Allow content to extend behind navigation bar
    );
  }
}
