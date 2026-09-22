import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorageService _storage;
  bool _isRefreshing = false;

  ApiClient({required this._storage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Platform': ApiConstants.platform,
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = error.response?.statusCode;

    if (statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final currentToken = await _storage.getToken();
        if (currentToken == null) {
          _isRefreshing = false;
          handler.reject(error);
          return;
        }

        final refreshResponse = await _dio.post(
          ApiConstants.refresh,
          options: Options(headers: {'Authorization': 'Bearer $currentToken'}),
        );

        final newToken = refreshResponse.data['access_token'] as String?;
        if (newToken != null) {
          await _storage.saveToken(newToken);
          error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(error.requestOptions);
          _isRefreshing = false;
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {
        await _storage.deleteAll();
      }
      _isRefreshing = false;
    }

    handler.reject(error);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _request(() => _dio.get(
            path,
            queryParameters: queryParameters,
            options: options,
          ));

  Future<Response> post(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _request(() => _dio.post(path, data: data, options: options));

  Future<Response> put(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _request(() => _dio.put(path, data: data, options: options));

  Future<Response> patch(
    String path, {
    dynamic data,
    Options? options,
  }) =>
      _request(() => _dio.patch(path, data: data, options: options));

  Future<Response> delete(String path, {dynamic data}) =>
      _request(() => _dio.delete(path, data: data));

  Future<Response> _request(Future<Response> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final message = (data is Map ? data['message'] : null) as String? ??
        'Erro de comunicação com o servidor.';

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.unknown) {
      return const NetworkException();
    }

    switch (statusCode) {
      case 401:
        return AuthException(message);
      case 403:
        return AuthException(message);
      case 422:
        final errors = data is Map ? data['errors'] as Map<String, dynamic>? : null;
        return ValidationException(message, errors: errors);
      default:
        return ServerException(message, statusCode: statusCode);
    }
  }
}
