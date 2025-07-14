import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/walking_session_model.dart';
import '../../services/step_counter_service.dart';
import '../../services/walking_tracker_service.dart';
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

class _WalkingTrackerWidgetState extends State<WalkingTrackerWidget>
    with TickerProviderStateMixin {
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
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _stepController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOutCubic),
    );
    _stepAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _stepController, curve: Curves.elasticOut),
    );
  }

  void _checkCurrentSession() {
    final current = _trackerService.currentSession;
    if (current != null) {
      setState(() => _currentSession = current);
      _listenToSession();
      if (current.isActive) {
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
        if (mounted) setState(() => _errorMessage = error.toString());
      },
    );
  }

  void _listenToStepCounter() {
    _stepSubscription?.cancel();
    _statusSubscription?.cancel();
    _stepSubscription = _stepService.stepStream?.listen((steps) {
      if (mounted && steps != _currentSteps) {
        setState(() => _currentSteps = steps);
        _triggerStepAnimation();
      }
    });
    _statusSubscription = _stepService.statusStream?.listen((status) {
      if (mounted) setState(() => _pedestrianStatus = status);
    });
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
      final ok = await _trackerService.startWalkingSession(
        userWeight: widget.userWeight,
        userAge: widget.userAge,
        userHeight: widget.userHeight,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (ok) {
          _listenToSession();
          _pulseController.repeat(reverse: true);
          _statsController.forward();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
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
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          _showErrorDialog(
            'Gagal memulai tracking',
            'Pastikan GPS aktif dan permission sudah diberikan.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Error', e.toString());
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
              children: const [
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
      if (mounted) _showErrorDialog('Error', 'Gagal pause tracking: $e');
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
              children: const [
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
      if (mounted) _showErrorDialog('Error', 'Gagal resume tracking: $e');
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
      if (mounted) _showErrorDialog('Error', 'Gagal stop tracking: $e');
    }
  }

  void _showSessionSummary(WalkingSession session) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: const [
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      Icons.directions_walk,
                      'Langkah',
                      '${session.steps}',
                    ),
                    _buildSummaryRow(
                      Icons.straighten,
                      'Jarak',
                      session.formattedDistance,
                    ),
                    _buildSummaryRow(
                      Icons.timer,
                      'Waktu',
                      session.formattedDuration,
                    ),
                    _buildSummaryRow(
                      Icons.local_fire_department,
                      'Kalori',
                      session.formattedCalories,
                    ),
                    _buildSummaryRow(
                      Icons.speed,
                      'Pace Rata-rata',
                      _calculatePace(session.averageSpeed),
                    ),
                    _buildSummaryRow(
                      Icons.trending_up,
                      'Kecepatan Max',
                      '${session.maxSpeed.toStringAsFixed(1)} km/h',
                    ),
                  ],
                ),
              ),
              if (session.route.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.map, color: Colors.blue),
                        const SizedBox(height: 4),
                        const Text(
                          'Rute berhasil direkam',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${session.route.length} titik GPS',
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
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _calculatePace(double speedKmh) {
    if (speedKmh <= 0) return '0:00 min/km';
    double pace = 60.0 / speedKmh;
    int m = pace.floor();
    int s = ((pace - m) * 60).round();
    return '$m:${s.toString().padLeft(2, '0')} min/km';
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0)
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${meters.toStringAsFixed(0)} m';
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

  Widget _buildHistorySection() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('walking_sessions')
          .orderBy('startTime', descending: true)
          .snapshots(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Belum ada riwayat',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
            final ts = data['startTime'];
            DateTime? start;
            if (ts is Timestamp) start = ts.toDate();
            if (ts is String) start = DateTime.tryParse(ts);
            final dateText = start != null
                ? '${start.day}/${start.month}/${start.year} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}'
                : '';
            final distance = (data['distance'] ?? 0).toDouble();
            final duration = data['duration'] ?? 0;
            final calories = (data['calories'] ?? 0).toDouble();
            final steps = data['steps'] ?? 0;
            final distanceText = distance >= 1000
                ? '${(distance / 1000).toStringAsFixed(2)} km'
                : '${distance.toStringAsFixed(0)} m';
            return ListTile(
              leading: const Icon(Icons.route, color: Colors.blue),
              title: Text('$distanceText • $steps langkah'),
              subtitle: Text(
                'Kalori: ${calories.toStringAsFixed(0)} • Durasi: ${_formatDuration(duration)}',
              ),
              trailing: Text(dateText, style: const TextStyle(fontSize: 12)),
            );
          },
        );
      },
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallText ? 12 : 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle,
                style: const TextStyle(fontSize: 8, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveStatsSection() {
    if (_currentSession == null) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatDuration(_currentSession!.duration),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Text(
                      'Waktu',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.blue.withOpacity(.3),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatDistance(_currentSession!.distance),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      'Jarak',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AnimatedBuilder(
                animation: _stepAnimation,
                builder: (_, child) =>
                    Transform.scale(scale: _stepAnimation.value, child: child),
                child: _buildLiveStatCard(
                  icon: Icons.directions_walk,
                  label: 'Langkah',
                  value: '$_currentSteps',
                  color: Colors.purple,
                  subtitle: _getStatusText(),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
        const SizedBox(height: 8),
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
            const SizedBox(width: 8),
            Expanded(
              child: _buildLiveStatCard(
                icon: Icons.trending_up,
                label: 'Kecepatan',
                value:
                    '${_currentSession!.averageSpeed.toStringAsFixed(1)} km/h',
                color: Colors.orange,
                isSmallText: true,
              ),
            ),
          ],
        ),
        if (_currentSession!.route.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gps_fixed, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'GPS: ${_currentSession!.route.length} titik',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.sensors, color: Colors.purple, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Sensor: Aktif',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControlButtons() {
    if (_currentSession == null) return const SizedBox.shrink();
    return Row(
      children: [
        if (_currentSession!.isActive)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _pauseWalking,
              icon: const Icon(Icons.pause),
              label: const Text('Pause'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _resumeWalking,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _stopWalking,
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
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
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _startWalking,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.play_arrow, size: 28),
        label: Text(
          _isLoading ? 'Memulai...' : 'Mulai Jalan',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.directions_walk,
                  color: _currentSession?.isActive == true
                      ? Colors.green
                      : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Walking Tracker',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_currentSession?.isActive == true)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.radio_button_checked,
                          color: Colors.white,
                          size: 12,
                        ),
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
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_currentSession != null)
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: GPSMapWidget(
                session: _currentSession,
                isTracking: _currentSession!.isActive,
                height: 250,
                showUserLocation: true,
                autoFollow: true,
              ),
            )
          else
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(.3)),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          if (_currentSession != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FadeTransition(
                opacity: _statsAnimation,
                child: _buildLiveStatsSection(),
              ),
            ),
          if (_currentSession != null) const SizedBox(height: 16),
          if (_currentSession != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildControlButtons(),
            ),
          if (_currentSession == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildStartButton(),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Riwayat Jalan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          _buildHistorySection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
