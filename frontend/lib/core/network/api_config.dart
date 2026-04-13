abstract final class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'VRATA_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.endsWith('/')) {
      return _configuredBaseUrl.substring(0, _configuredBaseUrl.length - 1);
    }

    return _configuredBaseUrl;
  }
}
