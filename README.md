# Agent City

3D-город AI-агентов: задачи, сборка ZIP, деплой через GitHub Actions, уведомления.

## Быстрый старт

```bash
# 1. Распакуй архив
# 2. Создай платформы (один раз)
flutter create . --project-name agent_city --org com.agentcity --platforms=android,ios

# 3. Зависимости
flutter pub get

# 4. Иконки
dart run flutter_launcher_icons

# 5. (Опционально) инициализация flutter_scene
dart run flutter_scene:init || true

# 6. Запуск
flutter run
# или с GPU:
flutter run --enable-flutter-gpu
```

## Сборка APK на GitHub Actions

1. Запушь репозиторий на GitHub
2. Actions → **Build APK** → Run workflow
3. Скачай артефакт `agent-city-apk`

## API-ключи агентов

В приложении: шестерёнка → вставь ключ (Grok / OpenAI / Claude / Gemini / Ollama).

Для реального деплоя:
```bash
flutter run \
  --dart-define=GITHUB_TOKEN=ghp_xxx \
  --dart-define=GITHUB_OWNER=your-login
```

## Структура

- `lib/scene/city_scene.dart` — 3D город + fallback
- `lib/agents/` — Builder & Deployer
- `lib/connectors/` — GitHub, Supabase
- `.github/workflows/build_apk.yml` — сборка APK
