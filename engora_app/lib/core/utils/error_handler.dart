import 'dart:io';
import 'package:dio/dio.dart';

/// Centralised error-to-message converter used across all providers.
class ErrorHandler {
  ErrorHandler._();

  /// Returns a human-readable message from any thrown object.
  static String message(Object error) {
    if (error is DioException) return _fromDio(error);
    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    }
    if (error is FormatException) {
      return 'Received an unexpected response from the server.';
    }
    return 'Something went wrong. Please try again.';
  }

  static String _fromDio(DioException e) {
    // Network errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Connection timed out. Check your internet and try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to connect to the server. Check your network.';
    }

    // HTTP status code errors
    final status = e.response?.statusCode;
    if (status != null) {
      // Try to extract server message first
      final serverMsg = _extractServerMessage(e.response?.data);
      if (serverMsg != null) return serverMsg;

      return switch (status) {
        400 => 'Invalid request. Please check your input.',
        401 => 'Your session has expired. Please log in again.',
        403 => 'You don\'t have permission to do this.',
        404 => 'The requested resource was not found.',
        409 => 'This account already exists.',
        422 => 'Invalid data provided. Please check your input.',
        429 => 'Too many requests. Please wait a moment.',
        500 => 'Server error. Please try again later.',
        502 || 503 => 'Service is temporarily unavailable.',
        _ => 'Request failed (HTTP $status).',
      };
    }

    return 'Something went wrong. Please try again.';
  }

  static String? _extractServerMessage(dynamic data) {
    if (data is Map) {
      // Common patterns: { message: "..." }, { error: "..." }
      for (final key in ['message', 'error', 'detail', 'msg']) {
        final val = data[key];
        if (val is String && val.isNotEmpty) return val;
        if (val is List && val.isNotEmpty && val.first is String) {
          return val.cast<String>().join(', ');
        }
      }
    }
    return null;
  }

  /// Returns true if error is a network connectivity issue.
  static bool isNetworkError(Object error) {
    if (error is SocketException) return true;
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout;
    }
    return false;
  }

  /// Returns true if the error is an auth failure (401).
  static bool isAuthError(Object error) {
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    return false;
  }
}
