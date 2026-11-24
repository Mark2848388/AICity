import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import 'notification_service.dart';

class TaskService extends ChangeNotifier {
  static const String _boxName = 'tasks';
  late Box<String> _box;

  final List<Task> _tasks = [];
  final int maxConcurrent = 2;

  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get activeTasks =>
      _tasks.where((t) => t.isActive || t.status == TaskStatus.pending).toList();
  List<Task> get finishedTasks => _tasks.where((t) => t.isFinished).toList();

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    _tasks.clear();
    for (final key in _box.keys) {
      try {
        final jsonStr = _box.get(key);
        if (jsonStr != null) {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          _tasks.add(Task.fromJson(map));
        }
      } catch (e) {
        debugPrint('Failed to load task $key: $e');
      }
    }
    // Восстанавливаем running → queued после перезапуска
    for (var i = 0; i < _tasks.length; i++) {
      if (_tasks[i].status == TaskStatus.running) {
        _tasks[i] = _tasks[i].copyWith(status: TaskStatus.queued);
        await _saveTask(_tasks[i]);
      }
    }
    notifyListeners();
  }

  Future<void> _saveTask(Task task) async {
    await _box.put(task.id, jsonEncode(task.toJson()));
  }

  Future<Task> createTask({
    required String title,
    required String description,
    required TaskType type,
    Duration? estimatedDuration,
    Map<String, dynamic>? metadata,
  }) async {
    final task = Task(
      title: title,
      description: description,
      type: type,
      estimatedDuration: estimatedDuration ?? _estimate(type),
      metadata: metadata,
    );
    task.addLog('Task created');
    _tasks.insert(0, task);
    await _saveTask(task);
    notifyListeners();
    return task;
  }

  Duration _estimate(TaskType type) {
    switch (type) {
      case TaskType.buildFlutterZip:
        return const Duration(minutes: 2);
      case TaskType.deployToGithub:
        return const Duration(minutes: 3);
      case TaskType.triggerApkBuild:
        return const Duration(minutes: 8);
      case TaskType.custom:
        return const Duration(minutes: 5);
    }
  }

  Future<void> updateTask(Task updated) async {
    final index = _tasks.indexWhere((t) => t.id == updated.id);
    if (index == -1) return;

    final oldStatus = _tasks[index].status;
    _tasks[index] = updated;
    await _saveTask(updated);
    notifyListeners();

    // Уведомления при завершении
    if (oldStatus != updated.status) {
      if (updated.status == TaskStatus.completed) {
        await NotificationService.instance.showTaskCompleted(updated);
      } else if (updated.status == TaskStatus.failed) {
        await NotificationService.instance.showTaskFailed(updated);
      }
    }
  }

  Future<void> assignAgent(String taskId, String agentId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    await updateTask(task.copyWith(
      assignedAgentId: agentId,
      status: TaskStatus.queued,
    ));
  }

  Future<void> startTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.addLog('Task started');
    await updateTask(task.copyWith(
      status: TaskStatus.running,
      startedAt: DateTime.now(),
      progress: 0.05,
    ));
  }

  Future<void> completeTask(String taskId, {String? result}) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.addLog('Task completed successfully');
    await updateTask(task.copyWith(
      status: TaskStatus.completed,
      finishedAt: DateTime.now(),
      progress: 1.0,
      result: result,
    ));
  }

  Future<void> failTask(String taskId, String error) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.addLog('Task failed: $error');
    await updateTask(task.copyWith(
      status: TaskStatus.failed,
      finishedAt: DateTime.now(),
      error: error,
    ));
  }

  Future<void> addLog(String taskId, String message) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    task.addLog(message);
    await updateTask(task);
  }

  Future<void> updateProgress(String taskId, double progress) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    await updateTask(task.copyWith(progress: progress.clamp(0.0, 1.0)));
  }

  int get runningCount =>
      _tasks.where((t) => t.status == TaskStatus.running).length;

  bool get canStartMore => runningCount < maxConcurrent;

  Task? getTask(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}