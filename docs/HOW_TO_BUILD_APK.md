# Как получить APK

## Способ 1 — GitHub Actions (рекомендуется)

1. Создай репозиторий на GitHub и запушь проект:
   ```bash
   git init
   git add .
   git commit -m "Agent City MVP"
   git branch -M main
   git remote add origin https://github.com/ТВОЙ_ЛОГИН/agent_city.git
   git push -u origin main
   ```

2. Зайди в репозиторий → вкладка **Actions**
3. Выбери workflow **Build APK** → **Run workflow**
4. После завершения скачай артефакт **agent-city-apk**

Готовый APK появится в разделе Artifacts.

## Способ 2 — Локально

```bash
flutter create . --project-name agent_city
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release
```

APK будет здесь:
`build/app/outputs/flutter-apk/app-release.apk`
