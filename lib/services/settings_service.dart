import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/ai_provider.dart';
import '../models/agent.dart';

/// Хранит API-ключи провайдеров и настройки агентов.
class SettingsService extends ChangeNotifier {
  static const String _boxName = 'settings';
  late Box<String> _box;

  List<AiProvider> _providers = [];
  List<Agent> _agents = [];

  List<AiProvider> get providers => List.unmodifiable(_providers);
  List<Agent> get agents => List.unmodifiable(_agents);

  AiProvider? get defaultProvider {
    final enabled = _providers.where((p) => p.enabled && p.isReady).toList();
    return enabled.isNotEmpty ? enabled.first : null;
  }

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    await _load();
  }

  Future<void> _load() async {
    // Providers
    final providersJson = _box.get('providers');
    if (providersJson != null) {
      try {
        final list = jsonDecode(providersJson) as List;
        _providers = list.map((e) => AiProvider.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _providers = AiProvider.defaults();
      }
    } else {
      _providers = AiProvider.defaults();
    }

    // Agents
    final agentsJson = _box.get('agents');
    if (agentsJson != null) {
      try {
        final list = jsonDecode(agentsJson) as List;
        _agents = list.map((e) => Agent.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        _agents = _defaultAgents();
      }
    } else {
      _agents = _defaultAgents();
    }

    notifyListeners();
  }

  List<Agent> _defaultAgents() {
    return [
      Agent(id: 'builder-1', name: 'Builder', role: AgentRole.builder, x: -4, z: 3),
      Agent(id: 'deployer-1', name: 'Deployer', role: AgentRole.deployer, x: 5, z: -2),
      Agent(id: 'researcher-1', name: 'Researcher', role: AgentRole.general, x: -2, z: -6),
      Agent(id: 'helper-1', name: 'Helper', role: AgentRole.general, x: 3, z: 6),
      Agent(id: 'tester-1', name: 'Tester', role: AgentRole.general, x: -7, z: 1),
    ];
  }

  Future<void> _saveProviders() async {
    await _box.put('providers', jsonEncode(_providers.map((p) => p.toJson()).toList()));
  }

  Future<void> _saveAgents() async {
    await _box.put('agents', jsonEncode(_agents.map((a) => a.toJson()).toList()));
  }

  // --- Providers ---

  Future<void> updateProvider(AiProvider updated) async {
    final idx = _providers.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return;
    _providers[idx] = updated;
    await _saveProviders();
    notifyListeners();
  }

  Future<void> setApiKey(String providerId, String? apiKey) async {
    final idx = _providers.indexWhere((p) => p.id == providerId);
    if (idx == -1) return;
    _providers[idx] = _providers[idx].copyWith(apiKey: apiKey);
    await _saveProviders();
    notifyListeners();
  }

  Future<void> toggleProvider(String providerId, bool enabled) async {
    final idx = _providers.indexWhere((p) => p.id == providerId);
    if (idx == -1) return;
    _providers[idx] = _providers[idx].copyWith(enabled: enabled);
    await _saveProviders();
    notifyListeners();
  }

  // --- Agents ---

  Future<void> updateAgent(Agent updated) async {
    final idx = _agents.indexWhere((a) => a.id == updated.id);
    if (idx == -1) return;
    _agents[idx] = updated;
    await _saveAgents();
    notifyListeners();
  }

  Future<void> addAgent(Agent agent) async {
    _agents.add(agent);
    await _saveAgents();
    notifyListeners();
  }

  Future<void> removeAgent(String id) async {
    _agents.removeWhere((a) => a.id == id);
    await _saveAgents();
    notifyListeners();
  }
}