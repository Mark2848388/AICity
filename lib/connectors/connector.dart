/// Базовый интерфейс любого коннектора.
/// Агенты получают список доступных коннекторов и вызывают их методы как tools.
abstract class Connector {
  /// Уникальный идентификатор (github, supabase, fcm...)
  String get id;

  /// Человекочитаемое имя
  String get name;

  /// Краткое описание для LLM / UI
  String get description;

  /// Готов ли коннектор к работе (есть токены, настройки и т.д.)
  bool get isReady;

  /// Список доступных действий (tools), которые агент может вызвать
  List<ConnectorAction> get actions;

  /// Выполнить действие по имени
  Future<ConnectorResult> execute(String actionName, Map<String, dynamic> params);
}

/// Описание одного действия коннектора
class ConnectorAction {
  final String name;
  final String description;
  final Map<String, dynamic> parametersSchema; // JSON Schema-like

  const ConnectorAction({
    required this.name,
    required this.description,
    this.parametersSchema = const {},
  });
}

/// Результат выполнения действия
class ConnectorResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final String? error;

  const ConnectorResult.success({this.message, this.data})
      : success = true,
        error = null;

  const ConnectorResult.failure(this.error)
      : success = false,
        message = null,
        data = null;

  Map<String, dynamic> toJson() => {
        'success': success,
        if (message != null) 'message': message,
        if (data != null) 'data': data,
        if (error != null) 'error': error,
      };
}

/// Реестр всех коннекторов (синглтон)
class ConnectorRegistry {
  ConnectorRegistry._();
  static final ConnectorRegistry instance = ConnectorRegistry._();

  final Map<String, Connector> _connectors = {};

  void register(Connector connector) {
    _connectors[connector.id] = connector;
  }

  Connector? get(String id) => _connectors[id];

  List<Connector> get all => _connectors.values.toList();

  List<Connector> get ready => _connectors.values.where((c) => c.isReady).toList();

  /// Удобный список всех actions для передачи в LLM как tools
  List<Map<String, dynamic>> get allActionsAsTools {
    final tools = <Map<String, dynamic>>[];
    for (final c in _connectors.values) {
      if (!c.isReady) continue;
      for (final action in c.actions) {
        tools.add({
          'name': '${c.id}.${action.name}',
          'description': '[${c.name}] ${action.description}',
          'parameters': action.parametersSchema,
        });
      }
    }
    return tools;
  }
}