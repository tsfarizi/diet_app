import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/walking_session_model.dart';
import '../../services/walking_tracker_service.dart';
import '../../services/step_counter_service.dart';
import 'gps_map_widget.dart';

class WalkingTrackerWidget extends StatefulWidget {
  final double userWeight;
  final int userAge;
  final double userHeight;
  final Function(WalkingSession)? onSessionComplete;
  final bool autoStart;

  const WalkingTrackerWidget({
    super.key,
    required this.userWeight,
    required this.userAge,
    required this.userHeight,
    this.onSessionComplete,
    this.autoStart = false,
  });

  @override
  State<WalkingTrackerWidget> createState() => _WalkingTrackerWidgetState();
}

class _WalkingTrackerWidgetState extends State<WalkingTrackerWidget> with TickerProviderStateMixin {
  final WalkingTrackerService _trackerService = WalkingTrackerService();
  final StepCounterService _stepService = StepCounterService();
  
  StreamSubscription<WalkingSession>? _sessionSubscription;
  StreamSubscription<int>? _stepSubscription;
  StreamSubscription<String>? _statusSubscription;
  
  WalkingSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentSteps = 0;
  String _pedestrianStatus = 'stopped';
  
  late AnimationController _pulseController;
  late AnimationController _statsController;
  late AnimationController _stepController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _stepAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkCurrentSession();
    _listenToStepCounter();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startWalking();
      });
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _stepController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutCubic,
    ));

    _stepAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _stepController,
      curve: Curves.elasticOut,
    ));
  }

  void _checkCurrentSession() {
    final currentSession = _trackerService.currentSession;
    if (currentSession != null) {
      setState(() {
        _currentSession = currentSession;
      });
      _listenToSession();
      if (currentSession.isActive) {
        _pulseController.repeat(reverse: true);
        _statsController.forward();
      }
    }
  }

  void _listenToSession() {
    _sessionSubscription?.cancel();
    _sessionSubscription = _trackerService.sessionStream?.listen(
      (session) {
        if (mounted) {
          setState(() {
            _currentSession = session;
            _errorMessage = null;
          });
          
          if (session.steps != _currentSteps) {
            _currentSteps = session.steps;
            _triggerStepAnimation();
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error.toString();
          });
        }
      },
    );
  }

  void _listenToStepCounter() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    
    _stepSubscription = _stepService.stepStream?.listen(
      (steps) {
        if (mounted && steps != _currentSteps) {
          setState(() {
            _currentSteps = steps;
          });
          _triggerStepAnimation();
        }
      },
      onError: (error) {
        print('Step counter error: $error');
      },
    );
    
    _statusSubscription = _stepService.statusStream?.listen(
      (status) {
        if (mounted) {
          setState(() {
            _pedestrianStatus = status;
          });
        }
      },
      onError: (error) {
        print('Status error: $error');
      },
    );
  }

  void _triggerStepAnimation() {
    _stepController.reset();
    _stepController.forward();
  }

  Future<void> _startWalking() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _trackerService.startWalkingSession(
        userWeight: widget.userWeight,
        userAge: widget.userAge,
        userHeight: widget.userHeight,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          _listenToSession();
          _pulseController.repeat(reverse: true);
          _statsController.forward();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Tracking dimulai!'),
                        Text(
                          'GPS mencari lokasi & sensor mengukur langkah...',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          _showErrorDialog('Gagal memulai tracking', 
            'Pastikan GPS aktif dan permission sudah diberikan.\n\nCoba:\n1. Aktifkan GPS\n2. Restart aplikasi\n3. Berikan permission lokasi & sensor');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        _showErrorDialog('Error', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showPermissionDialog();
            },
            child: Text('Cek Permission'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Informasi Permission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Permission yang dibutuhkan:'),
            SizedBox(height: 8),
            _buildPermissionItem(Icons.location_on, 'Lokasi', 'Untuk tracking GPS'),
            _buildPermissionItem(Icons.sensors, 'Sensor', 'Untuk menghitung langkah'),
            _buildPermissionItem(Icons.fitness_center, 'Aktivitas', 'Untuk deteksi gerakan'),
            SizedBox(height: 12),
            Text(
              'Jika permission ditolak, buka Settings > Apps > Diet App > Permissions',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pauseWalking() async {
    try {
      final session = await _trackerService.pauseSession();
      if (session != null && mounted) {
        _pulseController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.pause, color: Colors.white),
                SizedBox(width: 8),
                Text('Tracking dijeda'),
              ],
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Gagal pause tracking: $e');
      }
    }
  }

  Future<void> _resumeWalking() async {
    try {
      final session = await _trackerService.resumeSession();
      if (session != null && mounted) {
        _pulseController.repeat(reverse: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.white),
                SizedBox(width: 8),
                Text('Tracking dilanjutkan'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Gagal resume tracking: $e');
      }
    }
  }

  Future<void> _stopWalking() async {
    try {
      final session = await _trackerService.stopSession();
      
      if (mounted) {
        _pulseController.stop();
        _pulseController.reset();
        _statsController.reverse();
        
        if (session != null) {
          widget.onSessionComplete?.call(session);
          setState(() {
            _currentSession = null;
            _currentSteps = 0;
            _pedestrianStatus = 'stopped';
          });
          
          _showSessionSummary(session);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error', 'Gagal stop tracking: $e');
      }
    }
  }

  void _showSessionSummary(WalkingSession session) {
    final pace = _calculatePace(session.averageSpeed);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Sesi Selesai'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(Icons.directions_walk, 'Langkah', '${session.steps}'),
                    _buildSummaryRow(Icons.straighten, 'Jarak', session.formattedDistance),
                    _buildSummaryRow(Icons.timer, 'Waktu', session.formattedDuration),
                    _buildSummaryRow(Icons.local_fire_department, 'Kalori', session.formattedCalories),
                    _buildSummaryRow(Icons.speed, 'Pace Rata-rata', pace),
                    _buildSummaryRow(Icons.trending_up, 'Kecepatan Max', '${session.maxSpeed.toStringAsFixed(1)} km/h'),
                  ],
                ),
              ),
              if (session.route.isNotEmpty) ...[
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.map, color: Colors.blue),
                      SizedBox(height: 4),
                      Text(
                        'Rute berhasil direkam',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${session.route.length} titik GPS',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Selesai'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _calculatePace(double speedKmh) {
    if (speedKmh <= 0) return '0:00 min/km';
    double paceMinutesPerKm = 60.0 / speedKmh;
    int minutes = paceMinutesPerKm.floor();
    int seconds = ((paceMinutesPerKm - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')} min/km';
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    } else {
      return '${meters.toStringAsFixed(0)} m';
    }
  }

  String _getStatusText() {
    switch (_pedestrianStatus.toLowerCase()) {
      case 'running':
        return 'Sedang Berlari 🏃‍♂️';
      case 'walking':
        return 'Sedang Berjalan 🚶‍♂️';
      case 'moving':
        return 'Bergerak 🧍';
      case 'stopped':
        return 'Berhenti 🛑';
      default:
        return 'Mendeteksi... ❓';
    }
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    _pulseController.dispose();
    _statsController.dispose();
    _stepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.directions_walk,
                  color: _currentSession?.isActive == true ? Colors.green : Colors.grey,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Walking Tracker',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                if (_currentSession?.isActive == true)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.radio_button_checked, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          if (_errorMessage != null) ...[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
          
          if (_currentSession != null) ...[
            Container(
              height: 250,
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: GPSMapWidget(
                session: _currentSession,
                isTracking: _currentSession!.isActive,
                height: 250,
                showUserLocation: true,
                autoFollow: true,
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: FadeTransition(
                opacity: _statsAnimation,
                child: _buildLiveStatsSection(),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _buildControlButtons(),
            ),
            SizedBox(height: 16),
          ] else ...[
            Container(
              height: 250,
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mulai tracking untuk melihat peta',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _buildStartButton(),
            ),
            SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveStatsSection() {
    if (_currentSession == null) return SizedBox();
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatDuration(_currentSession!.duration),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      'Waktu',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.blue.withValues(alpha: 0.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatDistance(_currentSession!.distance),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Jarak',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _stepAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _stepAnimation.value,
                    child: _buildLiveStatCard(
                      icon: Icons.directions_walk,
                      label: 'Langkah',
                      value: '$_currentSteps',
                      color: Colors.purple,
                      subtitle: _getStatusText(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildLiveStatCard(
                icon: Icons.local_fire_department,
                label: 'Kalori',
                value: '${_currentSession!.calories.toInt()}',
                color: Colors.red,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildLiveStatCard(
                icon: Icons.speed,
                label: 'Pace',
                value: _calculatePace(_currentSession!.averageSpeed),
                color: Colors.green,
                isSmallText: true,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildLiveStatCard(
                icon: Icons.trending_up,
                label: 'Kecepatan',
                value: '${_currentSession!.averageSpeed.toStringAsFixed(1)} km/h',
                color: Colors.orange,
                isSmallText: true,
              ),
            ),
          ],
        ),
        if (_currentSession!.route.isNotEmpty) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gps_fixed, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text(
                  'GPS: ${_currentSession!.route.length} titik',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.sensors, color: Colors.purple, size: 16),
                SizedBox(width: 4),
                Text(
                  'Sensor: Aktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLiveStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isSmallText = false,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallText ? 12 : 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    if (_currentSession == null) return SizedBox();

    return Row(
      children: [
        if (_currentSession!.isActive) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _pauseWalking,
              icon: Icon(Icons.pause),
              label: Text('Pause'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _resumeWalking,
              icon: Icon(Icons.play_arrow),
              label: Text('Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
        SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _stopWalking,
            icon: Icon(Icons.stop),
            label: Text('Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _startWalking,
              icon: _isLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.play_arrow, size: 28),
              label: Text(
                _isLoading ? 'Memulai...' : 'Mulai Jalan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
              ),
            ),
          );
        },
      ),
    );
  }
}