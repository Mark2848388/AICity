# Agent City 🏙️🤖

**3D-город AI-агентов**, которые выполняют приказы, собирают Flutter-проекты в ZIP, заливают на GitHub и запускают сборку APK через GitHub Actions.

## MVP (v0.1)

См. подробный скоуп: [`docs/MVP_SCOPE.md`](docs/MVP_SCOPE.md)

### Что уже есть в каркасе

- ✅ Модели `Task` и `Agent`
- ✅ `TaskService` с persistence (Hive) + поддержка долгосрочных задач
- ✅ `BuilderAgent` — создаёт минимальный Flutter-проект и ZIP
- ✅ `DeployerAgent` — заливка на GitHub + триггер Actions (или mock)
- ✅ GitHub Actions workflow для APK
- ✅ Локальные push-уведомления (flutter_local_notifications)
- ✅ UI: панель задач, статусы, логи
- ✅ **3D-модели города** прямо сейчас:
  - Земля (Plane)
  - Дороги (Cuboid)
  - 8 зданий с крышами (Cuboid разного цвета и высоты)
  - 3 агента: капсула-тело + сфера-голова + цветной статус-индикатор
  - Орбитальная камера + мини-карта агентов + graceful fallback

## Быстрый старт

```bash
# 1. Создай Flutter-проект на базе этого каркаса (или скопируй файлы)
flutter create . --project-name agent_city
# (или просто используй существующую структуру)

# 2. Установи зависимости
flutter pub get

# 3. Инициализация flutter_scene (обязательно для настоящей 3D)
dart run flutter_scene:init

# 4. Запуск
flutter run --enable-flutter-gpu   # desktop / mobile
```

### Переменные окружения (коннекторы)

```bash
flutter run \
  --dart-define=GITHUB_TOKEN=ghp_xxxxx \
  --dart-define=GITHUB_OWNER=your-username \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ...
```

### Коннекторы (`lib/connectors/`)

| Коннектор   | Действия                                                                 |
|-------------|--------------------------------------------------------------------------|
| **github**  | `create_repo`, `upload_file`, `upload_zip_as_release`, `trigger_workflow`, `get_workflow_runs` |
| **supabase**| `upload_file`, `get_public_url`, `save_task`, `list_tasks`               |

Агенты вызывают через `ConnectorRegistry.instance.get('github')!.execute('trigger_workflow', {...})`.  
Все tools для LLM: `ConnectorRegistry.instance.allActionsAsTools`.

## Структура

```
lib/
  models/          # Task, Agent
  agents/          # BuilderAgent, DeployerAgent
  services/        # TaskService, NotificationService
  connectors/      # GitHub + Supabase + базовый реестр
  scene/           # CityScene (flutter_scene)
  ui/              # TaskPanel и другие виджеты
  main.dart
.github/workflows/ # build_apk.yml
docs/MVP_SCOPE.md
```

## Следующие шаги после MVP

1. Полноценная 3D-сцена с glTF-зданиями и анимированными агентами.
2. Настоящий LLM-оркестратор (Genkit Dart + tool-calling).
3. Supabase как backend для задач и storage ZIP.
4. Pathfinding агентов по городу.
5. Больше специализированных агентов (Researcher, Tester, Designer...).

## Лицензия

MIT (или как решишь).
```
---

## Запуск на телефоне (Android / iOS)

```bash
# После flutter create .
flutter run          # подключённый телефон / эмулятор
# или
flutter build apk --release
```

### Уведомления на телефоне

Локальные уведомления работают **сразу**:
- При завершении задачи
- При ошибке
- Когда APK готов (после GitHub Actions)

При первом запуске Android 13+ / iOS попросит разрешение — разреши.

### Настоящие Push (FCM) — опционально

1. Создай проект на [Firebase Console](https://console.firebase.google.com)
2. Добавь Android/iOS приложение
3. Скачай `google-services.json` / `GoogleService-Info.plist`
4. Раскомментируй `firebase_messaging` в `pubspec.yaml`
5. Добавь инициализацию FCM в `main.dart`

Пока без Firebase уже приходят локальные уведомления (даже когда приложение в фоне на большинстве устройств).

### GitHub Actions + Deployer

DeployerAgent теперь:
1. Создаёт репо
2. Заливает ZIP
3. Триггерит `build_apk.yml`
4. **Ждёт** завершения сборки (до 10 мин)
5. Присылает **уведомление «APK готов»** со ссылкой на Actions (где лежит артефакт)


---

## Иконка приложения

Иконка уже лежит в проекте: `assets/icon/app_icon.jpg`

После `flutter create .` сгенерируй иконки для Android/iOS:

```bash
flutter pub get
dart run flutter_launcher_icons
```

Это создаст все нужные размеры в `android/` и `ios/`.
