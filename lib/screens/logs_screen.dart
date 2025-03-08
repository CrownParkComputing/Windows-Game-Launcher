import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/log_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({Key? key}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final LogService _logService = LogService();
  late ScrollController _scrollController;
  LogLevel _filterLevel = LogLevel.debug;
  String _searchQuery = '';
  bool _autoScroll = true;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _logService.addListener(_onLogsUpdated);
  }
  
  @override
  void dispose() {
    _logService.removeListener(_onLogsUpdated);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onLogsUpdated() {
    if (_autoScroll && _scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
    
    if (mounted) {
      setState(() {});
    }
  }
  
  List<LogEntry> _getFilteredLogs() {
    final logs = _logService.getLogs();
    return logs.where((log) {
      // Filter by level
      if (log.level.index < _filterLevel.index) {
        return false;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        return log.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               log.source.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      
      return true;
    }).toList();
  }
  
  Color _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  void _exportLogs() async {
    final logs = _logService.getLogs();
    final String logText = logs.map((log) => log.toString()).join('\n');
    
    await Clipboard.setData(ClipboardData(text: logText));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logs copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Logs'),
        actions: [
          IconButton(
            icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center),
            tooltip: _autoScroll ? 'Auto-scroll enabled' : 'Auto-scroll disabled',
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy logs to clipboard',
            onPressed: _exportLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Clear logs',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Logs'),
                  content: const Text('Are you sure you want to clear all logs?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        _logService.clearLogs();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildToolbar(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: filteredLogs.length,
              itemBuilder: (context, index) {
                final log = filteredLogs[index];
                return _buildLogItem(log);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildToolbar() {
    final filteredLogs = _getFilteredLogs();
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[200],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search logs...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8.0),
              DropdownButton<LogLevel>(
                value: _filterLevel,
                onChanged: (value) {
                  setState(() {
                    _filterLevel = value!;
                  });
                },
                items: LogLevel.values.map((level) {
                  return DropdownMenuItem<LogLevel>(
                    value: level,
                    child: Text(
                      level.name.toUpperCase(),
                      style: TextStyle(
                        color: _getLogColor(level),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${filteredLogs.length} logs'),
              Text('Filter: ${_filterLevel.name.toUpperCase()}'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLogItem(LogEntry log) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: _getLogColor(log.level).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                decoration: BoxDecoration(
                  color: _getLogColor(log.level),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  log.level.name.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                log.source,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              Text(
                '${log.timestamp.hour}:${log.timestamp.minute}:${log.timestamp.second}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(log.message),
        ],
      ),
    );
  }
} 