import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../connector.dart';

/// Коннектор Supabase.
/// Основные возможности для MVP:
/// - Сохранение / чтение задач
/// - Загрузка ZIP и файлов в Storage
/// - Realtime-подписка (через отдельный сервис)
class SupabaseConnector implements Connector {
  final String? url;          // https://xxxx.supabase.co
  final String? anonKey;      // anon / service_role key
  final String? serviceKey;   // для серверных операций (опционально)

  SupabaseConnector({
    this.url,
    this.anonKey,
    this.serviceKey,
  });

  @override
  String get id => 'supabase';

  @override
  String get name => 'Supabase';

  @override
  String get description =>
      'Хранение задач, логов и ZIP-файлов. Storage + Database + (позже) Realtime';

  @override
  bool get isReady =>
      url != null &&
      url!.isNotEmpty &&
      ((anonKey != null && anonKey!.isNotEmpty) ||
          (serviceKey != null && serviceKey!.isNotEmpty));

  String get _key => serviceKey ?? anonKey!;

  @override
  List<ConnectorAction> get actions => [
        const ConnectorAction(
          name: 'upload_file',
          description: 'Загрузить файл в Supabase Storage',
          parametersSchema: {
            'type': 'object',
            'properties': {
              'bucket': {'type': 'string', 'default': 'agent-city'},
              'path': {'type': 'string', 'description': 'Путь внутри bucket, например builds/hello.zip'},
              'localPath': {'type': 'string', 'description': 'Локальный путь к файлу'},
              'upsert': {'type': 'boolean', 'default': true},
            },
            'required': ['path', 'localPath'],
          },
        ),
        const ConnectorAction(
          name: 'get_public_url',
          description: 'Получить публичный URL файла из Storage',
          parametersSchema: {
            'type': 'object',
            'properties': {
              'bucket': {'type': 'string', 'default': 'agent-city'},
              'path': {'type': 'string'},
            },
            'required': ['path'],
          },
        ),
        const ConnectorAction(
          name: 'save_task',
          description: 'Сохранить или обновить задачу в таблице tasks',
          parametersSchema: {
            'type': 'object',
            'properties': {
              'task': {'type': 'object', 'description': 'JSON задачи'},
            },
            'required': ['task'],
          },
        ),
        const ConnectorAction(
          name: 'list_tasks',
          description: 'Получить список задач (с фильтром по статусу)',
          parametersSchema: {
            'type': 'object',
            'properties': {
              'status': {'type': 'string'},
              'limit': {'type': 'integer', 'default': 20},
            },
          },
        ),
      ];

  @override
  Future<ConnectorResult> execute(String actionName, Map<String, dynamic> params) async {
    if (!isReady) {
      return const ConnectorResult.failure(
        'Supabase connector не готов. Укажи SUPABASE_URL и SUPABASE_ANON_KEY (или SERVICE_KEY).',
      );
    }

    try {
      switch (actionName) {
        case 'upload_file':
          return await _uploadFile(params);
        case 'get_public_url':
          return await _getPublicUrl(params);
        case 'save_task':
          return await _saveTask(params);
        case 'list_tasks':
          return await _listTasks(params);
        default:
          return ConnectorResult.failure('Неизвестное действие: $actionName');
      }
    } catch (e) {
      return ConnectorResult.failure(e.toString());
    }
  }

  Map<String, String> get _headers => {
        'apikey': _key,
        'Authorization': 'Bearer $_key',
        'Content-Type': 'application/json',
      };

  Future<ConnectorResult> _uploadFile(Map<String, dynamic> params) async {
    final bucket = params['bucket'] as String? ?? 'agent-city';
    final path = params['path'] as String;
    final localPath = params['localPath'] as String;
    final upsert = params['upsert'] as bool? ?? true;

    final file = File(localPath);
    if (!await file.exists()) {
      return ConnectorResult.failure('Файл не найден: $localPath');
    }

    final bytes = await file.readAsBytes();
    final uri = Uri.parse('$url/storage/v1/object/$bucket/$path');

    final resp = await http.post(
      uri,
      headers: {
        ..._headers,
        'Content-Type': 'application/octet-stream',
        if (upsert) 'x-upsert': 'true',
      },
      body: bytes,
    );

    // 200 / 201 = ok
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final publicUrl = '$url/storage/v1/object/public/$bucket/$path';
      return ConnectorResult.success(
        message: 'Файл загружен в Storage',
        data: {
          'path': path,
          'bucket': bucket,
          'public_url': publicUrl,
          'size': bytes.length,
        },
      );
    }

    return ConnectorResult.failure('upload_file: ${resp.statusCode} ${resp.body}');
  }

  Future<ConnectorResult> _getPublicUrl(Map<String, dynamic> params) async {
    final bucket = params['bucket'] as String? ?? 'agent-city';
    final path = params['path'] as String;
    final publicUrl = '$url/storage/v1/object/public/$bucket/$path';

    return ConnectorResult.success(
      message: 'Public URL',
      data: {'public_url': publicUrl},
    );
  }

  Future<ConnectorResult> _saveTask(Map<String, dynamic> params) async {
    final task = params['task'] as Map<String, dynamic>;

    // Используем upsert по id
    final resp = await http.post(
      Uri.parse('$url/rest/v1/tasks?on_conflict=id'),
      headers: {
        ..._headers,
        'Prefer': 'resolution=merge-duplicates,return=representation',
      },
      body: jsonEncode(task),
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      return ConnectorResult.success(
        message: 'Задача сохранена',
        data: {'task': jsonDecode(resp.body)},
      );
    }

    return ConnectorResult.failure('save_task: ${resp.statusCode} ${resp.body}');
  }

  Future<ConnectorResult> _listTasks(Map<String, dynamic> params) async {
    final status = params['status'] as String?;
    final limit = params['limit'] as int? ?? 20;

    var query = '$url/rest/v1/tasks?select=*&order=created_at.desc&limit=$limit';
    if (status != null) {
      query += '&status=eq.$status';
    }

    final resp = await http.get(Uri.parse(query), headers: _headers);

    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List;
      return ConnectorResult.success(
        message: 'Найдено задач: ${list.length}',
        data: {'tasks': list},
      );
    }

    return ConnectorResult.failure('list_tasks: ${resp.statusCode} ${resp.body}');
  }
}