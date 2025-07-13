import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../themes/app_theme.dart';
import '../widgets/common/custom_bottom_nav.dart';
import 'home/home_screen.dart';
import 'tracking/enhanced_tracking_screen.dart';
import 'profile/profile_screen.dart';
import 'cardio/cardio_screen.dart';
import 'analytics/analytics_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;
  bool _isCheckingProfile = true;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _checkProfileComplete();
    _screens = [
      EnhancedDashboardPage(
        onNavigateToTrack: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      const EnhancedTrackingScreen(),
      const CardioScreen(),
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];
  }

  Future<void> _checkProfileComplete() async {
    try {
      final isComplete = await _authService.isProfileComplete();
      setState(() {
        _isCheckingProfile = false;
      });

      if (!isComplete && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CompleteProfileScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCheckingProfile = false;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingProfile) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<AppTheme>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: CustomBottomNav(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
            isDarkMode: themeProvider.isDarkMode,
          ),
        );
      },
    );
  }
}

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController(initialPage: 1);
  final _authService = AuthService();
  
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  
  String _gender = 'male';
  String _activityLevel = 'moderate';
  bool _isLoading = false;
  int _currentPage = 1;

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final currentUser = await _authService.getUserProfile();
        if (currentUser != null) {
          final updatedUser = currentUser.copyWith(
            age: int.parse(_ageController.text),
            weight: double.parse(_weightController.text),
            height: double.parse(_heightController.text),
            gender: _gender,
            activityLevel: _activityLevel,
            goal: 'lose_weight',
            targetWeight: double.parse(_targetWeightController.text),
            updatedAt: DateTime.now(),
          );
          
          await _authService.updateUserProfile(updatedUser);
          
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const MainNavigation(),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi Profil'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentPage) / 2,
              backgroundColor: Colors.grey[300],
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  Container(),
                  _buildPersonalInfo(),
                  _buildGoalsInfo(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Personal',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Umur',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                    suffixText: 'tahun',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Wajib diisi';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return 'Umur tidak valid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kelamin',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Laki-laki')),
                    DropdownMenuItem(value: 'female', child: Text('Perempuan')),
                  ],
                  onChanged: (value) {
                    setState(() => _gender = value!);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Berat Badan',
                    prefixIcon: Icon(Icons.monitor_weight),
                    border: OutlineInputBorder(),
                    suffixText: 'kg',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Wajib diisi';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight < 20 || weight > 300) {
                      return 'Berat tidak valid';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tinggi Badan',
                    prefixIcon: Icon(Icons.height),
                    border: OutlineInputBorder(),
                    suffixText: 'cm',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Wajib diisi';
                    }
                    final height = double.tryParse(value);
                    if (height == null || height < 50 || height > 250) {
                      return 'Tinggi tidak valid';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Target Anda',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _targetWeightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Berat Target',
              prefixIcon: Icon(Icons.flag),
              border: OutlineInputBorder(),
              suffixText: 'kg',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Silakan masukkan berat target';
              }
              final target = double.tryParse(value);
              final current = double.tryParse(_weightController.text);
              if (target == null || target <= 0) {
                return 'Silakan masukkan berat yang valid';
              }
              if (current != null && target >= current) {
                return 'Berat target harus lebih kecil dari berat saat ini';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _activityLevel,
            decoration: const InputDecoration(
              labelText: 'Tingkat Aktivitas',
              prefixIcon: Icon(Icons.directions_run),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: 'sedentary',
                child: Text('Tidak aktif'),
              ),
              DropdownMenuItem(
                value: 'light',
                child: Text('Ringan'),
              ),
              DropdownMenuItem(
                value: 'moderate',
                child: Text('Sedang'),
              ),
              DropdownMenuItem(
                value: 'active',
                child: Text('Aktif'),
              ),
            ],
            onChanged: (value) {
              setState(() => _activityLevel = value!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 1)
            TextButton(
              onPressed: _previousPage,
              child: const Text('Sebelumnya'),
            )
          else
            const SizedBox(width: 80),
          if (_currentPage < 2)
            ElevatedButton(
              onPressed: _nextPage,
              child: const Text('Selanjutnya'),
            )
          else
            ElevatedButton(
              onPressed: _isLoading ? null : _completeProfile,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
        ],
      ),
    );
  }
}