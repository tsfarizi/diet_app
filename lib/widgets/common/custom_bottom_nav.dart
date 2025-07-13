import 'package:flutter/material.dart';
import '../../themes/color_constants.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isDarkMode;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final List<IconData> navIcons = [
      Icons.home_rounded,
      Icons.restaurant_rounded,
      Icons.fitness_center_rounded,
      Icons.analytics_rounded,
      Icons.person_rounded,
    ];

    final List<String> navLabels = [
      'Home',
      'Food',
      'Cardio',
      'Analytics',
      'Profile',
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? AppColors.shadowDark : AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navIcons.length, (index) {
              final isSelected = index == currentIndex;
              final color = isSelected 
                  ? (isDarkMode ? AppColors.primaryGreenLight : AppColors.primaryGreen)
                  : (isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

              return GestureDetector(
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          navIcons[index],
                          size: isSelected ? 28 : 24,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: isSelected ? 12 : 10,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: color,
                        ),
                        child: Text(navLabels[index]),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}