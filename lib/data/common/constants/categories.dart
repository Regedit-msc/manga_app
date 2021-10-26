enum Categories {
  ACTION,
  MARTIAL_ARTS,
  ALL,
  HAREM,
  DRAMA,
  SPORTS,

  ADULT,
  COOKING,
  ROMANCE,
  SCI_FI,
  MYSTERIOUS,
  MATURE,
  ADVENTURE,
  FANTASY,
  WEBTOONS,
  ONE_SHOT,
  PSYCHOLOGICAL,
  MANHWA,
  COMEDY,
  ISEKAI,
  TRAGEDY,
  SHOUJO,
  HISTORICAL,
  SHOUNEN,
  ECCHI,
  MANHUA,
  HORROR,
  GENDER_BENDER,
  MEDICAL,
  MECHA,

  SCHOOL_LIFE,
  SLICE_OF_LIFE
}

Categories getGenre(String genre) {
  switch (genre.toLowerCase()) {
    case "action":
      return Categories.ACTION;
    case "martial arts":
      return Categories.MARTIAL_ARTS;

    case "all":
      return Categories.ALL;
    case "harem":
      return Categories.HAREM;
    case "drama":
      return Categories.DRAMA;
    case "sports":
      return Categories.SPORTS;
    case "school life":
      return Categories.SCHOOL_LIFE;
    case "adult":
      return Categories.ADULT;
    case "slice of life":
      return Categories.SLICE_OF_LIFE;
    case "webtoons":
      return Categories.WEBTOONS;
    case "romance":
      return Categories.ROMANCE;
    case "sci fi":
      return Categories.SCI_FI;
    case "mysterious":
      return Categories.MYSTERIOUS;
    case "mature":
      return Categories.MATURE;
    case "tragedy":
      return Categories.TRAGEDY;
    case "ecchi":
      return Categories.ECCHI;
    case "shoujo":
      return Categories.SHOUJO;
    case "shounen":
      return Categories.SHOUNEN;
    case "mecha":
      return Categories.MECHA;
    case "medical":
      return Categories.MEDICAL;
    case "fantasy":
      return Categories.FANTASY;
    case "Gender bender":
      return Categories.GENDER_BENDER;
    case "historical":
      return Categories.HISTORICAL;
    case "horror":
      return Categories.HORROR;
    case "cooking":
      return Categories.COOKING;
    case "comedy":
      return Categories.COMEDY;
    case "manhua":
      return Categories.MANHUA;
    case "manhwa":
      return Categories.MANHWA;
    case "psychological":
      return Categories.PSYCHOLOGICAL;
    case "one shot":
      return Categories.ONE_SHOT;
    case "isekai":
      return Categories.ISEKAI;
    case "adventure":
      return Categories.ADVENTURE;
    default:
      return Categories.ACTION;
  }
}
