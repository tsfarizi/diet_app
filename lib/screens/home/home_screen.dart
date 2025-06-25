import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/auth_service.dart';
import '../../themes/app_theme.dart';
import '../../themes/color_constants.dart';
import '../../widgets/common/theme_toggle_button.dart';
import '../tracking/tracking_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const EnhancedDashboardPage(),
    const TrackingScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppTheme>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: themeProvider.isDarkMode 
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
              selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
              unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_rounded),
                  label: 'Track',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class EnhancedDashboardPage extends StatelessWidget {
  const EnhancedDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppTheme>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text('Diet Tracker'),
            centerTitle: false,
            actions: [
              const ThemeToggleButton(size: 20),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  await authService.signOut();
                },
                tooltip: 'Logout',
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: themeProvider.isDarkMode
                    ? const LinearGradient(
                        colors: [AppColors.surfaceDark, AppColors.cardDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AppColors.primaryGradient,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingSection(context, themeProvider),
                const SizedBox(height: 20),
                _buildEnhancedSummaryCard(context, themeProvider),
                const SizedBox(height: 20),
                _buildQuickActionsSection(context, themeProvider),
                const SizedBox(height: 20),
                _buildEnhancedRecentMeals(context, themeProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreetingSection(BuildContext context, AppTheme themeProvider) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final now = DateTime.now();
    String greeting = 'Good Morning';
    
    if (now.hour >= 12 && now.hour < 17) {
      greeting = 'Good Afternoon';
    } else if (now.hour >= 17) {
      greeting = 'Good Evening';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: themeProvider.isDarkMode
            ? LinearGradient(
                colors: [
                  AppColors.primaryGreenLight.withValues(alpha: 0.1),
                  AppColors.accentGreen.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppColors.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode ? Colors.black26 : Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: themeProvider.isDarkMode ? AppColors.textPrimaryDark : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
          
          const SizedBox(height: 4),
          
          StreamBuilder(
            stream: authService.authStateChanges,
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Text(
                user?.displayName ?? 'Welcome to Diet Tracker!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: themeProvider.isDarkMode ? AppColors.textPrimaryDark : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideX(begin: -0.2);
            },
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Ready to track your healthy journey today?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: themeProvider.isDarkMode 
                  ? AppColors.textSecondaryDark 
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ).animate().fadeIn(duration: 700.ms, delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildEnhancedSummaryCard(BuildContext context, AppTheme themeProvider) {
    return Card(
      elevation: 4,
      shadowColor: themeProvider.isDarkMode ? Colors.black38 : Colors.grey.shade300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.today_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Today\'s Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2),
            
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildEnhancedSummaryItem(
                    context,
                    'Calories',
                    '0',
                    '2000',
                    Icons.local_fire_department_rounded,
                    AppColors.caloriesColor,
                    themeProvider,
                  ).animate().fadeIn(duration: 600.ms, delay: 100.ms).scale(),
                ),
                Expanded(
                  child: _buildEnhancedSummaryItem(
                    context,
                    'Protein',
                    '0g',
                    '50g',
                    Icons.fitness_center_rounded,
                    AppColors.proteinColor,
                    themeProvider,
                  ).animate().fadeIn(duration: 600.ms, delay: 200.ms).scale(),
                ),
                Expanded(
                  child: _buildEnhancedSummaryItem(
                    context,
                    'Water',
                    '0ml',
                    '2000ml',
                    Icons.water_drop_rounded,
                    AppColors.waterColor,
                    themeProvider,
                  ).animate().fadeIn(duration: 600.ms, delay: 300.ms).scale(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSummaryItem(
    BuildContext context,
    String label,
    String value,
    String target,
    IconData icon,
    Color color,
    AppTheme themeProvider,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'of $target',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, AppTheme themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.add_circle_rounded,
                title: 'Add Meal',
                subtitle: 'Track your food',
                color: AppColors.primaryGreen,
                onTap: () {
                },
              ).animate().fadeIn(duration: 600.ms, delay: 100.ms).scale(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                context,
                icon: Icons.water_drop_rounded,
                title: 'Add Water',
                subtitle: 'Stay hydrated',
                color: AppColors.blue,
                onTap: () {
                },
              ).animate().fadeIn(duration: 600.ms, delay: 200.ms).scale(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedRecentMeals(BuildContext context, AppTheme themeProvider) {
    return Card(
      elevation: 4,
      shadowColor: themeProvider.isDarkMode ? Colors.black38 : Colors.grey.shade300,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.orange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recent Meals',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                  },
                  child: const Text('View All'),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.2),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No meals tracked yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to add your first meal',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 600.ms, delay: 100.ms),
          ],
        ),
      ),
    );
  }
}