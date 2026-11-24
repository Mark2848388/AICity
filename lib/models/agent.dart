enum AgentRole {
  builder,
  deployer,
  general,
}

enum AgentState {
  idle,
  walking,
  working,
  waiting,
  error,
}

class Agent {
  final String id;
  final String name;
  final AgentRole role;
  AgentState state;
  String? currentTaskId;
  // Позиция в 3D-мире (простая)
  double x;
  double y;
  double z;
  // Целевая позиция для движения
  double? targetX;
  double? targetZ;
  final List<String> capabilities;

  Agent({
    required this.id,
    required this.name,
    required this.role,
    this.state = AgentState.idle,
    this.currentTaskId,
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.targetX,
    this.targetZ,
    List<String>? capabilities,
  }) : capabilities = capabilities ?? _defaultCapabilities(role);

  static List<String> _defaultCapabilities(AgentRole role) {
    switch (role) {
      case AgentRole.builder:
        return [
          'create_flutter_project',
          'build_zip',
          'write_file',
        ];
      case AgentRole.deployer:
        return [
          'upload_to_github',
          'trigger_github_actions',
          'get_workflow_status',
        ];
      case AgentRole.general:
        return ['chat', 'plan'];
    }
  }

  Agent copyWith({
    AgentState? state,
    String? currentTaskId,
    double? x,
    double? y,
    double? z,
    double? targetX,
    double? targetZ,
  }) {
    return Agent(
      id: id,
      name: name,
      role: role,
      state: state ?? this.state,
      currentTaskId: currentTaskId ?? this.currentTaskId,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      targetX: targetX ?? this.targetX,
      targetZ: targetZ ?? this.targetZ,
      capabilities: capabilities,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.name,
        'state': state.name,
        'currentTaskId': currentTaskId,
        'x': x,
        'y': y,
        'z': z,
      };

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      name: json['name'] as String,
      role: AgentRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => AgentRole.general,
      ),
      state: AgentState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => AgentState.idle,
      ),
      currentTaskId: json['currentTaskId'] as String?,
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      z: (json['z'] as num?)?.toDouble() ?? 0,
    );
  }
}