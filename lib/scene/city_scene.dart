import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../models/agent.dart';

/// Контроллер 3D-города.
/// При ошибке GPU / flutter_scene автоматически переключается на красивый 2.5D fallback.
class CitySceneController {
  Scene? scene;
  final List<Agent> agents;
  final void Function(Agent)? onAgentTapped;

  final Map<String, Node> _agentNodes = {};
  final math.Random _rng = math.Random(42);
  bool use3d = false;
  String? lastError;

  CitySceneController({
    required this.agents,
    this.onAgentTapped,
  });

  Future<void> init() async {
    try {
      await Scene.initializeStaticResources();
      scene = Scene();
      _buildGround();
      _buildRoads();
      _buildDistricts();
      _buildPark();
      _buildAgents();
      use3d = true;
      lastError = null;
    } catch (e, st) {
      use3d = false;
      lastError = e.toString();
      debugPrint('3D init failed, using fallback: $e\n$st');
    }
  }

  // ---------- GROUND ----------
  void _buildGround() {
    final ground = Node(
      mesh: Mesh(
        PlaneGeometry(width: 90, depth: 90),
        PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(0.20, 0.30, 0.17, 1.0),
      ),
    );
    scene!.add(ground);

    // Река
    final river = Node(
      mesh: Mesh(
        CuboidGeometry(vm.Vector3(90, 0.06, 7)),
        PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(0.12, 0.32, 0.52, 1.0),
      ),
    );
    river.localTransform = Matrix4.translation(vm.Vector3(0, 0.03, 20));
    scene!.add(river);
  }

  // ---------- ROADS ----------
  void _buildRoads() {
    void road(vm.Vector3 center, vm.Vector3 size) {
      final n = Node(
        mesh: Mesh(
          CuboidGeometry(size),
          PhysicallyBasedMaterial()
            ..baseColorFactor = vm.Vector4(0.16, 0.16, 0.18, 1.0),
        ),
      );
      n.localTransform = Matrix4.translation(center + vm.Vector3(0, size.y / 2, 0));
      scene!.add(n);
    }

    road(vm.Vector3(0, 0.02, 0), vm.Vector3(80, 0.05, 3.8));
    road(vm.Vector3(0, 0.02, 0), vm.Vector3(3.8, 0.05, 55));
    for (final z in [-14.0, 12.0, -26.0]) {
      road(vm.Vector3(0, 0.02, z), vm.Vector3(60, 0.04, 2.4));
    }
    for (final x in [-16.0, 16.0, -28.0, 28.0]) {
      road(vm.Vector3(x, 0.02, 0), vm.Vector3(2.4, 0.04, 45));
    }
  }

  // ---------- DISTRICTS ----------
  void _buildDistricts() {
    _block(vm.Vector3(0, 0, -10), 3, 2, vm.Vector3(4.8, 9, 4.8), 6, vm.Vector4(0.42, 0.48, 0.60, 1), 7.5);
    _block(vm.Vector3(-20, 0, 2), 3, 3, vm.Vector3(3.3, 3.6, 3.3), 2.8, vm.Vector4(0.58, 0.50, 0.44, 1), 5.8);
    _block(vm.Vector3(20, 0, 2), 3, 3, vm.Vector3(3.1, 4.0, 3.1), 3.0, vm.Vector4(0.52, 0.48, 0.46, 1), 5.5);
    _block(vm.Vector3(-12, 0, 14), 4, 1, vm.Vector3(5.2, 2.6, 4.2), 1.4, vm.Vector4(0.38, 0.40, 0.38, 1), 7.2);

    _building(vm.Vector3(9, 0, -22), vm.Vector3(5.5, 16, 5.5), vm.Vector4(0.32, 0.38, 0.52, 1));
    _building(vm.Vector3(-7, 0, -24), vm.Vector3(4.2, 12, 4.2), vm.Vector4(0.48, 0.42, 0.52, 1));
  }

  void _block(vm.Vector3 center, int cols, int rows, vm.Vector3 base, double hVar, vm.Vector4 color, double spacing) {
    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        final ox = (i - (cols - 1) / 2) * spacing;
        final oz = (j - (rows - 1) / 2) * spacing;
        final h = base.y + _rng.nextDouble() * hVar;
        final w = base.x * (0.85 + _rng.nextDouble() * 0.3);
        final d = base.z * (0.85 + _rng.nextDouble() * 0.3);
        final c = vm.Vector4(
          (color.r + (_rng.nextDouble() - 0.5) * 0.07).clamp(0.0, 1.0),
          (color.g + (_rng.nextDouble() - 0.5) * 0.07).clamp(0.0, 1.0),
          (color.b + (_rng.nextDouble() - 0.5) * 0.07).clamp(0.0, 1.0),
          1.0,
        );
        _building(center + vm.Vector3(ox, 0, oz), vm.Vector3(w, h, d), c);
      }
    }
  }

  void _building(vm.Vector3 pos, vm.Vector3 size, vm.Vector4 color) {
    final body = Node(
      mesh: Mesh(
        CuboidGeometry(size),
        PhysicallyBasedMaterial()..baseColorFactor = color,
      ),
    );
    body.localTransform = Matrix4.translation(pos + vm.Vector3(0, size.y / 2, 0));

    final roof = Node(
      mesh: Mesh(
        CuboidGeometry(vm.Vector3(size.x + 0.3, 0.25, size.z + 0.3)),
        PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(color.r * 0.6, color.g * 0.6, color.b * 0.65, 1),
      ),
    );
    roof.localTransform = Matrix4.translation(vm.Vector3(0, size.y / 2 + 0.13, 0));
    body.add(roof);

    scene!.add(body);
  }

  // ---------- PARK ----------
  void _buildPark() {
    final lawn = Node(
      mesh: Mesh(
        CuboidGeometry(vm.Vector3(16, 0.07, 11)),
        PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(0.18, 0.42, 0.20, 1),
      ),
    );
    lawn.localTransform = Matrix4.translation(vm.Vector3(0, 0.04, 5));
    scene!.add(lawn);

    for (final p in [
      vm.Vector3(-5, 0, 3),
      vm.Vector3(4, 0, 4),
      vm.Vector3(-2, 0, 8),
      vm.Vector3(6, 0, 7),
      vm.Vector3(0, 0, 2),
      vm.Vector3(-6, 0, 7),
      vm.Vector3(2, 0, 9),
    ]) {
      _tree(p);
    }
  }

  void _tree(vm.Vector3 pos) {
    final trunk = Node(
      mesh: Mesh(
        CylinderGeometry(radius: 0.2, height: 1.5),
        PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(0.32, 0.20, 0.10, 1),
      ),
    );
    trunk.localTransform = Matrix4.translation(pos + vm.Vector3(0, 0.75, 0));

    final crown = Node(
      mesh: Mesh(
        SphereGeometry(radius: 1.2),
        PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(0.12, 0.42, 0.16, 1),
      ),
    );
    crown.localTransform = Matrix4.translation(vm.Vector3(0, 1.4, 0));
    trunk.add(crown);
    scene!.add(trunk);
  }

  // ---------- AGENTS ----------
  void _buildAgents() {
    for (final agent in agents) {
      final node = _createAgentNode(agent);
      _agentNodes[agent.id] = node;
      scene!.add(node);
    }
  }

  Node _createAgentNode(Agent agent) {
    final bodyColor = switch (agent.role) {
      AgentRole.builder => vm.Vector4(0.20, 0.55, 0.95, 1),
      AgentRole.deployer => vm.Vector4(0.95, 0.45, 0.15, 1),
      AgentRole.general => vm.Vector4(0.35, 0.80, 0.45, 1),
    };

    final body = Node(
      mesh: Mesh(
        CapsuleGeometry(radius: 0.34, height: 1.1),
        PhysicallyBasedMaterial()..baseColorFactor = bodyColor,
      ),
    );

    final head = Node(
      mesh: Mesh(
        SphereGeometry(radius: 0.28),
        PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(0.96, 0.86, 0.76, 1),
      ),
    );
    head.localTransform = Matrix4.translation(vm.Vector3(0, 0.95, 0));
    body.add(head);

    final statusColor = switch (agent.state) {
      AgentState.idle => vm.Vector4(0.3, 0.9, 0.4, 1),
      AgentState.working => vm.Vector4(1.0, 0.7, 0.1, 1),
      AgentState.walking => vm.Vector4(0.3, 0.7, 1.0, 1),
      AgentState.waiting => vm.Vector4(0.9, 0.9, 0.2, 1),
      AgentState.error => vm.Vector4(1.0, 0.25, 0.25, 1),
    };

    final status = Node(
      mesh: Mesh(
        SphereGeometry(radius: 0.12),
        PhysicallyBasedMaterial()..baseColorFactor = statusColor,
      ),
    );
    status.localTransform = Matrix4.translation(vm.Vector3(0, 1.4, 0));
    body.add(status);

    body.localTransform = Matrix4.translation(vm.Vector3(agent.x, 0.9, agent.z));
    return body;
  }

  void updateAgent(Agent agent) {
    final node = _agentNodes[agent.id];
    if (node == null) return;
    node.localTransform = Matrix4.translation(vm.Vector3(agent.x, 0.9, agent.z));
  }

  /// cameraBuilder получает Duration
  Camera createCamera(Duration elapsed) {
    final t = elapsed.inMicroseconds / 1e6;
    final angle = t * 0.07;
    const radius = 42.0;
    const height = 24.0;
    return PerspectiveCamera(
      position: vm.Vector3(
        radius * math.cos(angle),
        height,
        radius * math.sin(angle) * 0.75,
      ),
      target: vm.Vector3(0, 2, 0),
    );
  }
}

/// Виджет сцены: 3D или красивый fallback
class CitySceneView extends StatefulWidget {
  final CitySceneController controller;
  const CitySceneView({super.key, required this.controller});

  @override
  State<CitySceneView> createState() => _CitySceneViewState();
}

class _CitySceneViewState extends State<CitySceneView> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await widget.controller.init();
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const ColoredBox(
        color: Color(0xFF0a0a14),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.controller.use3d && widget.controller.scene != null) {
      return SceneView(
        widget.controller.scene!,
        cameraBuilder: (elapsed) => widget.controller.createCamera(elapsed),
      );
    }

    // Fallback — красивый 2.5D город
    return _FallbackCity(agents: widget.controller.agents, error: widget.controller.lastError);
  }
}

// ==================== FALLBACK 2.5D ====================

class _FallbackCity extends StatelessWidget {
  final List<Agent> agents;
  final String? error;
  const _FallbackCity({required this.agents, this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0d1020), Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: _CityPainter(agents)),
          if (error != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 100,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '3D недоступен (нужен Flutter GPU / Impeller).\nПоказан fallback-город.\n$error',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          Positioned(
            left: 12,
            bottom: 16,
            child: _MiniMap(agents: agents),
          ),
        ],
      ),
    );
  }
}

class _CityPainter extends CustomPainter {
  final List<Agent> agents;
  _CityPainter(this.agents);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.55;

    // ground plane
    final ground = Paint()..color = const Color(0xFF1e3a2f);
    canvas.drawRect(Rect.fromLTWH(0, cy, size.width, size.height - cy), ground);

    // simple isometric-ish buildings
    final buildings = [
      _B(cx - 160, cy - 20, 50, 110, const Color(0xFF3d4f6f)),
      _B(cx - 90, cy - 10, 45, 90, const Color(0xFF4a5d7a)),
      _B(cx - 20, cy - 40, 55, 140, const Color(0xFF2f3e5c)),
      _B(cx + 50, cy - 15, 48, 100, const Color(0xFF455a75)),
      _B(cx + 120, cy - 5, 42, 80, const Color(0xFF3a4d68)),
      _B(cx - 200, cy + 10, 40, 70, const Color(0xFF5c4a3a)),
      _B(cx + 180, cy + 5, 40, 75, const Color(0xFF5a4e42)),
    ];

    for (final b in buildings) {
      final body = Paint()..color = b.color;
      final roof = Paint()..color = Color.lerp(b.color, Colors.black, 0.3)!;
      canvas.drawRect(Rect.fromLTWH(b.x, b.y - b.h, b.w, b.h), body);
      canvas.drawRect(Rect.fromLTWH(b.x - 2, b.y - b.h - 6, b.w + 4, 8), roof);

      // windows
      final win = Paint()..color = const Color(0xFF88ccff).withOpacity(0.5);
      for (double wy = b.y - b.h + 12; wy < b.y - 10; wy += 18) {
        for (double wx = b.x + 8; wx < b.x + b.w - 8; wx += 14) {
          canvas.drawRect(Rect.fromLTWH(wx, wy, 8, 10), win);
        }
      }
    }

    // agents as glowing dots
    for (final a in agents) {
      final ax = cx + a.x * 6;
      final ay = cy + a.z * 4;
      final color = switch (a.state) {
        AgentState.idle => Colors.greenAccent,
        AgentState.working => Colors.orangeAccent,
        AgentState.walking => Colors.lightBlueAccent,
        AgentState.waiting => Colors.yellowAccent,
        AgentState.error => Colors.redAccent,
      };
      canvas.drawCircle(Offset(ax, ay), 7, Paint()..color = color.withOpacity(0.9));
      canvas.drawCircle(Offset(ax, ay), 12, Paint()..color = color.withOpacity(0.25));
    }
  }

  @override
  bool shouldRepaint(covariant _CityPainter old) => true;
}

class _B {
  final double x, y, w, h;
  final Color color;
  _B(this.x, this.y, this.w, this.h, this.color);
}

class _MiniMap extends StatelessWidget {
  final List<Agent> agents;
  const _MiniMap({required this.agents});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 6,
            left: 10,
            child: Text('Агенты', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ),
          ...agents.map((a) {
            final nx = ((a.x + 30) / 60).clamp(0.0, 1.0);
            final nz = ((a.z + 25) / 50).clamp(0.0, 1.0);
            final color = switch (a.state) {
              AgentState.idle => Colors.greenAccent,
              AgentState.working => Colors.orangeAccent,
              AgentState.walking => Colors.lightBlueAccent,
              AgentState.waiting => Colors.yellowAccent,
              AgentState.error => Colors.redAccent,
            };
            return Positioned(
              left: 10 + nx * 145,
              top: 26 + nz * 90,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 5)],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
