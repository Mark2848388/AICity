import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/task_service.dart';

class TaskPanel extends StatelessWidget {
  const TaskPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskService>(
      builder: (context, service, _) {
        final tasks = service.tasks;
        return Card(
          color: Colors.black.withOpacity(0.75),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'Задачи',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text(
                      '${service.runningCount} активных',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: tasks.isEmpty
                    ? const Center(
                        child: Text(
                          'Пока нет задач.\nНажми «Новая задача»',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return _TaskTile(task: tasks[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  final Task task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: _StatusIcon(status: task.status),
      title: Text(
        task.title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: task.progress,
            backgroundColor: Colors.white12,
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 4),
          Text(
            _statusText(task),
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.55)),
          ),
        ],
      ),
      children: [
        if (task.logs.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: task.logs
                  .take(12)
                  .map((l) => Text(
                        l,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.white70,
                        ),
                      ))
                  .toList(),
            ),
          ),
        if (task.result != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Результат: ${task.result}',
              style: const TextStyle(fontSize: 12, color: Colors.greenAccent),
            ),
          ),
        if (task.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              'Ошибка: ${task.error}',
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ),
      ],
    );
  }

  String _statusText(Task task) {
    final time = DateFormat.Hm().format(task.createdAt);
    switch (task.status) {
      case TaskStatus.pending:
        return 'Ожидает • $time';
      case TaskStatus.queued:
        return 'В очереди • $time';
      case TaskStatus.running:
        return 'Выполняется ${(task.progress * 100).toInt()}%';
      case TaskStatus.completed:
        return 'Готово • $time';
      case TaskStatus.failed:
        return 'Ошибка • $time';
      case TaskStatus.cancelled:
        return 'Отменено';
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final TaskStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (status) {
      case TaskStatus.pending:
      case TaskStatus.queued:
        icon = Icons.schedule;
        color = Colors.blueGrey;
        break;
      case TaskStatus.running:
        icon = Icons.autorenew;
        color = Colors.orangeAccent;
        break;
      case TaskStatus.completed:
        icon = Icons.check_circle;
        color = Colors.greenAccent;
        break;
      case TaskStatus.failed:
        icon = Icons.error;
        color = Colors.redAccent;
        break;
      case TaskStatus.cancelled:
        icon = Icons.cancel;
        color = Colors.grey;
        break;
    }
    return Icon(icon, color: color, size: 22);
  }
}