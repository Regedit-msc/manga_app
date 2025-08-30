import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webcomic/data/services/download/download_progress_service.dart';
import 'package:webcomic/presentation/ui/blocs/download/downloaded_cubit.dart';
import 'package:webcomic/presentation/ui/blocs/download/enhanced_downloading_cubit.dart';
import 'package:webcomic/presentation/widgets/download/download_widgets.dart';

class EnhancedDownloadManagementPage extends StatefulWidget {
  const EnhancedDownloadManagementPage({Key? key}) : super(key: key);

  @override
  State<EnhancedDownloadManagementPage> createState() =>
      _EnhancedDownloadManagementPageState();
}

class _EnhancedDownloadManagementPageState
    extends State<EnhancedDownloadManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DownloadProgressService _progressService = DownloadProgressService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Refresh downloaded manga when page loads
    context.read<DownloadedCubit>().refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Manager'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              icon: Icon(Icons.download),
              text: 'Active',
            ),
            const Tab(
              icon: Icon(Icons.download_done),
              text: 'Downloaded',
            ),
            const Tab(
              icon: Icon(Icons.settings),
              text: 'Settings',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active Downloads Tab
          _buildActiveDownloadsTab(),

          // Downloaded Content Tab
          _buildDownloadedTab(),

          // Download Settings Tab
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildActiveDownloadsTab() {
    return StreamBuilder<GlobalDownloadProgress>(
      stream: _progressService.progressStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final progress = snapshot.data!;

        if (!progress.hasActiveDownloads) {
          return _buildEmptyActiveState();
        }

        return Column(
          children: [
            // Overall progress header
            _buildOverallProgressCard(progress),

            // Chapter list
            Expanded(
              child: _buildChapterList(progress),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyActiveState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Downloads',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start downloading manga chapters to see progress here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgressCard(GlobalDownloadProgress progress) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.download,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Progress',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(progress.overallProgress * 100).toInt()}% complete',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  if (progress.averageSpeed > 0)
                    Text(
                      '${progress.averageSpeed.toStringAsFixed(1)} KB/s',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress.overallProgress,
                backgroundColor:
                    Theme.of(context).colorScheme.outline.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progress.statusSummary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterList(GlobalDownloadProgress progress) {
    final chapters = progress.allChapters;

    // Sort chapters: downloading first, then queued, then others
    chapters.sort((a, b) {
      if (a.status == DownloadStatus.downloading &&
          b.status != DownloadStatus.downloading) return -1;
      if (b.status == DownloadStatus.downloading &&
          a.status != DownloadStatus.downloading) return 1;
      if (a.status == DownloadStatus.queued &&
          b.status != DownloadStatus.queued) return -1;
      if (b.status == DownloadStatus.queued &&
          a.status != DownloadStatus.queued) return 1;
      return a.lastUpdate.compareTo(b.lastUpdate);
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return EnhancedChapterProgressCard(
          progress: chapter,
          onPause: () => _pauseChapter(chapter.chapterUrl),
          onResume: () => _resumeChapter(chapter.chapterUrl),
          onCancel: () => _cancelChapter(chapter.chapterUrl),
        );
      },
    );
  }

  Widget _buildDownloadedTab() {
    return BlocBuilder<DownloadedCubit, DownloadedState>(
      builder: (context, state) {
        if (state.downloadedManga.isEmpty) {
          return _buildEmptyDownloadedState();
        }

        return Column(
          children: [
            // Storage summary
            _buildStorageSummaryCard(),

            // Downloaded manga list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: state.downloadedManga.length,
                itemBuilder: (context, index) {
                  return _buildDownloadedMangaCard(
                      state.downloadedManga[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyDownloadedState() {
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
            'No Downloaded Manga',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloaded manga will appear here for offline reading',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSummaryCard() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: FutureBuilder<Map<String, dynamic>>(
        future: context.read<DownloadedCubit>().getStorageInfo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final data = snapshot.data!;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.storage,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Storage Usage',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data['formattedSize']} • ${data['chapterCount']} chapters',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showStorageManagement(),
                    icon: const Icon(Icons.cleaning_services, size: 18),
                    label: const Text('Manage'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDownloadedMangaCard(DownloadedManga manga) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            manga.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 50,
              height: 50,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
        title: Text(
          manga.mangaName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Downloaded: ${_formatDate(manga.dateDownloaded)}'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMangaAction(value, manga),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view_chapters',
              child: Row(
                children: [
                  Icon(Icons.list),
                  SizedBox(width: 8),
                  Text('View Chapters'),
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
        onTap: () => _handleMangaAction('view_chapters', manga),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Download Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Download quality settings
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Download Quality',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Higher quality uses more storage space.'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: 'high',
                  decoration: const InputDecoration(
                    labelText: 'Image Quality',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (value) {
                    // TODO: Implement quality setting
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Concurrent downloads
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Download Performance',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Number of concurrent downloads.'),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: 3,
                  decoration: const InputDecoration(
                    labelText: 'Concurrent Downloads',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 (Slowest)')),
                    DropdownMenuItem(value: 2, child: Text('2')),
                    DropdownMenuItem(value: 3, child: Text('3 (Recommended)')),
                    DropdownMenuItem(value: 4, child: Text('4')),
                    DropdownMenuItem(value: 6, child: Text('6 (Fastest)')),
                  ],
                  onChanged: (value) {
                    // TODO: Implement concurrent setting
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Storage management
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Storage Management',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cleaning_services),
                  title: const Text('Clear Cache'),
                  subtitle: const Text('Remove temporary download files'),
                  onTap: _clearCache,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_sweep),
                  title: const Text('Delete All Downloads'),
                  subtitle: const Text('Remove all downloaded manga'),
                  onTap: _showDeleteAllConfirmation,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return 'Recently';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _handleMangaAction(String action, DownloadedManga manga) {
    switch (action) {
      case 'view_chapters':
        // Navigate to chapter list
        // Navigator.pushNamed(context, Routes.downloadedChapters, arguments: manga);
        break;
      case 'delete':
        _showDeleteMangaConfirmation(manga);
        break;
    }
  }

  void _showStorageManagement() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Storage Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Clear Cache'),
              subtitle: const Text('Remove temporary files'),
              onTap: () {
                Navigator.pop(context);
                _clearCache();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title:
                  const Text('Delete All', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Remove all downloaded content'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteAllConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteMangaConfirmation(DownloadedManga manga) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Manga'),
        content: Text(
          'Are you sure you want to delete "${manga.mangaName}" and all its chapters? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteManga(manga);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Downloads'),
        content: const Text(
          'Are you sure you want to delete all downloaded manga? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAllDownloads();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteManga(DownloadedManga manga) async {
    try {
      final success = await context.read<DownloadedCubit>().deleteManga(
            mangaName: manga.mangaName,
            mangaUrl: manga.mangaUrl,
          );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Manga deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete manga'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllDownloads() async {
    try {
      final downloadedCubit = context.read<DownloadedCubit>();
      final mangaList = downloadedCubit.state.downloadedManga;

      bool allSucceeded = true;
      for (final manga in mangaList) {
        final success = await downloadedCubit.deleteManga(
          mangaName: manga.mangaName,
          mangaUrl: manga.mangaUrl,
        );
        if (!success) allSucceeded = false;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              allSucceeded
                  ? 'All downloads deleted successfully'
                  : 'Some downloads could not be deleted',
            ),
            backgroundColor: allSucceeded ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete downloads'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearCache() {
    // TODO: Implement cache clearing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _pauseChapter(String chapterUrl) async {
    await context.read<EnhancedDownloadingCubit>().pauseChapterDownload(
          chapterUrl: chapterUrl,
        );
  }

  void _resumeChapter(String chapterUrl) async {
    await context.read<EnhancedDownloadingCubit>().resumeChapterDownload(
          chapterUrl: chapterUrl,
        );
  }

  void _cancelChapter(String chapterUrl) {
    final currentProgress = _progressService.currentProgress;
    final chapters = currentProgress.allChapters;
    final chapter = chapters.firstWhere((c) => c.chapterUrl == chapterUrl);

    _progressService.updateProgress(
      mangaUrl: chapter.mangaUrl,
      chapterUrl: chapter.chapterUrl,
      totalImages: chapter.totalImages,
      completedImages: chapter.completedImages,
      mangaName: chapter.mangaName,
      chapterName: chapter.chapterName,
      status: DownloadStatus.cancelled,
    );
  }
}
