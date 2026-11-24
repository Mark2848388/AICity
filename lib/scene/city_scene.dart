import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../models/agent.dart';

/// Большой и красивый 3D-город на flutter_scene.
class CitySceneController {
  Scene? scene;
  final List<Agent> agents;
  final void Function(Agent)? onAgentTapped;

  final Map<String, Node> _agentNodes = {};
  final math.Random _rng = math.Random(42);

  CitySceneController({
    required this.agents,
    this.onAgentTapped,
  });

  Future<void> init() async {
    await Scene.initializeStaticResources();
    scene = Scene();

    _buildGround();
    _buildRoads();
    _buildDistricts();
    _buildPark();
    _buildAgents();
  }

  void _buildGround() {
    final ground = Node(
      name: 'ground',
      mesh: Mesh(
        PlaneGeometry(vm.Vector2(80, 80)),
        PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(0.22, 0.32, 0.18, 1.0),
      ),
    );
    scene!.add(ground);

    final river = Node(
      name: 'river',
      mesh: Mesh(
        CuboidGeometry(vm.Vector3(80, 0.08, 6)),
        PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(0.15, 0.35, 0.55, 1.0),
      ),
    );
    river.localTransform = Matrix4.translation(vm.Vector3(0, 0.04, 18));
    scene!.add(river);
  }

  void _buildRoads() {
    _road(vm.Vector3(0, 0.03, 0), vm.Vector3(70, 0.06, 3.5));
    _road(vm.Vector3(0, 0.03, 0), vm.Vector3(3.5, 0.06, 50));
    for (final z in [-12.0, 12.0, -22.0]) {
      _road(vm.Vector3(0, 0.03, z), vm.Vector3(55, 0.05, 2.2));
    }
    for (final x in [-14.0, 14.0, -24.0, 24.0]) {
      _road(vm.Vector3(x, 0.03, 0), vm.Vector3(2.2, 0.05, 40));
    }
  }

  void _road(vm.Vector3 center, vm.Vector3 size) {
    final road = Node(
      name: 'road',
      mesh: Mesh(
        CuboidGeometry(size),
        PhysicallyBasedMaterial()
          ..baseColorFactor = vm.Vector4(0.18, 0.18, 0.2, 1.0),
      ),
    );
    road.localTransform = Matrix4.translation(center + vm.Vector3(0, size.y / 2, 0));
    scene!.add(road);
  }

  void _buildDistricts() {
    _block(center: vm.Vector3(0, 0, -8), cols: 3, rows: 2, baseSize: vm.Vector3(4.5, 8, 4.5), heightVariation: 5, color: vm.Vector4(0.45, 0.5, 0.62, 1), spacing: 7);
    _block(center: vm.Vector3(-18, 0, 2), cols: 3, rows: 3, baseSize: vm.Vector3(3.2, 3.5, 3.2), heightVariation: 2.5, color: vm.Vector4(0.6, 0.52, 0.45, 1), spacing: 5.5);
    _block(center: vm.Vector3(18, 0, 2), cols: 3, rows: 3, baseSize: vm.Vector3(3.0, 3.8, 3.0), heightVariation: 2.8, color: vm.Vector4(0.55, 0.5, 0.48, 1), spacing: 5.2);
    _block(center: vm.Vector3(-10, 0, 12), cols: 4, rows: 1, baseSize: vm.Vector3(5, 2.8, 4), heightVariation: 1.2, color: vm.Vector4(0.4, 0.42, 0.4, 1), spacing: 7);
    _building(vm.Vector3(8, 0, -18), vm.Vector3(5, 14, 5), vm.Vector4(0.35, 0.4, 0.55, 1));
    _building(vm.Vector3(-6, 0, -20), vm.Vector3(4, 11, 4), vm.Vector4(0.5, 0.45, 0.55, 1));
  }

  void _block({required vm.Vector3 center, required int cols, required int rows, required vm.Vector3 baseSize, required double heightVariation, required vm.Vector4 color, required double spacing}) {
    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        final ox = (i - (cols - 1) / 2) * spacing;
        final oz = (j - (rows - 1) / 2) * spacing;
        final h = baseSize.y + _rng.nextDouble() * heightVariation;
        final w = baseSize.x * (0.85 + _rng.nextDouble() * 0.3);
        final d = baseSize.z * (0.85 + _rng.nextDouble() * 0.3);
        final pos = center + vm.Vector3(ox, 0, oz);
        final c = vm.Vector4(
          (color.r + (_rng.nextDouble() - 0.5) * 0.08).clamp(0.0, 1.0),
          (color.g + (_rng.nextDouble() - 0.5) * 0.08).clamp(0.0, 1.0),
          (color.b + (_rng.nextDouble() - 0.5) * 0.08).clamp(0.0, 1.0),
          1.0,
        );
        _building(pos, vm.Vector3(w, h, d), c);
      }
    }
  }

  void _building(vm.Vector3 pos, vm.Vector3 size, vm.Vector4 color) {
    final body = Node(
      name: 'building',
      mesh: Mesh(CuboidGeometry(size), PhysicallyBasedMaterial()..baseColorFactor = color),
    );
    body.localTransform = Matrix4.translation(pos + vm.Vector3(0, size.y / 2, 0));

    final roof = Node(
      name: 'roof',
      mesh: Mesh(
        CuboidGeometry(vm.Vector3(size.x + 0.25, 0.22, size.z + 0.25)),
        PhysicallyBasedMaterial()..baseColorFactor = vm.Vector4(color.r * 0.65, color.g * 0.65, color.b * 0.7, 1),
      ),
    );
    roof.localTransform = Matrix4.translation(vm.Vector3(0, size.y / 2 + 0.12, 0));
    body.add(roof);

    if (size.y > 4) {
      final windowMat = PhysicallyBasedMaterial()..baseColorFactor = vm.Vector4(0.7, 0.85, 1.0, 1.0);
      for (var y = 1.2; y < size.y - 0.8; y += 1.4) {
        for (var side = 0; side < 2; side++) {
          final wx = side == 0 ? size.x / 2 + 0.02 : -size.x / 2 - 0.02;
          final window = Node(mesh: Mesh(CuboidGeometry(vm.Vector3(0.08, 0.5, 0.6)), windowMat));
          window.localTransform = Matrix4.translation(vm.Vector3(wx, y - size.y / 2, 0));
          body.add(window);
        }
      }
    }
    scene!.add(body);
  }

  void _buildPark() {
    final lawn = Node(
      name: 'lawn',
      mesh: Mesh(CuboidGeometry(vm.Vector3(14, 0.08, 10)), PhysicallyBasedMaterial()..baseColorFactor = vm.Vector4(0.2, 0.45, 0.22, 1)),
    );
    lawn.localTransform = Matrix4.translation(vm.Vector3(0, 0.04, 5));
    scene!.add(lawn);

    for (final pos in [vm.Vector3(-4, 0, 3), vm.Vector3(3, 0, 4), vm.Vector3(-2, 0, 7), vm.Vector3(5, 0, 6), vm.Vector3(0, 0, 2), vm.Vector3(-5, 0, 6)]) {
      _tree(pos);
    }
  }

  void _tree(vm.Vector3 pos) {
    final trunk = Node(
      name: 'trunk',
      mesh: Mesh(CylinderGeometry(radius: 0.18, height: 1.4), PhysicallyBasedMaterial()..baseColorFactor = vm.Vector4(0.35, 0.22, 0.12, 1)),
    );
    trunk.localTransform = Matrix4.translation(pos + vm.Vector3(0, 0.7, 0));
    final crown = Node(
      name: 'crown',
      mesh: Mesh(SphereGeometry(radius: 1.1), PhysicallyBasedMaterial()..baseColorFactor = vm.Vector4(0.15, 0.45, 0.18, 1)),
    );
    crown.localTransform = Matrix4.translation(vm.Vector3(0, 1.3, 0));
    trunk.add(crown);
    scene!.add(trunk);
  }

  void _buildAgents() {
    for (final agent in agents) {
      final node = _createAgentNode(agent);
      _agentNodes[agent.id] = node;
      scene!.add(node);
    }
  }

  Node _createAgentNode(Agent agent) {
    final bodyColor = _colorForRole(agent.role);
    final body = Node(
      name: 'agent_${agent.id}',
      mesh: Mesh(CapsuleGeometry(radius: 0.32, height: 1.05), PhysicallyBasedMaterial()..baseColorFactor = bodyColor),
    );
    final head = Node(
      name: 'head',
      mesh: Mesh(SphereGeometry(radius: 0.26), PhysicallyBasedMaterial()..baseColorFactor = vm.Vector4(0.96, 0.86, 0.76, 1)),
    );
    head.localTransform = Matrix4.translation(vm.Vector3(0, 0.9, 0));
    body.add(head);
    final status = Node(
      name: 'status',
      mesh: Mesh(SphereGeometry(radius: 0.11), PhysicallyBasedMaterial()..baseColorFactor = _colorForState(agent.state)),
    );
    status.localTransform = Matrix4.translation(vm.Vector3(0, 1.35, 0));
    body.add(status);
    body.localTransform = Matrix4.translation(vm.Vector3(agent.x, 0.85, agent.z));
    return body;
  }

  vm.Vector4 _colorForRole(AgentRole role) {
    switch (role) {
      case AgentRole.builder: return vm.Vector4(0.2, 0.55, 0.95, 1);
      case AgentRole.deployer: return vm.Vector4(0.95, 0.45, 0.15, 1);
      case AgentRole.general: return vm.Vector4(0.35, 0.8, 0.45, 1);
    }
  }

  vm.Vector4 _colorForState(AgentState state) {
    switch (state) {
      case AgentState.idle: return vm.Vector4(0.3, 0.9, 0.4, 1);
      case AgentState.working: return vm.Vector4(1.0, 0.7, 0.1, 1);
      case AgentState.walking: return vm.Vector4(0.3, 0.7, 1.0, 1);
      case AgentState.waiting: return vm.Vector4(0.9, 0.9, 0.2, 1);
      case AgentState.error: return vm.Vector4(1.0, 0.25, 0.25, 1);
    }
  }

  void updateAgent(Agent agent) {
    final node = _agentNodes[agent.id];
    if (node == null) return;
    node.localTransform = Matrix4.translation(vm.Vector3(agent.x, 0.85, agent.z));
  }

  Camera createCamera(double t) {
    final angle = t * 0.06;
    const radius = 38.0;
    const height = 22.0;
    return PerspectiveCamera(
      position: vm.Vector3(radius * vm.cos(angle), height, radius * vm.sin(angle) * 0.8),
      target: vm.Vector3(0, 2, 0),
    );
  }
}

class CitySceneView extends StatefulWidget {
  final CitySceneController controller;
  const CitySceneView({super.key, required this.controller});
  @override
  State<CitySceneView> createState() => _CitySceneViewState();
}

class _CitySceneViewState extends State<CitySceneView> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await widget.controller.init();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _ready = true; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const ColoredBox(color: Color(0xFF0f0f1a), child: Center(child: CircularProgressIndicator()));
    if (widget.controller.scene != null && _error == null) {
      return SceneView(widget.controller.scene!, cameraBuilder: (elapsed) => widget.controller.createCamera(elapsed));
    }
    return _FallbackView(agents: widget.controller.agents, error: _error);
  }
}

class _FallbackView extends StatelessWidget {
  final List<Agent> agents;
  final String? error;
  const _FallbackView({required this.agents, this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0a0a14),
      child: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: _GridPainter()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_city, size: 80, color: Colors.white24),
                const SizedBox(height: 16),
                const Text('Большой 3D-город', style: TextStyle(color: Colors.white54, fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                  error != null ? 'Ошибка: $error\n\ndart run flutter_scene:init\nflutter run --enable-flutter-gpu' : 'Загрузка сцены…',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: error != null ? Colors.redAccent : Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),
          Positioned(left: 16, bottom: 16, child: _MiniMap(agents: agents)),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1;
    const step = 48.0;
    for (double x = 0; x < size.width; x += step) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += step) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniMap extends StatelessWidget {
  final List<Agent> agents;
  const _MiniMap({required this.agents});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180, height: 140,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)),
      child: Stack(
        children: [
          const Positioned(top: 8, left: 10, child: Text('Агенты', style: TextStyle(color: Colors.white70, fontSize: 12))),
          ...agents.map((a) {
            final nx = ((a.x + 30) / 60).clamp(0.0, 1.0);
            final nz = ((a.z + 25) / 50).clamp(0.0, 1.0);
            return Positioned(
              left: 10 + nx * 155, top: 28 + nz * 95,
              child: Tooltip(
                message: '${a.name} • ${a.state.name}',
                child: Container(
                  width: 11, height: 11,
                  decoration: BoxDecoration(color: _stateColor(a.state), shape: BoxShape.circle, boxShadow: [BoxShadow(color: _stateColor(a.state).withOpacity(0.7), blurRadius: 6)]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
  Color _stateColor(AgentState s) {
    switch (s) {
      case AgentState.idle: return Colors.greenAccent;
      case AgentState.working: return Colors.orangeAccent;
      case AgentState.walking: return Colors.lightBlueAccent;
      case AgentState.waiting: return Colors.yellowAccent;
      case AgentState.error: return Colors.redAccent;
    }
  }
}
