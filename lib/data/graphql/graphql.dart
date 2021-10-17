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
      genres{
        genreUrl
        genre
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

const MOST_VIEWED = '''
query MostViewed {
  getMostViewedManga {
    message
    success
    data {
      mangaUrl
      imageUrl
      title
      status
    }
  }
}
''';

const MOST_CLICKED = '''
query MostClicked {
  getMostClickedManga {
    message
    success
    data {
      mangaUrl
      imageUrl
      title
      score
    }
  }
}

''';
