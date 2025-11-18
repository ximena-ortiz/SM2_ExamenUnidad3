class EnvironmentConfig {
  // =========================
  // Flags de compilación
  // =========================
  // Usa el túnel (loca.lt) por defecto. Para usar localhost:
  // --dart-define=USE_TUNNEL=false
  static const bool _useTunnel = bool.fromEnvironment(
    'USE_TUNNEL',
    defaultValue: true,
  );

  // =========================
  // URLs base por defecto (ambas ramas)
  // =========================
  static const String _tunnelApiUrl   = 'https://115b1724cb70.ngrok-free.app/'; // <<<< HU-007-4
  static const String _localApiUrl    = 'http://localhost:3000';               // <<<< main

  // Elige por defecto según el flag _useTunnel (se puede sobreescribir con API_BASE_URL)
  static const String _defaultApiUrl  = _useTunnel ? _tunnelApiUrl : _localApiUrl;

  // Versión de API (se puede sobreescribir con API_VERSION)
  static const String _defaultApiVersion = 'api/v1';

  // =========================
  // Lectura de variables de entorno (con fallback)
  // =========================
  static String get apiBaseUrl {
    const url = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _defaultApiUrl,
    );
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get apiVersion {
    return const String.fromEnvironment(
      'API_VERSION',
      defaultValue: _defaultApiVersion,
    );
  }

  // =========================
  // URL completa
  // =========================
  static String get fullApiUrl => '$apiBaseUrl/$apiVersion';

  // =========================
  // Endpoints comunes
  // =========================
  static String get authEndpoint   => '$fullApiUrl/auth';
  static String get usersEndpoint  => '$fullApiUrl/users';
  static String get personsEndpoint=> '$fullApiUrl/persons';

  // Endpoints específicos
  static String get registerEndpoint     => '$fullApiUrl/auth/register';
  static String get loginEndpoint        => '$fullApiUrl/auth/login';
  static String get refreshTokenEndpoint => '$fullApiUrl/auth/refresh';

  // =========================
  // Flags de entorno
  // =========================
  static bool get isDevelopment {
    return const bool.fromEnvironment(
      'DEVELOPMENT_MODE',
      defaultValue: true,
    );
  }

  static bool get enableLogging {
    return const bool.fromEnvironment(
      'ENABLE_API_LOGGING',
      defaultValue: true,
    );
  }

  // =========================
  // Timeout
  // =========================
  static Duration get apiTimeout {
    const timeoutSeconds = int.fromEnvironment(
      'API_TIMEOUT_SECONDS',
      defaultValue: 30,
    );
    return Duration(seconds: timeoutSeconds);
  }

  // =========================
  // Log de configuración
  // =========================
  static void logConfiguration() {
    if (isDevelopment) {
      // ignore: avoid_print
      print('=== Environment Configuration ===');
      // ignore: avoid_print
      print('USE_TUNNEL: $_useTunnel');
      // ignore: avoid_print
      print('API Base URL: $apiBaseUrl');
      // ignore: avoid_print
      print('API Version: $apiVersion');
      // ignore: avoid_print
      print('Full API URL: $fullApiUrl');
      // ignore: avoid_print
      print('Development Mode: $isDevelopment');
      // ignore: avoid_print
      print('Enable Logging: $enableLogging');
      // ignore: avoid_print
      print('API Timeout: ${apiTimeout.inSeconds}s');
      // ignore: avoid_print
      print('================================');
    }
  }
}
