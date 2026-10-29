enum Environment { development, staging, production }

class EnvConfig {
  static const String _env =
      String.fromEnvironment('ENV', defaultValue: 'development');

  static Environment get currentEnvironment {
    switch (_env) {
      case 'production':
        return Environment.production;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.development;
    }
  }

  static String get apiBaseUrl {
    switch (currentEnvironment) {
      case Environment.production:
        return 'https://edubook.runasp.net';
      case Environment.staging:
        return 'https://edubook.runasp.net';
      case Environment.development:
        return 'https://edubook.runasp.net';
    }
  }
}