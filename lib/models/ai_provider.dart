/// Провайдер ИИ (OpenAI, Grok, Anthropic, Gemini, Ollama и т.д.)
class AiProvider {
  final String id;
  final String name;
  final String baseUrl;
  final String model;
  final String? apiKey;
  final bool enabled;
  final Map<String, dynamic> extra;

  const AiProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.model,
    this.apiKey,
    this.enabled = true,
    this.extra = const {},
  });

  bool get isReady => apiKey != null && apiKey!.isNotEmpty;

  AiProvider copyWith({
    String? name,
    String? baseUrl,
    String? model,
    String? apiKey,
    bool? enabled,
    Map<String, dynamic>? extra,
  }) {
    return AiProvider(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      enabled: enabled ?? this.enabled,
      extra: extra ?? this.extra,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseUrl': baseUrl,
        'model': model,
        'apiKey': apiKey,
        'enabled': enabled,
        'extra': extra,
      };

  factory AiProvider.fromJson(Map<String, dynamic> json) {
    return AiProvider(
      id: json['id'] as String,
      name: json['name'] as String,
      baseUrl: json['baseUrl'] as String,
      model: json['model'] as String,
      apiKey: json['apiKey'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      extra: Map<String, dynamic>.from(json['extra'] as Map? ?? {}),
    );
  }

  /// Предустановленные провайдеры
  static List<AiProvider> defaults() => [
        const AiProvider(
          id: 'grok',
          name: 'xAI Grok',
          baseUrl: 'https://api.x.ai/v1',
          model: 'grok-3',
        ),
        const AiProvider(
          id: 'openai',
          name: 'OpenAI',
          baseUrl: 'https://api.openai.com/v1',
          model: 'gpt-4o',
        ),
        const AiProvider(
          id: 'anthropic',
          name: 'Anthropic Claude',
          baseUrl: 'https://api.anthropic.com/v1',
          model: 'claude-sonnet-4-20250514',
        ),
        const AiProvider(
          id: 'gemini',
          name: 'Google Gemini',
          baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
          model: 'gemini-2.0-flash',
        ),
        const AiProvider(
          id: 'ollama',
          name: 'Ollama (Local)',
          baseUrl: 'http://localhost:11434/v1',
          model: 'llama3.2',
          apiKey: 'ollama', // Ollama не требует реального ключа
        ),
      ];
}