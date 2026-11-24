import 'package:uuid/uuid.dart';

enum TaskStatus {
  pending,
  queued,
  running,
  completed,
  failed,
  cancelled,
}

enum TaskType {
  buildFlutterZip,
  deployToGithub,
  triggerApkBuild,
  custom,
}

class Task {
  final String id;
  final String title;
  final String description;
  final TaskType type;
  TaskStatus status;
  String? assignedAgentId;
  final DateTime createdAt;
  DateTime? startedAt;
  DateTime? finishedAt;
  double progress; // 0.0 – 1.0
  Duration? estimatedDuration;
  String? result;
  String? error;
  final List<String> logs;
  final Map<String, dynamic> metadata;

  Task({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    this.status = TaskStatus.pending,
    this.assignedAgentId,
    DateTime? createdAt,
    this.startedAt,
    this.finishedAt,
    this.progress = 0.0,
    this.estimatedDuration,
    this.result,
    this.error,
    List<String>? logs,
    Map<String, dynamic>? metadata,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        logs = logs ?? [],
        metadata = metadata ?? {};

  Task copyWith({
    TaskStatus? status,
    String? assignedAgentId,
    DateTime? startedAt,
    DateTime? finishedAt,
    double? progress,
    Duration? estimatedDuration,
    String? result,
    String? error,
    List<String>? logs,
    Map<String, dynamic>? metadata,
  }) {
    return Task(
      id: id,
      title: title,
      description: description,
      type: type,
      status: status ?? this.status,
      assignedAgentId: assignedAgentId ?? this.assignedAgentId,
      createdAt: createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      progress: progress ?? this.progress,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      result: result ?? this.result,
      error: error ?? this.error,
      logs: logs ?? List.from(this.logs),
      metadata: metadata ?? Map.from(this.metadata),
    );
  }

  void addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    logs.add('[$timestamp] $message');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'status': status.name,
        'assignedAgentId': assignedAgentId,
        'createdAt': createdAt.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'finishedAt': finishedAt?.toIso8601String(),
        'progress': progress,
        'estimatedDurationMs': estimatedDuration?.inMilliseconds,
        'result': result,
        'error': error,
        'logs': logs,
        'metadata': metadata,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: TaskType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TaskType.custom,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      assignedAgentId: json['assignedAgentId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.parse(json['finishedAt'] as String)
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      estimatedDuration: json['estimatedDurationMs'] != null
          ? Duration(milliseconds: json['estimatedDurationMs'] as int)
          : null,
      result: json['result'] as String?,
      error: json['error'] as String?,
      logs: List<String>.from(json['logs'] as List? ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  bool get isFinished =>
      status == TaskStatus.completed ||
      status == TaskStatus.failed ||
      status == TaskStatus.cancelled;

  bool get isActive =>
      status == TaskStatus.running || status == TaskStatus.queued;
}