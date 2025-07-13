import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _authService = AuthService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  
  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _weightLossRate = 'moderate';
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  int _currentPage = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Silakan masukkan password';
    }
    if (value.length < 8) {
      return 'Password minimal 8 karakter';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password harus mengandung huruf besar';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password harus mengandung huruf kecil';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password harus mengandung angka';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Silakan konfirmasi password';
    }
    if (value != _passwordController.text) {
      return 'Password tidak sama';
    }
    return null;
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          age: int.parse(_ageController.text),
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
          gender: _gender,
          activityLevel: _activityLevel,
          targetWeight: double.parse(_targetWeightController.text),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Akun berhasil dibuat!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
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

  Future<void> _signUpWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    
    try {
      await _authService.signUpWithGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil masuk dengan Google!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (!_validateFirstPage()) return;
    }
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateFirstPage() {
    if (_nameController.text.trim().isEmpty) {
      _showError('Nama tidak boleh kosong');
      return false;
    }
    if (_emailController.text.trim().isEmpty || !_emailController.text.contains('@')) {
      _showError('Email tidak valid');
      return false;
    }
    if (_validatePassword(_passwordController.text) != null) {
      _showError(_validatePassword(_passwordController.text)!);
      return false;
    }
    if (_validateConfirmPassword(_confirmPasswordController.text) != null) {
      _showError(_validateConfirmPassword(_confirmPasswordController.text)!);
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _calculateTimelineText() {
    try {
      final current = double.parse(_weightController.text);
      final target = double.parse(_targetWeightController.text);
      final difference = current - target;
      
      double weeklyLoss = 0.5;
      if (_weightLossRate == 'slow') weeklyLoss = 0.25;
      if (_weightLossRate == 'fast') weeklyLoss = 0.75;
      
      final weeks = (difference / weeklyLoss).ceil();
      final months = (weeks / 4.3).round();
      
      if (months > 0) {
        return 'Anda akan mencapai target dalam sekitar $months bulan ($weeks minggu)';
      } else {
        return 'Anda akan mencapai target dalam sekitar $weeks minggu';
      }
    } catch (e) {
      return 'Masukkan berat target untuk melihat estimasi';
    }
  }

  Widget _buildPasswordStrengthIndicator() {
    String password = _passwordController.text;
    int strength = 0;
    
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    Color strengthColor = Colors.red;
    String strengthText = 'Lemah';
    
    if (strength >= 4) {
      strengthColor = Colors.green;
      strengthText = 'Kuat';
    } else if (strength >= 3) {
      strengthColor = Colors.orange;
      strengthText = 'Sedang';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Kekuatan Password: ',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              strengthText,
              style: TextStyle(
                fontSize: 12,
                color: strengthColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: strength / 4,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Akun'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentPage + 1) / 3,
              backgroundColor: Colors.grey[300],
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildAccountInfo(),
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

  Widget _buildAccountInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Akun',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Buat akun baru atau gunakan Google',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isGoogleLoading ? null : _signUpWithGoogle,
              icon: _isGoogleLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Image.asset(
                      'assets/icons/google_logo.png',
                      height: 20,
                      width: 20,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.login, color: Colors.red);
                      },
                    ),
              label: Text('Daftar dengan Google'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'ATAU',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Silakan masukkan nama Anda';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Silakan masukkan email Anda';
              }
              if (!value.contains('@')) {
                return 'Silakan masukkan email yang valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(),
              helperText: 'Min 8 karakter, huruf besar, kecil, dan angka',
            ),
            validator: _validatePassword,
          ),
          if (_passwordController.text.isNotEmpty) _buildPasswordStrengthIndicator(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Konfirmasi Password',
              prefixIcon: Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              border: OutlineInputBorder(),
            ),
            validator: _validateConfirmPassword,
          ),
        ],
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
          const SizedBox(height: 8),
          Text(
            'Tetapkan berat target dan timeline',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Berat Saat Ini',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_weightController.text} kg',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.trending_down,
                  color: Colors.blue.shade700,
                  size: 32,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _targetWeightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Berat Target',
              prefixIcon: Icon(Icons.flag),
              border: OutlineInputBorder(),
              helperText: 'Berat yang ingin Anda capai',
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
            value: _weightLossRate,
            decoration: const InputDecoration(
              labelText: 'Kecepatan Penurunan Berat',
              prefixIcon: Icon(Icons.speed),
              border: OutlineInputBorder(),
              helperText: 'Seberapa cepat Anda ingin menurunkan berat?',
            ),
            items: const [
              DropdownMenuItem(
                value: 'slow',
                child: Text('Lambat (0.25 kg/minggu) - Mudah'),
              ),
              DropdownMenuItem(
                value: 'moderate',
                child: Text('Sedang (0.5 kg/minggu) - Direkomendasikan'),
              ),
              DropdownMenuItem(
                value: 'fast',
                child: Text('Cepat (0.75 kg/minggu) - Menantang'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _weightLossRate = value!;
                _calculateTimelineText();
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _activityLevel,
            decoration: const InputDecoration(
              labelText: 'Tingkat Aktivitas',
              prefixIcon: Icon(Icons.directions_run),
              border: OutlineInputBorder(),
              helperText: 'Seberapa aktif Anda?',
            ),
            items: const [
              DropdownMenuItem(
                value: 'sedentary',
                child: Text('Tidak aktif (jarang olahraga)'),
              ),
              DropdownMenuItem(
                value: 'light',
                child: Text('Ringan (olahraga 1-3 hari/minggu)'),
              ),
              DropdownMenuItem(
                value: 'moderate',
                child: Text('Sedang (olahraga 3-5 hari/minggu)'),
              ),
              DropdownMenuItem(
                value: 'active',
                child: Text('Aktif (olahraga 6-7 hari/minggu)'),
              ),
            ],
            onChanged: (value) {
              setState(() => _activityLevel = value!);
            },
          ),
          
          const SizedBox(height: 24),
          
          if (_targetWeightController.text.isNotEmpty && _weightController.text.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Estimasi Timeline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _calculateTimelineText(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
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
          if (_currentPage > 0)
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
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Daftar'),
            ),
        ],
      ),
    );
  }
}