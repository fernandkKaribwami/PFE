import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.greyDark100 : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? Colors.grey[400] : Colors.grey[600],
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: [
            _buildNavItem(
              icon: currentIndex == 0 ? Icons.home : Icons.home_outlined,
              label: 'Home',
              isSelected: currentIndex == 0,
            ),
            _buildNavItem(
              icon: currentIndex == 1 ? Icons.search : Icons.search_outlined,
              label: 'Search',
              isSelected: currentIndex == 1,
            ),
            _buildNavItem(
              icon: Icons.add_box_outlined,
              label: 'Create',
              isSelected: currentIndex == 2,
            ),
            _buildNavItem(
              icon: currentIndex == 3 ? Icons.chat_bubble : Icons.chat_bubble_outline,
              label: 'Messages',
              isSelected: currentIndex == 3,
            ),
            _buildNavItem(
              icon: currentIndex == 4 ? Icons.person : Icons.person_outline,
              label: 'Profile',
              isSelected: currentIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isSelected ? 8 : 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: isSelected ? 28 : 24,
        ),
      ),
      label: label,
    );
  }
}