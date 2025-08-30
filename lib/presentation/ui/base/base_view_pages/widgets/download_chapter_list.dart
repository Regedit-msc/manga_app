import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_downloader/flutter_downloader.dart' as fd;
import 'package:timeago/timeago.dart' as timeago;
import 'dart:io';
import 'package:webcomic/data/common/constants/routes_constants.dart';
import 'package:webcomic/data/common/constants/size_constants.dart';
import 'package:webcomic/presentation/themes/colors.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloaded_cubit.dart';
import 'package:webcomic/presentation/ui/loading/no_animation_loading.dart';
import 'package:webcomic/data/services/debug/debug_logger.dart';
import 'package:webcomic/presentation/ui/other_pages/manga_reader/offline_reader.dart';

class DownloadChapterListView extends StatefulWidget {
  final DownloadedManga downloadedManga;
  const DownloadChapterListView({Key? key, required this.downloadedManga})
      : super(key: key);

  @override
  _DownloadChapterListViewState createState() =>
      _DownloadChapterListViewState();
}

class _DownloadChapterListViewState extends State<DownloadChapterListView> {
  ValueNotifier<List<dynamic>> chapters = ValueNotifier([]);
  late String appDir;

  @override
  void initState() {
    doSetup();
    super.initState();
  }

  Future<void> doSetup() async {
    // final dir = await getApplicationDocumentsDirectory();
    // print(dir.path);
    final dir = await context.read<DownloadedCubit>().getAppDir();
    setState(() {
      appDir = dir;
    });
    List<fd.DownloadTask>? getTasks =
        await fd.FlutterDownloader.loadTasksWithRawQuery(
            query:
                'SELECT * FROM  task WHERE saved_dir LIKE "%${widget.downloadedManga.mangaName}%" AND status=3');
    if (getTasks != null && getTasks.isNotEmpty) {
      // Group by savedDir and pick the newest task per chapter folder
      final Map<String, fd.DownloadTask> newestPerDir = {};
      for (final t in getTasks) {
        final existing = newestPerDir[t.savedDir];
        if (existing == null ||
            _safeCompareEpoch(t.timeCreated, existing.timeCreated) > 0) {
          newestPerDir[t.savedDir] = t;
        }
      }

      // Sort chapters by newest first
      final chapterList = newestPerDir.values.toList()
        ..sort((a, b) => _safeCompareEpoch(b.timeCreated, a.timeCreated));

      if (chapterList.isNotEmpty) {
        DebugLogger.logInfo('downloaded chapters loaded: ${chapterList.length}',
            category: 'Downloader');
        chapters.value = chapterList;
      }
    }
    ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.downloadedManga.mangaName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete All Chapters',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'storage_info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Storage Info'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ValueListenableBuilder(
          valueListenable: chapters,
          builder: (context, List<dynamic> value, child) {
            if (value.isEmpty) {
              return _buildEmptyState(context);
            }

            return Column(
              children: [
                // Storage info header
                _buildStorageHeader(context, value.length),

                // Chapter list
                Expanded(
                  child: ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      return _buildChapterCard(context, value[index], index);
                    },
                  ),
                ),
              ],
            );
          }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_done,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Downloaded Chapters',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download some chapters to read offline',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageHeader(BuildContext context, int chapterCount) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$chapterCount Chapter${chapterCount != 1 ? 's' : ''} Downloaded',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FutureBuilder<Map<String, dynamic>>(
                  future: context.read<DownloadedCubit>().getStorageInfo(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        'Storage: ${snapshot.data!['formattedSize']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      );
                    }
                    return const Text('Calculating storage...');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(BuildContext context, dynamic chapter, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8.0),
        leading: Container(
          width: Sizes.dimen_60,
          height: Sizes.dimen_60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              fadeInDuration: const Duration(microseconds: 100),
              imageUrl: widget.downloadedManga.imageUrl,
              fit: BoxFit.cover,
              placeholder: (ctx, string) {
                return Container(
                  width: Sizes.dimen_60,
                  height: Sizes.dimen_60,
                  child: NoAnimationLoading(),
                );
              },
            ),
          ),
        ),
        title: Text(
          _chapterTitleFromSavedDir(chapter.savedDir),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeago
                  .format(_dateTimeFromEpoch(chapter.timeCreated))
                  .replaceAll("ago", ""),
              style: const TextStyle(color: AppColor.violet),
            ),
            FutureBuilder<String>(
              future: _getChapterSize(chapter.savedDir),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(
                    'Size: ${snapshot.data}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleChapterAction(context, value, chapter),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'read',
              child: Row(
                children: [
                  Icon(Icons.menu_book),
                  SizedBox(width: 8),
                  Text('Read'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(context, Routes.offlineReader,
              arguments: OfflineReaderProps(
                  chapterDir: chapter.savedDir, manga: widget.downloadedManga));
        },
      ),
    );
  }

  Future<String> _getChapterSize(String chapterDir) async {
    try {
      final directory = Directory(chapterDir);
      if (!await directory.exists()) return '0 B';

      int totalSize = 0;
      final files = await directory.list(recursive: true).toList();
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size.toInt();
        }
      }

      return _formatBytes(totalSize);
    } catch (e) {
      return '0 B';
    }
  }

  String _formatBytes(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    if (bytes == 0) return '0 B';

    int i = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'delete_all':
        _showDeleteAllConfirmation(context);
        break;
      case 'storage_info':
        _showStorageInfo(context);
        break;
    }
  }

  void _handleChapterAction(
      BuildContext context, String action, dynamic chapter) {
    switch (action) {
      case 'read':
        Navigator.pushNamed(context, Routes.offlineReader,
            arguments: OfflineReaderProps(
                chapterDir: chapter.savedDir, manga: widget.downloadedManga));
        break;
      case 'delete':
        _showDeleteChapterConfirmation(context, chapter);
        break;
    }
  }

  void _showDeleteAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Chapters'),
          content: Text(
              'Are you sure you want to delete all downloaded chapters for "${widget.downloadedManga.mangaName}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAllChapters(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteChapterConfirmation(BuildContext context, dynamic chapter) {
    final chapterTitle = _chapterTitleFromSavedDir(chapter.savedDir);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Chapter'),
          content: Text(
              'Are you sure you want to delete "$chapterTitle"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteChapter(context, chapter);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showStorageInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Storage Information'),
          content: FutureBuilder<Map<String, dynamic>>(
            future: context.read<DownloadedCubit>().getStorageInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Calculating storage usage...'),
                  ],
                );
              }

              if (snapshot.hasError) {
                return const Text('Failed to calculate storage usage.');
              }

              final data = snapshot.data!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Downloads: ${data['chapterCount']} chapters'),
                  const SizedBox(height: 8),
                  Text('Storage Used: ${data['formattedSize']}'),
                  const SizedBox(height: 8),
                  Text('Manga: ${widget.downloadedManga.mangaName}'),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteChapter(BuildContext context, dynamic chapter) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final success = await context.read<DownloadedCubit>().deleteChapter(
            mangaName: widget.downloadedManga.mangaName,
            chapterDir: chapter.savedDir,
          );

      if (success) {
        // Refresh the chapter list
        await doSetup();
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Chapter deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to delete chapter'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while deleting'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAllChapters(BuildContext context) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final success = await context.read<DownloadedCubit>().deleteManga(
            mangaName: widget.downloadedManga.mangaName,
            mangaUrl: widget.downloadedManga.mangaUrl,
          );

      if (success) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('All chapters deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate back since there are no more chapters
        Navigator.of(context).pop();
      } else {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to delete chapters'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while deleting'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

String _chapterTitleFromSavedDir(String savedDir) {
  try {
    // Use last path segment, prefer number after the final '-' (our dir naming pattern)
    final tail =
        savedDir.split('/').isNotEmpty ? savedDir.split('/').last : savedDir;

    String? pickNumber(String s) {
      // First, try suffix after last dash (e.g., Manga-12 or Manga-12.5)
      final dashIdx = s.lastIndexOf('-');
      if (dashIdx != -1 && dashIdx + 1 < s.length) {
        final suffix = s.substring(dashIdx + 1);
        final cleaned = suffix.replaceAll(RegExp(r'[^0-9\._]'), '');
        final normalized = cleaned.replaceAll('_', '.');
        if (RegExp(r'^\d+(?:\.\d+)?$').hasMatch(normalized)) {
          return normalized;
        }
      }
      // Fallback: search anywhere for first decimal/integer occurrence
      final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(s);
      return m?.group(1);
    }

    final numStr = pickNumber(tail);
    if (numStr != null && numStr.isNotEmpty) {
      // Pretty print: trim trailing .0 if present
      final asNum = double.tryParse(numStr);
      if (asNum != null) {
        final pretty =
            asNum % 1 == 0 ? asNum.toInt().toString() : asNum.toString();
        return 'Chapter $pretty';
      }
      return 'Chapter $numStr';
    }
  } catch (_) {}
  return 'Chapter';
}

// Safely convert an epoch (seconds/millis/micros) to DateTime
DateTime _dateTimeFromEpoch(int epoch) {
  // Heuristic thresholds for units
  if (epoch > 100000000000000) {
    // > 1e14 -> microseconds
    return DateTime.fromMicrosecondsSinceEpoch(epoch);
  } else if (epoch > 100000000000) {
    // > 1e11 -> milliseconds
    return DateTime.fromMillisecondsSinceEpoch(epoch);
  } else {
    // assume seconds
    return DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
  }
}

// Compare two epoch values regardless of unit by normalizing via DateTime
int _safeCompareEpoch(int a, int b) {
  final da = _dateTimeFromEpoch(a);
  final db = _dateTimeFromEpoch(b);
  return da.compareTo(db);
}
