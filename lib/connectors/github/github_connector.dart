import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../connector.dart';

/// Коннектор GitHub.
/// Позволяет агентам: создавать репозитории, заливать файлы/ZIP, запускать Actions, получать статус.
class GitHubConnector implements Connector {
  final String? token;
  final String? owner; // username или organization

  GitHubConnector({this.token, this.owner});

  @override
  String get id => 'github';

  @override
  String get name => 'GitHub';

  @override
  String get description =>
      'Создание репозиториев, загрузка файлов и ZIP, запуск GitHub Actions, получение артефактов';

  @override
  bool get isReady => token != null && token!.isNotEmpty && owner != null && owner!.isNotEmpty;

  @override
  List<ConnectorAction> get actions => [
        const ConnectorAction(
          name: 'create_repo',
          description: 'Создать новый публичный или приватный репозиторий',
          parametersSchema: {
            'type': 'object',
            'properties': {
              'name': {'type': 'string', 'description': 'Имя репозитория'},
              'description': {'type': 'string'},
              'private': {'type': 'boolean', 'default': false},
            },
            'required': ['name'],
          },
        ),
        const ConnectorAction(
          name: 'upload_file',
          description: 'Загрузить один файл в репозиторий (через Contents API)',
          parametersSchema: {
            'type': 'object',
            'properties': {
              'repo': {'type': 'string'},
              'path': {'type': 'string', 'description': 'Путь в репо, например src/main.dart'},
              'contentBase64': {'type': 'string'},
              'message': {'type': 'string', 'description': 'Commit message'},
              'branch': {'type': 'string', 'default': 'main'},
            },
            'required': ['repo', 'path', 'contentBase64'],
          },
        ),
        const ConnectorAction(
          name: 'upload_zip_as_release',
          description: 'Создать Release и прикрепить ZIP-файл как asset',
          parametersSchema: {
            'type': 'object',
            'properties': {
              'repo': {'type': 'string'},
              'zipPath': {'type': 'string', 'description': 'Локальный путь к ZIP'},
              'tag': {'type': 'string', 'default': 'v0.1.0-agent'},
              'name': {'type': 'string', 'description': 'Название релиза'},
            },
            'required': ['repo', 'zipPath'],
          },
        ),
        const ConnectorAction(
          name: 'trigger_workflow',
          description: 'Запустить GitHub Actions workflow (workflow_dispatch)',
          parametersSchema: {
            'type': 'object',
            'properties': {
              'repo': {'type': 'string'},
              'workflow': {'type': 'string', 'default': 'build_apk.yml'},
              'ref': {'type': 'string', 'default': 'main'},
            },
            'required': ['repo'],
          },
        ),
        const ConnectorAction(
          name: 'get_workflow_runs',
          description: 'Получить последние запуски workflow',
          parametersSchema: {
            'type': 'object',
            'properties': {
              'repo': {'type': 'string'},
              'workflow': {'type': 'string', 'default': 'build_apk.yml'},
              'perPage': {'type': 'integer', 'default': 5},
            },
            'required': ['repo'],
          },
        ),
      ];

  @override
  Future<ConnectorResult> execute(String actionName, Map<String, dynamic> params) async {
    if (!isReady) {
      return const ConnectorResult.failure(
        'GitHub connector не готов. Укажи GITHUB_TOKEN и GITHUB_OWNER.',
      );
    }

    try {
      switch (actionName) {
        case 'create_repo':
          return await _createRepo(params);
        case 'upload_file':
          return await _uploadFile(params);
        case 'upload_zip_as_release':
          return await _uploadZipAsRelease(params);
        case 'trigger_workflow':
          return await _triggerWorkflow(params);
        case 'get_workflow_runs':
          return await _getWorkflowRuns(params);
        default:
          return ConnectorResult.failure('Неизвестное действие: $actionName');
      }
    } catch (e) {
      return ConnectorResult.failure(e.toString());
    }
  }

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
      };

  Future<ConnectorResult> _createRepo(Map<String, dynamic> params) async {
    final name = params['name'] as String;
    final description = params['description'] as String? ?? 'Created by Agent City';
    final isPrivate = params['private'] as bool? ?? false;

    final resp = await http.post(
      Uri.parse('https://api.github.com/user/repos'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'description': description,
        'private': isPrivate,
        'auto_init': true,
      }),
    );

    if (resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return ConnectorResult.success(
        message: 'Репозиторий создан',
        data: {
          'html_url': data['html_url'],
          'clone_url': data['clone_url'],
          'full_name': data['full_name'],
        },
      );
    }

    if (resp.statusCode == 422) {
      // Уже существует
      return ConnectorResult.success(
        message: 'Репозиторий уже существует',
        data: {'html_url': 'https://github.com/$owner/$name'},
      );
    }

    return ConnectorResult.failure('GitHub create_repo: ${resp.statusCode} ${resp.body}');
  }

  Future<ConnectorResult> _uploadFile(Map<String, dynamic> params) async {
    final repo = params['repo'] as String;
    final path = params['path'] as String;
    final contentBase64 = params['contentBase64'] as String;
    final message = params['message'] as String? ?? 'Upload from Agent City';
    final branch = params['branch'] as String? ?? 'main';

    // Сначала проверяем, существует ли файл (нужен sha для обновления)
    String? sha;
    final getResp = await http.get(
      Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path?ref=$branch'),
      headers: _headers,
    );
    if (getResp.statusCode == 200) {
      sha = jsonDecode(getResp.body)['sha'] as String?;
    }

    final body = {
      'message': message,
      'content': contentBase64,
      'branch': branch,
      if (sha != null) 'sha': sha,
    };

    final resp = await http.put(
      Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path'),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final data = jsonDecode(resp.body);
      return ConnectorResult.success(
        message: 'Файл загружен',
        data: {
          'html_url': data['content']?['html_url'],
          'download_url': data['content']?['download_url'],
        },
      );
    }

    return ConnectorResult.failure('upload_file: ${resp.statusCode} ${resp.body}');
  }

  Future<ConnectorResult> _uploadZipAsRelease(Map<String, dynamic> params) async {
    final repo = params['repo'] as String;
    final zipPath = params['zipPath'] as String;
    final tag = params['tag'] as String? ?? 'v0.1.0-agent';
    final name = params['name'] as String? ?? 'Agent City build';

    final file = File(zipPath);
    if (!await file.exists()) {
      return ConnectorResult.failure('ZIP не найден: $zipPath');
    }

    // Создаём release
    final createResp = await http.post(
      Uri.parse('https://api.github.com/repos/$owner/$repo/releases'),
      headers: _headers,
      body: jsonEncode({
        'tag_name': tag,
        'name': name,
        'body': 'Automated release from Agent City',
        'draft': false,
        'prerelease': true,
      }),
    );

    Map<String, dynamic> release;
    if (createResp.statusCode == 201) {
      release = jsonDecode(createResp.body);
    } else {
      // Пробуем найти существующий
      final listResp = await http.get(
        Uri.parse('https://api.github.com/repos/$owner/$repo/releases'),
        headers: _headers,
      );
      if (listResp.statusCode != 200) {
        return ConnectorResult.failure('Не удалось создать/найти release: ${createResp.body}');
      }
      final releases = jsonDecode(listResp.body) as List;
      release = releases.firstWhere(
        (r) => r['tag_name'] == tag,
        orElse: () => null,
      );
      if (release == null) {
        return ConnectorResult.failure('Release не создан и не найден');
      }
    }

    final uploadUrlTemplate = release['upload_url'] as String;
    final uploadUrl = uploadUrlTemplate.replaceAll('{?name,label}', '');
    final fileName = p.basename(zipPath);
    final bytes = await file.readAsBytes();

    final uploadResp = await http.post(
      Uri.parse('$uploadUrl?name=$fileName'),
      headers: {
        ..._headers,
        'Content-Type': 'application/zip',
        'Content-Length': bytes.length.toString(),
      },
      body: bytes,
    );

    if (uploadResp.statusCode == 201) {
      final asset = jsonDecode(uploadResp.body);
      return ConnectorResult.success(
        message: 'ZIP загружен в Release',
        data: {
          'release_url': release['html_url'],
          'download_url': asset['browser_download_url'],
          'size': asset['size'],
        },
      );
    }

    return ConnectorResult.failure('Ошибка загрузки asset: ${uploadResp.statusCode} ${uploadResp.body}');
  }

  Future<ConnectorResult> _triggerWorkflow(Map<String, dynamic> params) async {
    final repo = params['repo'] as String;
    final workflow = params['workflow'] as String? ?? 'build_apk.yml';
    final ref = params['ref'] as String? ?? 'main';

    final resp = await http.post(
      Uri.parse('https://api.github.com/repos/$owner/$repo/actions/workflows/$workflow/dispatches'),
      headers: _headers,
      body: jsonEncode({'ref': ref}),
    );

    // 204 No Content = успех
    if (resp.statusCode == 204) {
      return ConnectorResult.success(
        message: 'Workflow $workflow запущен на $ref',
        data: {'repo': repo, 'workflow': workflow, 'ref': ref},
      );
    }

    return ConnectorResult.failure('trigger_workflow: ${resp.statusCode} ${resp.body}');
  }

  Future<ConnectorResult> _getWorkflowRuns(Map<String, dynamic> params) async {
    final repo = params['repo'] as String;
    final workflow = params['workflow'] as String? ?? 'build_apk.yml';
    final perPage = params['perPage'] as int? ?? 5;

    final resp = await http.get(
      Uri.parse(
        'https://api.github.com/repos/$owner/$repo/actions/workflows/$workflow/runs?per_page=$perPage',
      ),
      headers: _headers,
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final runs = (data['workflow_runs'] as List).map((r) {
        return {
          'id': r['id'],
          'status': r['status'],
          'conclusion': r['conclusion'],
          'html_url': r['html_url'],
          'created_at': r['created_at'],
        };
      }).toList();

      return ConnectorResult.success(
        message: 'Найдено запусков: ${runs.length}',
        data: {'runs': runs},
      );
    }

    return ConnectorResult.failure('get_workflow_runs: ${resp.statusCode} ${resp.body}');
  }
}