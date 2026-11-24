import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_provider.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки агентов и API'),
        backgroundColor: Colors.black87,
      ),
      body: Consumer<SettingsService>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'AI Провайдеры (API ключи)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Добавь ключи — агенты смогут думать через выбранных ИИ',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
              ),
              const SizedBox(height: 16),
              ...settings.providers.map((p) => _ProviderCard(provider: p)),
              const SizedBox(height: 32),
              const Text(
                'Агенты в городе',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...settings.agents.map((a) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _roleColor(a.role.name),
                      child: Text(a.name[0], style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(a.name),
                    subtitle: Text('${a.role.name} • ${a.state.name}'),
                    trailing: Text(
                      a.currentTaskId != null ? 'Работает' : 'Свободен',
                      style: TextStyle(
                        color: a.currentTaskId != null ? Colors.orangeAccent : Colors.greenAccent,
                        fontSize: 12,
                      ),
                    ),
                  )),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  // Можно добавить диалог создания нового агента
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Добавление агентов — в следующей версии')),
                  );
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Добавить агента'),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'builder':
        return Colors.blue;
      case 'deployer':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}

class _ProviderCard extends StatefulWidget {
  final AiProvider provider;
  const _ProviderCard({required this.provider});

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  late TextEditingController _keyController;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.provider.apiKey ?? '');
  }

  @override
  void didUpdateWidget(covariant _ProviderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider.apiKey != widget.provider.apiKey) {
      _keyController.text = widget.provider.apiKey ?? '';
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final settings = context.read<SettingsService>();

    return Card(
      color: Colors.white.withOpacity(0.06),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Text(
                        '${p.model}  •  ${p.baseUrl}',
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: p.enabled,
                  onChanged: (v) => settings.toggleProvider(p.id, v),
                ),
                const SizedBox(width: 4),
                Icon(
                  p.isReady ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: p.isReady ? Colors.greenAccent : Colors.orangeAccent,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _keyController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'API Key',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    IconButton(
                      icon: const Icon(Icons.save, size: 20),
                      onPressed: () async {
                        await settings.setApiKey(p.id, _keyController.text.trim().isEmpty ? null : _keyController.text.trim());
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Ключ для ${p.name} сохранён')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}