import 'package:flutter/foundation.dart';
import 'dart:collection';

class LogEntry {
  final String message;
  final String source;
  final DateTime timestamp;
  final LogLevel level;

  LogEntry({
    required this.message,
    required this.source,
    required this.timestamp,
    required this.level,
  });

  @override
  String toString() {
    return '[${level.name}] ${timestamp.toString()} - $source: $message';
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LogService {
  static final LogService _instance = LogService._internal();
  
  // Factory constructor
  factory LogService() {
    return _instance;
  }
  
  LogService._internal();
  
  // Maximum number of logs to keep in memory
  final int _maxLogs = 10000;
  
  // Log storage
  final ListQueue<LogEntry> _logs = ListQueue<LogEntry>();
  
  // Listeners for log updates
  final List<Function()> _listeners = [];
  
  // Write a log entry
  void log(String message, {
    LogLevel level = LogLevel.debug,
    String source = 'App',
  }) {
    final entry = LogEntry(
      message: message,
      source: source,
      timestamp: DateTime.now(),
      level: level,
    );
    
    // Add to queue
    _logs.add(entry);
    
    // Maintain max size
    if (_logs.length > _maxLogs) {
      _logs.removeFirst();
    }
    
    // Print to console in debug mode
    if (kDebugMode) {
      print('${entry.toString()}');
    }
    
    // Notify listeners
    _notifyListeners();
  }
  
  // Shorthand methods for different log levels
  void debug(String message, {String source = 'App'}) {
    log(message, level: LogLevel.debug, source: source);
  }
  
  void info(String message, {String source = 'App'}) {
    log(message, level: LogLevel.info, source: source);
  }
  
  void warning(String message, {String source = 'App'}) {
    log(message, level: LogLevel.warning, source: source);
  }
  
  void error(String message, {String source = 'App'}) {
    log(message, level: LogLevel.error, source: source);
  }
  
  // Get all logs
  List<LogEntry> getLogs() {
    return List.from(_logs);
  }
  
  // Clear all logs
  void clearLogs() {
    _logs.clear();
    _notifyListeners();
  }
  
  // Add listener
  void addListener(Function() listener) {
    _listeners.add(listener);
  }
  
  // Remove listener
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }
  
  // Notify listeners
  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
} 