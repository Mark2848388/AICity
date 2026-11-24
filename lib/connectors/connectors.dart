import 'github/github_connector.dart';
import 'supabase/supabase_connector.dart';
import 'connector.dart';

export 'connector.dart';
export 'github/github_connector.dart';
export 'supabase/supabase_connector.dart';

/// Инициализация всех коннекторов.
/// Вызывать один раз при старте приложения.
///
/// Токены лучше брать из:
/// - --dart-define=GITHUB_TOKEN=...
/// - или из secure storage / .env
void initConnectors({
  String? githubToken,
  String? githubOwner,
  String? supabaseUrl,
  String? supabaseAnonKey,
  String? supabaseServiceKey,
}) {
  final registry = ConnectorRegistry.instance;

  // GitHub
  registry.register(GitHubConnector(
    token: githubToken ?? const String.fromEnvironment('GITHUB_TOKEN'),
    owner: githubOwner ?? const String.fromEnvironment('GITHUB_OWNER'),
  ));

  // Supabase
  registry.register(SupabaseConnector(
    url: supabaseUrl ?? const String.fromEnvironment('SUPABASE_URL'),
    anonKey: supabaseAnonKey ?? const String.fromEnvironment('SUPABASE_ANON_KEY'),
    serviceKey: supabaseServiceKey ?? const String.fromEnvironment('SUPABASE_SERVICE_KEY'),
  ));

  // Позже сюда добавим:
  // - FcmConnector
  // - TelegramConnector
  // - GenericHttpConnector
}