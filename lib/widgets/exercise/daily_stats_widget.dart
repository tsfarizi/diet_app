import 'package:flutter/material.dart';

class DailyStatsWidget extends StatefulWidget {
  final int currentSteps;
  final double currentCalories;
  final int currentWorkouts;
  final int currentMinutes;
  final int targetSteps;
  final double targetCalories;
  final int targetWorkouts;
  final int targetMinutes;

  const DailyStatsWidget({
    super.key,
    this.currentSteps = 0,
    this.currentCalories = 0.0,
    this.currentWorkouts = 0,
    this.currentMinutes = 0,
    this.targetSteps = 5000,
    this.targetCalories = 300.0,
    this.targetWorkouts = 3,
    this.targetMinutes = 60,
  });

  @override
  State<DailyStatsWidget> createState() => _DailyStatsWidgetState();
}

class _DailyStatsWidgetState extends State<DailyStatsWidget> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startProgressAnimation();
  }

  void _initializeAnimations() {
    _progressController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
  }

  void _startProgressAnimation() {
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        _progressController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(DailyStatsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSteps != widget.currentSteps ||
        oldWidget.currentCalories != widget.currentCalories ||
        oldWidget.currentWorkouts != widget.currentWorkouts ||
        oldWidget.currentMinutes != widget.currentMinutes) {
      _progressController.reset();
      _startProgressAnimation();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
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
          _buildHeader(),
          SizedBox(height: 16),
          _buildStatsGrid(),
          if (_hasAnyProgress()) ...[
            SizedBox(height: 16),
            _buildProgressSummary(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.today,
            color: Colors.blue,
            size: 24,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aktivitas Hari Ini',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getFormattedDate(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (_hasAnyProgress()) _buildOverallProgressBadge(),
      ],
    );
  }

  Widget _buildOverallProgressBadge() {
    final overallProgress = _calculateOverallProgress();
    final color = _getProgressColor(overallProgress);
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        '${(overallProgress * 100).toInt()}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.directions_walk,
                label: 'Langkah',
                current: widget.currentSteps,
                target: widget.targetSteps,
                unit: '',
                color: Colors.blue,
                formatNumber: true,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department,
                label: 'Kalori',
                current: widget.currentCalories.toInt(),
                target: widget.targetCalories.toInt(),
                unit: 'kal',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.fitness_center,
                label: 'Workout',
                current: widget.currentWorkouts,
                target: widget.targetWorkouts,
                unit: 'sesi',
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer,
                label: 'Menit',
                current: widget.currentMinutes,
                target: widget.targetMinutes,
                unit: 'min',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int current,
    required int target,
    required String unit,
    required Color color,
    bool formatNumber = false,
  }) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isCompleted = current >= target;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? color : color.withValues(alpha: 0.3),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              if (isCompleted)
                Icon(Icons.check_circle, color: color, size: 16),
            ],
          ),
          SizedBox(height: 8),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return _buildProgressIndicator(
                progress * _progressAnimation.value,
                color,
              );
            },
          ),
          SizedBox(height: 8),
          Text(
            formatNumber ? _formatNumber(current) : current.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (target > 0) ...[
            SizedBox(height: 4),
            Text(
              'Target: ${formatNumber ? _formatNumber(target) : target} $unit',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(double progress, Color color) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 4,
            color: color.withValues(alpha: 0.2),
            backgroundColor: Colors.transparent,
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 4,
            color: color,
            backgroundColor: Colors.transparent,
          ),
          Center(
            child: Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary() {
    final overallProgress = _calculateOverallProgress();
    final completedGoals = _getCompletedGoalsCount();
    final totalGoals = 4;
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up, color: Colors.blue, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Harian',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  '$completedGoals dari $totalGoals target tercapai',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getProgressColor(overallProgress).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(overallProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getProgressColor(overallProgress),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    final months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                   'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    
    return '${weekdays[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  bool _hasAnyProgress() {
    return widget.currentSteps > 0 ||
           widget.currentCalories > 0 ||
           widget.currentWorkouts > 0 ||
           widget.currentMinutes > 0;
  }

  double _calculateOverallProgress() {
    final stepsProgress = widget.targetSteps > 0 ? (widget.currentSteps / widget.targetSteps).clamp(0.0, 1.0) : 0.0;
    final caloriesProgress = widget.targetCalories > 0 ? (widget.currentCalories / widget.targetCalories).clamp(0.0, 1.0) : 0.0;
    final workoutsProgress = widget.targetWorkouts > 0 ? (widget.currentWorkouts / widget.targetWorkouts).clamp(0.0, 1.0) : 0.0;
    final minutesProgress = widget.targetMinutes > 0 ? (widget.currentMinutes / widget.targetMinutes).clamp(0.0, 1.0) : 0.0;
    
    return (stepsProgress + caloriesProgress + workoutsProgress + minutesProgress) / 4;
  }

  int _getCompletedGoalsCount() {
    int completed = 0;
    if (widget.currentSteps >= widget.targetSteps) completed++;
    if (widget.currentCalories >= widget.targetCalories) completed++;
    if (widget.currentWorkouts >= widget.targetWorkouts) completed++;
    if (widget.currentMinutes >= widget.targetMinutes) completed++;
    return completed;
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) {
      return Colors.green;
    } else if (progress >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}