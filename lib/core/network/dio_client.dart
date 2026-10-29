import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import '../../app/config/env_config.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: EnvConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final storage = ref.read(secureStorageProvider);
        final token = await storage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final requestOptions = error.requestOptions;

        // Auto-refresh token on 401 Unauthorized (except for login & refresh-token endpoints)
        if (error.response?.statusCode == 401 &&
            !requestOptions.path.contains('/api/Auth/login') &&
            !requestOptions.path.contains('/api/Auth/refresh-token')) {
          final storage = ref.read(secureStorageProvider);
          final currentToken = await storage.getToken();
          final currentRefreshToken = await storage.getRefreshToken();

          if (currentToken != null && currentRefreshToken != null) {
            try {
              final refreshDio = Dio(
                BaseOptions(
                  baseUrl: EnvConfig.apiBaseUrl,
                  connectTimeout: const Duration(seconds: 10),
                  receiveTimeout: const Duration(seconds: 10),
                  headers: {'Content-Type': 'application/json'},
                ),
              );

              final refreshResponse = await refreshDio.post(
                '/api/Auth/refresh-token',
                data: {
                  'accessToken': currentToken,
                  'refreshToken': currentRefreshToken,
                },
              );

              if (refreshResponse.statusCode == 200 &&
                  refreshResponse.data != null) {
                final raw = refreshResponse.data as Map<String, dynamic>;
                final data = (raw['data'] ?? raw) as Map<String, dynamic>;
                final newAccessToken = data['accessToken'] as String?;
                final newRefreshToken = data['refreshToken'] as String?;

                if (newAccessToken != null && newRefreshToken != null) {
                  await storage.saveToken(newAccessToken);
                  await storage.saveRefreshToken(newRefreshToken);

                  // Update header and retry original request
                  requestOptions.headers['Authorization'] =
                      'Bearer $newAccessToken';
                  final retryResponse = await dio.fetch(requestOptions);
                  return handler.resolve(retryResponse);
                }
              }
            } catch (_) {
              // Refresh failed or revoked: clear stale token
              await storage.clearToken();
            }
          }
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});