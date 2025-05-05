import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_path_provider/android_path_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  double _downloadProgress = 0.0;
  bool _isDownloading = false;
  bool _isFetchingData = false;
  bool _isUrlValid = true;
  bool _showDownloadInfo = false;

  String? _title;
  String? _thumbnailUrl;
  int? _durationSeconds;
  List<Map<String, String>> _formats = [];
  String? _selectedFormatId;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    await [Permission.storage, Permission.manageExternalStorage].request();
  }

  Future<void> _fetchVideoInfo(String url) async {
    setState(() {
      _isFetchingData = true;
      _isUrlValid = true;
      _showDownloadInfo = false;
      _thumbnailUrl = null;
      _formats.clear();
      _title = null;
      _durationSeconds = null;
    });

    final uriRegExp = RegExp(
      r"^(https?\:\/\/)?(www\.youtube\.com|youtu\.?be)\/.+$",
    );

    if (!uriRegExp.hasMatch(url)) {
      setState(() {
        _isFetchingData = false;
        _isUrlValid = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid YouTube URL!')));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.108:8000/info'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'url': url},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Map<String, String>> fetchedFormats =
            List<Map<String, String>>.from(
              data['formats'].map((f) {
                return {
                  'id': f['format_id'].toString(),
                  'format': f['format'].toString(),
                  'resolution': f['resolution'].toString(),
                };
              }),
            );

        setState(() {
          _title = data['title'];
          _thumbnailUrl = data['thumbnail'];
          _durationSeconds = data['duration'];
          _formats = fetchedFormats;
          _selectedFormatId =
              fetchedFormats.isNotEmpty ? fetchedFormats.first['id'] : null;
          _showDownloadInfo = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Unable to fetch video info')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Network Error: $e')));
    } finally {
      setState(() => _isFetchingData = false);
    }
  }

  Future<void> _startDownload() async {
    if (_selectedFormatId == null || _urlController.text.trim().isEmpty) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    final url = _urlController.text.trim();
    final formatCode = _selectedFormatId!;
    final downloadUrl = 'http://192.168.0.108:8000/download';

    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }

      String? downloadsPath;
      if (Platform.isAndroid) {
        downloadsPath = await AndroidPathProvider.downloadsPath;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        downloadsPath = dir.path;
      }

      final savePath = '$downloadsPath/$_title.mp4';

      final dio = Dio();
      final response = await dio.post(
        downloadUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'accept': 'application/octet-stream',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
        data: {'url': url, 'format_code': formatCode},
        onReceiveProgress: (count, total) {
          setState(() {
            _downloadProgress = count / total;
          });
        },
      );

      final file = File(savePath);
      await file.writeAsBytes(response.data);

      setState(() => _isDownloading = false);

      // Show success snackbar without file path
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download successful!')));
    } catch (e) {
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'YT Downloader',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Enter YouTube URL',
                labelStyle: const TextStyle(color: Colors.green),
                errorText: _isUrlValid ? null : 'Invalid URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_urlController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _urlController.clear();
                          setState(() {
                            _showDownloadInfo = false;
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.green),
                      onPressed:
                          _isFetchingData
                              ? null
                              : () =>
                                  _fetchVideoInfo(_urlController.text.trim()),
                    ),
                  ],
                ),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 8),
            if (_isFetchingData)
              const CircularProgressIndicator()
            else if (_showDownloadInfo)
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_thumbnailUrl != null)
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _thumbnailUrl!,
                                  height: 200,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          if (_title != null)
                            Text(
                              _title!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (_durationSeconds != null)
                            Text(
                              'Duration: ${_formatDuration(_durationSeconds!)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _selectedFormatId,
                            decoration: InputDecoration(
                              labelText: 'Select Format',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items:
                                _formats.map((format) {
                                  final label =
                                      '${format['format']} (${format['resolution']})';
                                  return DropdownMenuItem(
                                    value: format['id'],
                                    child: Text(label),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFormatId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                iconColor: Colors.white,
                                backgroundColor: Colors.green[600],
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _isDownloading ? null : _startDownload,
                              icon: const Icon(Icons.download),
                              label: Text(
                                _isDownloading
                                    ? 'Downloading...'
                                    : 'Download', // Change label here
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          if (_isDownloading)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: LinearProgressIndicator(
                                value: _downloadProgress,
                                color: Colors.green,
                                backgroundColor: Colors.green[100],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
