const String GET_NEWEST_MANGA = '''
query NewestManga {
  getNewestManga {
    message
    success
    data {
      title
      mangaUrl
      imageUrl
      mangaSource
    }
  }
}
''';

const String GET_MANGA_INFO = '''
query MangaInfo(\$source: String!, \$mangaUrl: String!,) {
  getMangaInfo(source:\$source, mangaUrl:\$mangaUrl) {
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
      recommendations{
        title
        mangaUrl
        mangaImage
      }
      chapterList {
        chapterUrl
        chapterTitle
        dateUploaded
      }
      genres{
        genreUrl
        genre
      }
      mangaSource
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
      chapterList
      mangaSource
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
      mangaSource
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
      mangaSource
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
      mangaSource
    }
  }
}

''';

const MANGA_BY_GENRE = '''
query MangaByGenre(\$source: String!,\$genreUrl: String!) {
  getMangaByGenre(source: \$source,genreUrl: \$genreUrl) {
    message
    success
    data {
      mangaUrl
      mangaTitle
      mangaImage
      author
      summary
      stats
      mangaSource
    }
  }
}
''';

const ADD_TOKEN = '''
mutation AddToken(\$token: String!, \$userId: String!) {
  addFcmToken(token: \$token, userID: \$userId) {
    message
    success
    tokenID
  }
}
''';

const SUBSCRIBE = '''
mutation SubscribeToManga(\$tokenId: String!, \$mangaTitle: String!) {
  subscribe(tokenID: \$tokenId, mangaTitle: \$mangaTitle) {
    message
    success
  }
}
''';

const MANGA_UPDATE = '''
query MangaUpdate(\$page: Int!) {
  getMangaPage(page: \$page) {
    message
    success
    data {
      mangaUrl
      imageUrl
      title
      status
      mangaSource
    }
  }
}
''';

const REMOVE_TOKEN = '''
mutation RemoveFcmTokenMutation( \$userId: String!) {
  removeFcmToken(userID: \$userId) {
    message
    success
  }
}
''';
