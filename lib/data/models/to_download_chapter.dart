import 'manga_info_model.dart';

class ToDownloadChapter {
  final String chapterName;
  final String chapterUrl;
  final String mangaName;
  final String mangaUrl;
  final String mangaImageUrl;
  final String? mangaSource;
  ToDownloadChapter(this.mangaImageUrl, this.chapterName, this.chapterUrl,
      this.mangaName, this.mangaUrl, this.mangaSource);

  factory ToDownloadChapter.fromChapterList(ChapterList chapter,
          String mangaName, String mangaUrl, String imageUrl) =>
      ToDownloadChapter(imageUrl, chapter.chapterTitle, chapter.chapterUrl,
          mangaName, mangaUrl, chapter.mangaSource);
}
