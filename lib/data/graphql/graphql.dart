const String GET_NEWEST_MANGA = '''
query NewestManga {
  getNewestManga {
    message
    success
    data {
      title
      mangaUrl
      imageUrl
    }
  }
}
''';

const String GET_MANGA_INFO = '''
query MangaInfo(\$mangaUrl: String!) {
  getMangaInfo(mangaUrl: \$mangaUrl) {
    message
    success
    data {
      mangaImage
      author
      chapterNo
      views
      status
      description
      summary
      chapterList {
        chapterUrl
        chapterTitle
        dateUploaded
      }
    }
  }
}

''';

const String MANGA_READER = '''
query MangaReader(\$chapterUrl: String!) {
  getMangaReader(chapterUrl: \$chapterUrl) {
    message
    success
    data {
      chapter
      images
    }
  }
}
''';

const MANGA_SEARCH = '''
query MangaSearch(\$term: String!) {
  mangaSearch(term: \$term) {
    message
    success
    data {
      mangaUrl
      title
      imageUrl
    }
  }
}
''';
