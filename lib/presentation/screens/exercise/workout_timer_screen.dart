import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database.dart';
import '../../../data/database/database_providers.dart';

/// 运动计时器页面
class WorkoutTimerScreen extends ConsumerStatefulWidget {
  final TrainingPlan plan;
  final List<TrainingPlanExercise> exercises;
  
  const WorkoutTimerScreen({
    super.key, 
    required this.plan, 
    required this.exercises
  });

  @override
  ConsumerState<WorkoutTimerScreen> createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends ConsumerState<WorkoutTimerScreen> {
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  int _totalSets = 3;
  
  // 计时器状态
  bool _isResting = false;
  bool _isWorking = false;
  int _restSeconds = 60;
  int _remainingRestSeconds = 0;
  int _workSeconds = 0;
  int _remainingWorkSeconds = 0;
  Timer? _timer;
  
  // 训练类型
  bool _isTimedTraining = false;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentExercise();
  }
  
  void _loadCurrentExercise() {
    if (_currentExerciseIndex < widget.exercises.length) {
      final exercise = widget.exercises[_currentExerciseIndex];
      _totalSets = exercise.targetSets;
      _isTimedTraining = exercise.trainingType == 'endurance';
      _restSeconds = exercise.restSeconds ?? 60;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _startRest() {
    setState(() {
      _isResting = true;
      _isWorking = false;
      _remainingRestSeconds = _restSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingRestSeconds--;
        if (_remainingRestSeconds <= 0) {
          _endRest();
        }
      });
    });
  }
  
  void _endRest() {
    _timer?.cancel();
    setState(() {
      _isResting = false;
      _currentSet++;
      if (_currentSet > _totalSets) {
        _nextExercise();
      }
    });
  }
  
  void _startWork() {
    setState(() {
      _isWorking = true;
      _isResting = false;
      _workSeconds = 0;
      if (_isTimedTraining) {
        _remainingWorkSeconds = 10; // 10秒倒计时后开始
      }
    });
    
    if (_isTimedTraining) {
      // 计时训练：10秒倒计时后自动开始
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _remainingWorkSeconds--;
          if (_remainingWorkSeconds <= 0) {
            _remainingWorkSeconds = 0;
            _workSeconds++;
          }
        });
      });
    } else {
      // 力量训练：手动开始
    }
  }
  
  void _stopWork() {
    _timer?.cancel();
    setState(() {
      _isWorking = false;
    });
    // 询问是否开始休息
    _showRestDialog();
  }
  
  void _showRestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('组间休息'),
        content: Text('开始 $_restSeconds 秒休息？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startRest();
            },
            child: const Text('开始休息'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // 跳过休息，继续下一组
              if (_currentSet < _totalSets) {
                _currentSet++;
                setState(() {});
              } else {
                _nextExercise();
              }
            },
            child: const Text('跳过'),
          ),
        ],
      ),
    );
  }
  
  void _nextExercise() {
    setState(() {
      _currentExerciseIndex++;
      _currentSet = 1;
      if (_currentExerciseIndex >= widget.exercises.length) {
        _finishWorkout();
      } else {
        _loadCurrentExercise();
      }
    });
  }
  
  void _finishWorkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('训练完成！'),
        content: const Text('恭喜你完成了本次训练！'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentExerciseIndex >= widget.exercises.length) {
      return Scaffold(
        appBar: AppBar(title: const Text('训练完成')),
        body: const Center(child: Text('训练已完成！')),
      );
    }
    
    final exercise = widget.exercises[_currentExerciseIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(),
        ),
      ),
      body: Column(
        children: [
          // 顶部进度条
          LinearProgressIndicator(
            value: (_currentExerciseIndex + 1) / widget.exercises.length,
          ),
          
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 当前动作
                  Text(
                    exercise.movement,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    exercise.device,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  
                  // 当前组数
                  Text(
                    '第 $_currentSet / $_totalSets 组',
                    style: const TextStyle(fontSize: 24),
                  ),
                  Text(
                    '${exercise.targetReps} 次 × ${exercise.targetWeight ?? 0} kg',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 48),
                  
                  // 计时显示
                  if (_isResting) ...[
                    // 休息倒计时
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        children: [
                          const Text('休息中', style: TextStyle(fontSize: 20, color: Colors.orange)),
                          Text(
                            '$_remainingRestSeconds',
                            style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          const Text('秒', style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        _timer?.cancel();
                        setState(() => _isResting = false);
                      },
                      child: const Text('跳过休息'),
                    ),
                  ] else if (_isWorking) ...[
                    //工作中
                    if (_isTimedTraining && _remainingWorkSeconds > 0) ...[
                      // 计时训练倒计时
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          children: [
                            const Text('即将开始', style: TextStyle(fontSize: 20, color: Colors.blue)),
                            Text(
                              '$_remainingWorkSeconds',
                              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            const Text('秒', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                    ] else ...[
                      // 工作中或计时中
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isTimedTraining ? '计时中' : '工作中',
                              style: const TextStyle(fontSize: 20, color: Colors.green),
                            ),
                            Text(
                              _formatTime(_workSeconds),
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _stopWork,
                        child: const Text('完成这一组'),
                      ),
                    ],
                  ] else ...[
                    // 未开始
                    if (_isTimedTraining)
                      ElevatedButton(
                        onPressed: _startWork,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        ),
                        child: const Text('开始计时', style: TextStyle(fontSize: 20)),
                      )
                    else
                      ElevatedButton(
                        onPressed: _startWork,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        ),
                        child: const Text('开始这一组', style: TextStyle(fontSize: 20)),
                      ),
                  ],
                ],
              ),
            ),
          ),
          
          // 底部动作列表
          Container(
            height: 80,
            color: Colors.grey[200],
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.exercises.length,
              itemBuilder: (context, index) {
                final ex = widget.exercises[index];
                final isCurrent = index == _currentExerciseIndex;
                return Container(
                  width: 100,
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        ex.movement,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCurrent ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${ex.targetSets}×${ex.targetReps}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isCurrent ? Colors.white70 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出训练吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
