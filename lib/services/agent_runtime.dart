import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/agent.dart';
import '../models/task.dart';
import '../scene/city_scene.dart';
import 'task_service.dart';
import '../agents/builder_agent.dart';
import '../agents/deployer_agent.dart';

/// Живой рантайм агентов: движение по городу + автоматический разбор очереди задач.
class AgentRuntime extends ChangeNotifier {
  final TaskService taskService;
  final CitySceneController sceneController;
  final List<Agent> agents;

  Timer? _tickTimer;
  final math.Random _rng = math.Random();

  // Простые «офисы» агентов в городе
  final Map<String, List<math.Point<double>>> _waypoints = {};

  AgentRuntime({
    required this.taskService,
    required this.sceneController,
    required this.agents,
  }) {
    _initWaypoints();
  }

  void _initWaypoints() {
    // Каждому агенту — свой маршрут по городу
    _waypoints['builder-1'] = [
      math.Point(-4, 3),
      math.Point(-8, -2),
      math.Point(-2, -8),
      math.Point(2, -4),
    ];
    _waypoints['deployer-1'] = [
      math.Point(5, -2),
      math.Point(10, 3),
      math.Point(6, 8),
      math.Point(0, 4),
    ];
    _waypoints['researcher-1'] = [
      math.Point(-2, -6),
      math.Point(-12, -4),
      math.Point(-6, 2),
      math.Point(0, -2),
    ];
    _waypoints['helper-1'] = [
      math.Point(3, 6),
      math.Point(-3, 8),
      math.Point(4, 2),
      math.Point(8, 6),
    ];
    _waypoints['tester-1'] = [
      math.Point(-7, 1),
      math.Point(-10, 6),
      math.Point(-4, 5),
      math.Point(-1, 0),
    ];
  }

  void start() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 80), _onTick);
  }

  void stop() {
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void _onTick(Timer timer) {
    // 1. Двигаем агентов
    for (var i = 0; i < agents.length; i++) {
      agents[i] = _moveAgent(agents[i]);
      sceneController.updateAgent(agents[i]);
    }

    // 2. Пробуем взять новую задачу, если есть свободные агенты
    _tryAssignTasks();

    notifyListeners();
  }

  Agent _moveAgent(Agent agent) {
    final points = _waypoints[agent.id];
    if (points == null || points.isEmpty) return agent;

    // Если работает — стоим на месте
    if (agent.state == AgentState.working) {
      return agent;
    }

    // Простое преследование следующей точки
    final target = points[_rng.nextInt(points.length)];
    final dx = target.x - agent.x;
    final dz = target.y - agent.z;
    final dist = math.sqrt(dx * dx + dz * dz);

    if (dist < 0.4) {
      // Дошли — иногда меняем состояние на idle
      return agent.copyWith(
        state: AgentState.idle,
        x: target.x,
        z: target.y,
      );
    }

    const speed = 0.08;
    final nx = agent.x + (dx / dist) * speed;
    final nz = agent.z + (dz / dist) * speed;

    return agent.copyWith(
      state: AgentState.walking,
      x: nx,
      z: nz,
    );
  }

  Future<void> _tryAssignTasks() async {
    if (!taskService.canStartMore) return;

    final pending = taskService.tasks
        .where((t) => t.status == TaskStatus.pending || t.status == TaskStatus.queued)
        .toList();
    if (pending.isEmpty) return;

    final freeAgents = agents.where((a) => a.state == AgentState.idle || a.state == AgentState.walking).toList();
    if (freeAgents.isEmpty) return;

    for (final task in pending) {
      if (!taskService.canStartMore) break;

      Agent? suitable;
      if (task.type == TaskType.buildFlutterZip) {
        suitable = freeAgents.cast<Agent?>().firstWhere(
              (a) => a?.role == AgentRole.builder,
              orElse: () => freeAgents.isNotEmpty ? freeAgents.first : null,
            );
      } else if (task.type == TaskType.deployToGithub || task.type == TaskType.triggerApkBuild) {
        suitable = freeAgents.cast<Agent?>().firstWhere(
              (a) => a?.role == AgentRole.deployer,
              orElse: () => freeAgents.isNotEmpty ? freeAgents.first : null,
            );
      } else {
        suitable = freeAgents.isNotEmpty ? freeAgents.first : null;
      }

      if (suitable == null) continue;

      // Назначаем
      await taskService.assignAgent(task.id, suitable.id);
      final idx = agents.indexWhere((a) => a.id == suitable!.id);
      if (idx != -1) {
        agents[idx] = agents[idx].copyWith(
          state: AgentState.working,
          currentTaskId: task.id,
        );
      }

      // Запускаем в фоне
      unawaited(_runTask(suitable, task));
      freeAgents.remove(suitable);
    }
  }

  Future<void> _runTask(Agent agent, Task task) async {
    try {
      if (task.type == TaskType.buildFlutterZip) {
        final builder = BuilderAgent(taskService: taskService, agentId: agent.id);
        await builder.execute(task);
      } else if (task.type == TaskType.deployToGithub || task.type == TaskType.triggerApkBuild) {
        final deployer = DeployerAgent(taskService: taskService, agentId: agent.id);
        await deployer.execute(task);
      } else {
        // Заглушка для остальных
        await taskService.startTask(task.id);
        await Future.delayed(const Duration(seconds: 3));
        await taskService.completeTask(task.id, result: 'Готово (generic)');
      }
    } finally {
      final idx = agents.indexWhere((a) => a.id == agent.id);
      if (idx != -1) {
        agents[idx] = agents[idx].copyWith(
          state: AgentState.idle,
          currentTaskId: null,
        );
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
