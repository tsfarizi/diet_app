import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/daily_reminder_service.dart';
import '../../models/user_model.dart';
import '../../themes/color_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();

  String _gender = 'male';
  String _activityLevel = 'moderate';

  File? _imageFile;
  bool _isEditing = false;
  bool _isLoading = false;
  UserModel? _currentUserProfile;

  bool _smartNotificationsEnabled = false;
  bool _isLoadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadNotificationSettings();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserProfile();
      if (userData != null && mounted) {
        setState(() {
          _currentUserProfile = userData;
          _nameController.text = userData.name;
          _ageController.text = userData.age.toString();
          _heightController.text = userData.height.toString();
          _weightController.text = userData.weight.toString();
          _targetWeightController.text = userData.targetWeight.toString();

          _gender = _validateDropdownValue(userData.gender, [
            'male',
            'female',
          ], 'male');
          _activityLevel = _validateDropdownValue(userData.activityLevel, [
            'sedentary',
            'light',
            'moderate',
            'active',
            'very_active',
          ], 'moderate');
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final reminderService = Provider.of<DailyReminderService>(
        context,
        listen: false,
      );
      final status = await reminderService.getReminderStatus();

      if (mounted) {
        setState(() {
          _smartNotificationsEnabled = status['smartNotifications'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  String _validateDropdownValue(
    String value,
    List<String> validValues,
    String defaultValue,
  ) {
    return validValues.contains(value) ? value : defaultValue;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await _storageService.uploadProfilePicture(
          _authService.currentUser!.uid,
          _imageFile!,
        );
      }

      final currentUser = await _authService.getUserProfile();

      final updatedUser = UserModel(
        id: _authService.currentUser!.uid,
        email: _authService.currentUser!.email!,
        name: _nameController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        height: double.tryParse(_heightController.text) ?? 0,
        weight: double.tryParse(_weightController.text) ?? 0,
        gender: _gender,
        activityLevel: _activityLevel,
        goal: 'lose_weight',
        targetWeight: double.tryParse(_targetWeightController.text) ?? 0,
        dailyCalorieTarget: 2000,
        profileImageUrl: photoUrl ?? currentUser?.profileImageUrl,
        createdAt: currentUser?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _authService.updateUserProfile(updatedUser);

      if (mounted) {
        setState(() {
          _currentUserProfile = updatedUser;
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error memperbarui profil: $e')));
      }
    }
  }

  Future<void> _toggleNotifications(bool enabled) async {
    setState(() => _isLoadingNotifications = true);

    try {
      final reminderService = Provider.of<DailyReminderService>(
        context,
        listen: false,
      );

      if (enabled) {
        await reminderService.updateReminderPreferences(
          smartNotifications: true,
          morningReminder: true,
          lunchReminder: true,
          eveningReminder: true,
          nightCheck: true,
        );

        await reminderService.startBackgroundNotifications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Notifikasi cerdas diaktifkan!'),
              backgroundColor: AppColors.primaryGreen,
            ),
          );
        }
      } else {
        await reminderService.updateReminderPreferences(
          smartNotifications: false,
        );

        await reminderService.stopBackgroundNotifications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Notifikasi cerdas dinonaktifkan.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      setState(() {
        _smartNotificationsEnabled = enabled;
        _isLoadingNotifications = false;
      });
    } catch (e) {
      setState(() => _isLoadingNotifications = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mengubah pengaturan notifikasi: $e')),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    try {
      final reminderService = Provider.of<DailyReminderService>(
        context,
        listen: false,
      );
      await reminderService.testBackgroundNotification();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🧪 Test notification dikirim! Cek notifikasi Anda.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error mengirim test notification: $e')),
        );
      }
    }
  }

  void _showNotificationInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.smart_toy, color: AppColors.primaryGreen, size: 24),
            SizedBox(width: 8),
            Text('Fitur Notifikasi Cerdas'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sistem akan mengirim pengingat otomatis berdasarkan aktivitas Anda:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            _buildFeatureItem('🏃‍♂️', 'Pengingat olahraga saat kurang aktif'),
            _buildFeatureItem('⚠️', 'Peringatan kalori berlebih'),
            _buildFeatureItem('💪', 'Motivasi harian'),
            _buildFeatureItem('📊', 'Analisis progress'),
            _buildFeatureItem('🔄', 'Berjalan otomatis walaupun app ditutup'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notifikasi akan disesuaikan dengan pola aktivitas harian Anda',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tutup'),
          ),
          if (_smartNotificationsEnabled)
            ElevatedButton.icon(
              onPressed: _testNotification,
              icon: Icon(Icons.bug_report, size: 18),
              label: Text('Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  UserModel? _getPreviewUserModel() {
    if (_currentUserProfile == null) return null;

    return _currentUserProfile!.copyWith(
      age: int.tryParse(_ageController.text) ?? _currentUserProfile!.age,
      height:
          double.tryParse(_heightController.text) ??
          _currentUserProfile!.height,
      weight:
          double.tryParse(_weightController.text) ??
          _currentUserProfile!.weight,
      gender: _gender,
      activityLevel: _activityLevel,
      targetWeight:
          double.tryParse(_targetWeightController.text) ??
          _currentUserProfile!.targetWeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewUser = _isEditing
        ? _getPreviewUserModel()
        : _currentUserProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _loadUserData();
                }
              });
            },
            tooltip: _isEditing ? 'Batal' : 'Edit Profil',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Keluar'),
                  content: const Text('Apakah Anda yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await _authService.signOut();
              }
            },
            tooltip: 'Keluar',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : null,
                    child: _imageFile == null
                        ? const Icon(Icons.person, size: 60)
                        : null,
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        radius: 20,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: AppColors.primaryGreen,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Pengaturan Notifikasi',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Icon(
                          Icons.smart_toy,
                          color: _smartNotificationsEnabled
                              ? AppColors.primaryGreen
                              : Colors.grey,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifikasi Cerdas',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Pengingat otomatis berdasarkan aktivitas Anda',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _showNotificationInfoDialog,
                          icon: Icon(
                            Icons.info_outline,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          tooltip: 'Info Detail',
                        ),
                        SizedBox(width: 4),
                        _isLoadingNotifications
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Switch(
                                value: _smartNotificationsEnabled,
                                onChanged: _toggleNotifications,
                                activeColor: AppColors.primaryGreen,
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: TextEditingController(
                        text: _authService.currentUser?.email,
                      ),
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _ageController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Umur',
                              prefixIcon: Icon(Icons.cake),
                            ),
                            onChanged: _isEditing
                                ? (_) => setState(() {})
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 7,
                          child: DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: const InputDecoration(
                              labelText: 'Jenis Kelamin',
                              prefixIcon: Icon(Icons.person),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Laki-laki'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Perempuan'),
                              ),
                            ],
                            onChanged: _isEditing
                                ? (value) {
                                    if (value != null) {
                                      setState(() => _gender = value);
                                    }
                                  }
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _heightController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tinggi (cm)',
                              prefixIcon: Icon(Icons.height),
                            ),
                            onChanged: _isEditing
                                ? (_) => setState(() {})
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Berat (kg)',
                              prefixIcon: Icon(Icons.monitor_weight),
                            ),
                            onChanged: _isEditing
                                ? (_) => setState(() {})
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _targetWeightController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Berat (kg)',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      onChanged: _isEditing ? (_) => setState(() {}) : null,
                    ),
                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _activityLevel,
                          decoration: const InputDecoration(
                            labelText: 'Tingkat Aktivitas',
                            prefixIcon: Icon(Icons.directions_run),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'sedentary',
                              child: Text('Tidak Aktif'),
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
                            DropdownMenuItem(
                              value: 'very_active',
                              child: Text('Sangat Aktif'),
                            ),
                          ],
                          onChanged: _isEditing
                              ? (value) {
                                  if (value != null) {
                                    setState(() => _activityLevel = value);
                                  }
                                }
                              : null,
                        ),

                        if (previewUser != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📋 ${previewUser.activityLevelDescription}',
                                  style: const TextStyle(fontSize: 12),
                                ),

                                if (_isEditing &&
                                    _currentUserProfile != null) ...[
                                  const SizedBox(height: 8),
                                  if (_activityLevel !=
                                      _currentUserProfile!.activityLevel)
                                    _buildActivityImpactPreview(),
                                ],

                                if (previewUser.getActivityLevelWarning() !=
                                    null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            previewUser
                                                .getActivityLevelWarning()!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.orange,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_isEditing) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Simpan Perubahan'),
                ),
              ),
            ],

            if (previewUser != null && previewUser.isDataComplete) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistik Kesehatan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow('BMI', previewUser.bmi.toStringAsFixed(1)),
                      _buildStatRow('Kategori BMI', previewUser.bmiCategory),
                      const Divider(),
                      _buildStatRow(
                        'TDEE (Kebutuhan Harian)',
                        '${previewUser.dailyCalorieNeeds.round()} kcal',
                      ),
                      _buildStatRow(
                        'Target Kalori Diet',
                        '${previewUser.calculatedCalorieTarget.round()} kcal',
                        color: AppColors.caloriesColor,
                      ),
                      _buildStatRow(
                        'Target Protein',
                        '${previewUser.calculatedProteinTarget.round()}g',
                        color: AppColors.proteinColor,
                      ),
                      _buildStatRow(
                        'Target Air',
                        '${previewUser.calculatedWaterTarget.round()}ml',
                        color: AppColors.waterColor,
                      ),
                    ],
                  ),
                ),
              ),

              if (!_isEditing &&
                  previewUser.targetWeight < previewUser.weight) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress & Estimasi',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Berat Target',
                          '${previewUser.targetWeight}kg',
                        ),
                        _buildStatRow(
                          'Perlu Turun',
                          '${(previewUser.weight - previewUser.targetWeight).toStringAsFixed(1)}kg',
                        ),
                        _buildStatRow(
                          'Estimasi Turun/Minggu',
                          '${previewUser.estimatedWeightLossPerWeek.toStringAsFixed(2)}kg',
                        ),
                        _buildStatRow(
                          'Estimasi Waktu ke Target',
                          '${previewUser.estimatedWeeksToTarget} minggu',
                        ),

                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: 0.0,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mulai tracking untuk melihat progress!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityImpactPreview() {
    if (_currentUserProfile == null) return const SizedBox();

    final calorieImpact = _currentUserProfile!.getCalorieImpactIfChange(
      _activityLevel,
    );
    final isIncrease = calorieImpact > 0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isIncrease
            ? Colors.blue.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            isIncrease ? Icons.trending_up : Icons.trending_down,
            color: isIncrease ? Colors.blue : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Target kalori ${isIncrease ? 'naik' : 'turun'} ${calorieImpact.abs().round()} kcal',
            style: TextStyle(
              fontSize: 11,
              color: isIncrease ? Colors.blue : Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }
}
