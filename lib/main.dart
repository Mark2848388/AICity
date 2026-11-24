import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/agent.dart';
import 'models/task.dart';
import 'scene/city_scene.dart';
import 'services/notification_service.dart';
import 'services/task_service.dart';
import 'services/settings_service.dart';
import 'ui/task_panel.dart';
import 'ui/settings_screen.dart';
import 'agents/builder_agent.dart';
import 'agents/deployer_agent.dart';
import 'connectors/connectors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  initConnectors();

  final taskService = TaskService();
  await taskService.init();

  final settingsService = SettingsService();
  await settingsService.init();

  await NotificationService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: taskService),
        ChangeNotifierProvider.value(value: settingsService),
      ],
      child: const AgentCityApp(),
    ),
  );
}

class AgentCityApp extends StatelessWidget {
  const AgentCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agent City',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const CityHomePage(),
    );
  }
}

class CityHomePage extends StatefulWidget {
  const CityHomePage({super.key});

  @override
  State<CityHomePage> createState() => _CityHomePageState();
}

class _CityHomePageState extends State<CityHomePage> {
  late CitySceneController _sceneController;
  Agent? _selectedAgent;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsService>();
    _sceneController = CitySceneController(
      agents: settings.agents,
      onAgentTapped: (agent) => setState(() => _selectedAgent = agent),
    );
  }

  Future<void> _createBuildTask() async {
    final taskService = context.read<TaskService>();
    final settings = context.read<SettingsService>();

    final task = await taskService.createTask(
      title: 'Собрать тестовое Flutter-приложение',
      description: 'Создать минимальный Flutter-проект и упаковать в ZIP',
      type: TaskType.buildFlutterZip,
      metadata: {
        'projectName': 'hello_from_agent_${DateTime.now().millisecondsSinceEpoch % 10000}',
      },
    );

    final builderAgent = settings.agents.firstWhere(
      (a) => a.role == AgentRole.builder,
      orElse: () => settings.agents.first,
    );

    await taskService.assignAgent(task.id, builderAgent.id);

    final builder = BuilderAgent(taskService: taskService, agentId: builderAgent.id);
    await builder.execute(task);

    final updated = taskService.getTask(task.id);
    if (updated?.status == TaskStatus.completed) {
      final zipPath = _extractZipPath(updated!.result);
      if (zipPath != null) {
        await _createDeployTask(zipPath, updated.metadata['projectName'] as String?);
      }
    }
  }

  String? _extractZipPath(String? result) {
    if (result == null) return null;
    final match = RegExp(r'ZIP готов: (.+) \(').firstMatch(result);
    return match?.group(1);
  }

  Future<void> _createDeployTask(String zipPath, String? projectName) async {
    final taskService = context.read<TaskService>();
    final settings = context.read<SettingsService>();

    final task = await taskService.createTask(
      title: 'Залить на GitHub + APK',
      description: 'Загрузить ZIP и запустить GitHub Actions',
      type: TaskType.deployToGithub,
      metadata: {
        'zipPath': zipPath,
        'projectName': projectName ?? 'agent-project',
      },
    );

    final deployerAgent = settings.agents.firstWhere(
      (a) => a.role == AgentRole.deployer,
      orElse: () => settings.agents.first,
    );

    await taskService.assignAgent(task.id, deployerAgent.id);

    final deployer = DeployerAgent(taskService: taskService, agentId: deployerAgent.id);
    await deployer.execute(task);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      body: Stack(
        children: [
          CitySceneView(controller: _sceneController),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text(
                    'Agent City',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    tooltip: 'API ключи и агенты',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _createBuildTask,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Новая задача'),
                  ),
                ],
              ),
            ),
          ),

          const Positioned(
            top: 80,
            right: 12,
            bottom: 12,
            width: 340,
            child: TaskPanel(),
          ),

          if (_selectedAgent != null)
            Positioned(
              left: 12,
              top: 80,
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(_selectedAgent!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Chip(label: Text(_selectedAgent!.role.name, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
                          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _selectedAgent = null)),
                        ],
                      ),
                      Text('Статус: ${_selectedAgent!.state.name}'),
                    ],
                  ),
                ),
              ),
            ),

          // Индикатор готовых провайдеров
          Positioned(
            left: 12,
            bottom: 160,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    settings.defaultProvider != null ? Icons.smart_toy : Icons.smart_toy_outlined,
                    size: 16,
                    color: settings.defaultProvider != null ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    settings.defaultProvider != null
                        ? 'ИИ: ${settings.defaultProvider!.name}'
                        : 'Нет API-ключа',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
