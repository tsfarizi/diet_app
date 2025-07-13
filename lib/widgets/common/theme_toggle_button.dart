import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../themes/app_theme.dart';
import '../../themes/color_constants.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final double size;
  
  const ThemeToggleButton({
    super.key,
    this.showLabel = true,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppTheme>(
      builder: (context, themeProvider, child) {
        return PopupMenuButton<ThemeMode>(
          icon: Icon(
            themeProvider.themeIcon,
            size: size,
          ).animate().scale(duration: 200.ms),
          tooltip: 'Change Theme',
          onSelected: (ThemeMode mode) {
            themeProvider.setThemeMode(mode);
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: ThemeMode.light,
              child: Row(
                children: [
                  Icon(
                    Icons.light_mode,
                    color: themeProvider.themeMode == ThemeMode.light
                        ? AppColors.primaryGreen
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Light',
                    style: TextStyle(
                      fontWeight: themeProvider.themeMode == ThemeMode.light
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: themeProvider.themeMode == ThemeMode.light
                          ? AppColors.primaryGreen
                          : null,
                    ),
                  ),
                  if (themeProvider.themeMode == ThemeMode.light) ...[
                    const Spacer(),
                    const Icon(
                      Icons.check,
                      color: AppColors.primaryGreen,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode,
                    color: themeProvider.themeMode == ThemeMode.dark
                        ? AppColors.primaryGreen
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Dark',
                    style: TextStyle(
                      fontWeight: themeProvider.themeMode == ThemeMode.dark
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: themeProvider.themeMode == ThemeMode.dark
                          ? AppColors.primaryGreen
                          : null,
                    ),
                  ),
                  if (themeProvider.themeMode == ThemeMode.dark) ...[
                    const Spacer(),
                    const Icon(
                      Icons.check,
                      color: AppColors.primaryGreen,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.system,
              child: Row(
                children: [
                  Icon(
                    Icons.auto_mode,
                    color: themeProvider.themeMode == ThemeMode.system
                        ? AppColors.primaryGreen
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'System',
                    style: TextStyle(
                      fontWeight: themeProvider.themeMode == ThemeMode.system
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: themeProvider.themeMode == ThemeMode.system
                          ? AppColors.primaryGreen
                          : null,
                    ),
                  ),
                  if (themeProvider.themeMode == ThemeMode.system) ...[
                    const Spacer(),
                    const Icon(
                      Icons.check,
                      color: AppColors.primaryGreen,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class AnimatedThemeToggle extends StatelessWidget {
  const AnimatedThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppTheme>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () => themeProvider.toggleTheme(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  themeProvider.themeIcon,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  themeProvider.currentThemeName,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).scale(duration: 200.ms),
        );
      },
    );
  }
}