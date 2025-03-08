import 'package:flutter/foundation.dart';
import 'log_service.dart';

/// A utility class that replaces debugPrint with a more advanced logging system
class Logger {
  static final LogService _logService = LogService();
  
  /// Logs a debug message
  static void debug(String message, {String source = 'App'}) {
    _logService.debug(message, source: source);
    
    // Still output to console in debug mode for development convenience
    if (kDebugMode) {
      debugPrint('[DEBUG] $source: $message');
    }
  }
  
  /// Logs an info message
  static void info(String message, {String source = 'App'}) {
    _logService.info(message, source: source);
    
    // Still output to console in debug mode for development convenience
    if (kDebugMode) {
      debugPrint('[INFO] $source: $message');
    }
  }
  
  /// Logs a warning message
  static void warning(String message, {String source = 'App'}) {
    _logService.warning(message, source: source);
    
    // Still output to console in debug mode for development convenience
    if (kDebugMode) {
      debugPrint('[WARNING] $source: $message');
    }
  }
  
  /// Logs an error message
  static void error(String message, {String source = 'App'}) {
    _logService.error(message, source: source);
    
    // Still output to console in debug mode for development convenience
    if (kDebugMode) {
      debugPrint('[ERROR] $source: $message');
    }
  }
} 