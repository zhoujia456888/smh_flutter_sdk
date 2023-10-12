import 'dart:io';

import 'package:smh_flutter_sdk/core/base/smh_services_manager.dart';
import 'package:smh_flutter_sdk/core/interceptors/smh_request_retrier.dart';
import 'package:dio/dio.dart';

class SMHRetryInterceptor extends QueuedInterceptorsWrapper {
  late SMHRequestRetrier requestRetrier;
  int retryCount = 3;
  SMHRetryInterceptor(this.requestRetrier);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (shouldRetry(err.type)) {
      Response? response;
      try {
        response = await _retry(
          err,
          retryCount,
        );
      } catch (e) {
        handler.reject(err);
      }
      if (response == null) {
        super.onError(err, handler);
      } else {
        handler.resolve(response);
      }
    } else {
      super.onError(err, handler);
    }
  }

  Future<Response?> _retry(DioError err, int retryCount) async {
    Response? response;
    for (int i = 0; i < retryCount; i++) {
      try {
        response = await Future.delayed(Duration(seconds: 5), () {
          return this.requestRetrier.scheduleRequestRetry(err.requestOptions);
        });
      } catch (e) {}
      if (response != null) {
        return response;
      }
    }
    return response;
  }

  static bool shouldRetry(DioExceptionType err) {
    bool isNoNet =
        (err == DioExceptionType.unknown && (err is SocketException));
    bool need = isNoNet || err == DioExceptionType.connectionTimeout;
    return need;
  }
}
