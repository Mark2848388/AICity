# Agent City — MVP Scope (v0.1)

**Цель MVP:** работающий прототип, в котором можно видеть 3D-город с агентами, давать им задачи, наблюдать выполнение и получать уведомления о результате. Одна реальная "полезная" задача — сборка простого Flutter-проекта в ZIP + триггер GitHub Actions для APK.

## Что входит в MVP

### 1. 3D-город (визуализация)
- Базовая сцена на `flutter_scene`: земля + 4–6 зданий (простые кубы / low-poly glTF).
- 2–3 агента-манекена (простые человечки или цветные капсулы), которые перемещаются между зданиями.
- Камера: orbit + zoom (можно мышью/тачем).
- Над каждым агентом — имя + текущий статус (Idle / Working / Done / Error).
- Клик по агенту → открывает панель с его текущей задачей и логом.

### 2. Система задач (Task System)
- Модель `Task`: id, title, description, status (pending/running/completed/failed), assignedAgentId, createdAt, startedAt, finishedAt, progress (0–100), estimatedDuration, result, error.
- Очередь задач + возможность запускать несколько параллельно (лимит 2–3).
- Долгосрочные задачи: сохранение состояния в локальное хранилище (Hive / shared_preferences + JSON) + возможность возобновления.
- Простая оценка ETA на основе типа задачи.

### 3. Агенты (1–2 простых)
- **BuilderAgent** — умеет:
  - Создать минимальный Flutter-проект (pubspec + main.dart).
  - Упаковать его в ZIP.
  - Сохранить ZIP локально / в documents.
- **DeployerAgent** — умеет:
  - Загрузить ZIP на GitHub (через GitHub API, создать репозиторий или закоммитить в существующий).
  - Триггернуть GitHub Actions workflow для сборки APK.
  - Вернуть ссылку на артефакт / статус workflow.
- Агенты работают через tool-calling (на MVP можно mock + реальный LLM через Genkit/OpenAI/Grok API).
- Логи действий агента пишутся в Task и отображаются в UI.

### 4. GitHub Actions + tool «собрать и залить»
- Готовый workflow `.github/workflows/build_apk.yml`:
  - checkout → setup Flutter → `flutter build apk --release` → upload-artifact.
- Tool у DeployerAgent: `trigger_apk_build(repo, branch)` + `get_workflow_status(run_id)`.
- Результат: APK как artifact + ссылка.

### 5. Push-уведомления + долгосрочные задачи
- Интеграция Firebase Cloud Messaging (FCM) — минимум.
- При смене статуса задачи на `completed` / `failed` — локальное уведомление + (если настроено) push.
- Долгосрочные задачи переживают перезапуск приложения (через persistent storage).

## Что НЕ входит в MVP (откладываем)
- Полноценный LLM-оркестратор с планированием (пока жёсткая логика + 1–2 tools).
- Красивые 3D-модели людей / анимации ходьбы (только манекены).
- Реальная физика / pathfinding (агенты телепортируются или едут по прямым).
- Supabase (можно добавить позже как storage для ZIP и задач).
- Мультипользователь / аккаунты.
- Web-версия (фокус на mobile + desktop).
- Полный редактор города.

## Критерии готовности MVP
1. Запускается на Android / macOS / Windows.
2. Виден 3D-город с 2+ агентами.
3. Можно создать задачу «Собрать тестовое Flutter-приложение».
4. BuilderAgent создаёт ZIP.
5. DeployerAgent (или тот же) заливает на GitHub и запускает Actions (или mock, если нет токена).
6. При завершении/ошибке приходит уведомление.
7. Состояние задач сохраняется между запусками.

## Технологии MVP
- Flutter (stable / main channel для flutter_scene)
- `flutter_scene` + `vector_math`
- `hive` или `shared_preferences` + json для persistence
- `http` / `dio` для GitHub API
- `firebase_messaging` + `flutter_local_notifications`
- Genkit Dart (опционально, для tool-calling) или простой mock-агент
- GitHub Actions

---
*Дата фиксации: 24 ноября 2026*