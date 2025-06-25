import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  // REMOVED: Unused _databaseService field
  
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _targetCaloriesController = TextEditingController();
  
  String _gender = 'male';
  String _activityLevel = 'moderate';
  String _goal = 'maintain';
  
  File? _imageFile;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await _authService.getUserProfile();
      if (userData != null && mounted) {
        setState(() {
          _nameController.text = userData.name;
          _ageController.text = userData.age.toString();
          _heightController.text = userData.height.toString();
          _weightController.text = userData.weight.toString();
          _targetWeightController.text = userData.targetWeight.toString();
          _targetCaloriesController.text = userData.dailyCalorieTarget.toString();
          _gender = userData.gender;
          _activityLevel = userData.activityLevel;
          _goal = userData.goal;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
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
        goal: _goal,
        targetWeight: double.tryParse(_targetWeightController.text) ?? 0,
        dailyCalorieTarget: int.tryParse(_targetCaloriesController.text) ?? 2000,
        profileImageUrl: photoUrl ?? currentUser?.profileImageUrl,
        createdAt: currentUser?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _authService.updateUserProfile(updatedUser);
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        // REMOVED: backgroundColor (use theme default)
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _loadUserData(); // Reload data if canceling
                }
              });
            },
            tooltip: _isEditing ? 'Cancel' : 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Show confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await _authService.signOut();
              }
            },
            tooltip: 'Logout',
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
                  children: [
                    TextField(
                      controller: _nameController,
                      enabled: _isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Name',
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
                          child: TextField(
                            controller: _ageController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              prefixIcon: Icon(Icons.cake),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.person),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'male', child: Text('Male')),
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                            ],
                            onChanged: _isEditing ? (value) {
                              setState(() => _gender = value!);
                            } : null,
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
                              labelText: 'Height (cm)',
                              prefixIcon: Icon(Icons.height),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              prefixIcon: Icon(Icons.monitor_weight),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _targetWeightController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Target Weight (kg)',
                              prefixIcon: Icon(Icons.flag),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _targetCaloriesController,
                            enabled: _isEditing,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Daily Calories',
                              prefixIcon: Icon(Icons.local_fire_department),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _activityLevel,
                      decoration: const InputDecoration(
                        labelText: 'Activity Level',
                        prefixIcon: Icon(Icons.directions_run),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
                        DropdownMenuItem(value: 'light', child: Text('Light')),
                        DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'very_active', child: Text('Very Active')),
                      ],
                      onChanged: _isEditing ? (value) {
                        setState(() => _activityLevel = value!);
                      } : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _goal,
                      decoration: const InputDecoration(
                        labelText: 'Goal',
                        prefixIcon: Icon(Icons.track_changes),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'lose_weight', child: Text('Lose Weight')),
                        DropdownMenuItem(value: 'maintain', child: Text('Maintain Weight')),
                        DropdownMenuItem(value: 'gain_weight', child: Text('Gain Weight')),
                      ],
                      onChanged: _isEditing ? (value) {
                        setState(() => _goal = value!);
                      } : null,
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
                      : const Text('Save Changes'),
                ),
              ),
            ],
            if (!_isEditing && double.tryParse(_weightController.text) != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Stats',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildStatRow('BMI', _calculateBMI()),
                      _buildStatRow('BMI Category', _getBMICategory()),
                      _buildStatRow('Daily Calorie Needs', '${_calculateDailyCalories()} kcal'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  String _calculateBMI() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    if (weight != null && height != null && height > 0) {
      final bmi = weight / ((height / 100) * (height / 100));
      return bmi.toStringAsFixed(1);
    }
    return '-';
  }

  String _getBMICategory() {
    final bmiStr = _calculateBMI();
    if (bmiStr == '-') return '-';
    
    final bmi = double.parse(bmiStr);
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  String _calculateDailyCalories() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final age = int.tryParse(_ageController.text);
    
    if (weight != null && height != null && age != null) {
      double bmr;
      if (_gender == 'male') {
        bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
      } else {
        bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
      }
      
      double multiplier;
      switch (_activityLevel) {
        case 'sedentary':
          multiplier = 1.2;
          break;
        case 'light':
          multiplier = 1.375;
          break;
        case 'moderate':
          multiplier = 1.55;
          break;
        case 'active':
          multiplier = 1.725;
          break;
        case 'very_active':
          multiplier = 1.9;
          break;
        default:
          multiplier = 1.2;
      }
      
      return (bmr * multiplier).toStringAsFixed(0);
    }
    return '2000';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _targetWeightController.dispose();
    _targetCaloriesController.dispose();
    super.dispose();
  }
}