// To parse this JSON data, do
//
//     final unsplash = unsplashFromMap(jsonString);

import 'dart:convert';

Unsplash unsplashFromMap(String str) => Unsplash.fromMap(json.decode(str));

String unsplashToMap(Unsplash data) => json.encode(data.toMap());

class Unsplash {
  Unsplash({
    required this.total,
    required this.totalPages,
    required this.results,
  });

  final int total;
  final int totalPages;
  final List<Result> results;

  factory Unsplash.fromMap(Map<String, dynamic> json) => Unsplash(
        total: json["total"],
        totalPages: json["total_pages"],
        results:
            List<Result>.from(json["results"].map((x) => Result.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "total": total,
        "total_pages": totalPages,
        "results": List<dynamic>.from(results.map((x) => x.toMap())),
      };

  @override
  String toString() =>
      'Unsplash(total: ' +
      total.toString() +
      ', pages: ' +
      totalPages.toString() +
      ', results: ' +
      results.length.toString() +
      ')';
}

class Result {
  Result({
    required this.id,
    required this.title,
    required this.description,
    required this.previewPhotos,
  });

  final String id;
  final String title;
  final String description;
  final List<PreviewPhoto> previewPhotos;

  factory Result.fromMap(Map<String, dynamic> json) => Result(
        id: json["id"],
        title: json["title"],
        description: json["description"] == null ? '' : json["description"],
        previewPhotos: List<PreviewPhoto>.from(
            json["preview_photos"].map((x) => PreviewPhoto.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "title": title,
        "description": description,
        "preview_photos":
            List<dynamic>.from(previewPhotos.map((x) => x.toMap())),
      };

  @override
  String toString() =>
      'Unsplash.Result(id: ' +
      id +
      ', title: ' +
      title +
      ', photos: ' +
      previewPhotos.length.toString() +
      ')';
}

class ResultCoverPhoto {
  ResultCoverPhoto({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.promotedAt,
    required this.width,
    required this.height,
    required this.color,
    required this.blurHash,
    required this.description,
    required this.altDescription,
    required this.urls,
    required this.links,
    required this.categories,
    required this.likes,
    required this.likedByUser,
    required this.currentUserCollections,
    required this.sponsorship,
    required this.topicSubmissions,
    required this.user,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? promotedAt;
  final int width;
  final int height;
  final String color;
  final String blurHash;
  final String description;
  final String altDescription;
  final Urls urls;
  final CoverPhotoLinks links;
  final List<dynamic> categories;
  final int likes;
  final bool likedByUser;
  final List<dynamic> currentUserCollections;
  final dynamic sponsorship;
  final PurpleTopicSubmissions topicSubmissions;
  final User user;

  factory ResultCoverPhoto.fromMap(Map<String, dynamic> json) =>
      ResultCoverPhoto(
        id: json["id"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        promotedAt: json["promoted_at"] == null
            ? null
            : DateTime.parse(json["promoted_at"]),
        width: json["width"],
        height: json["height"],
        color: json["color"],
        blurHash: json["blur_hash"],
        description: json["description"] == null ? "" : json["description"],
        altDescription:
            json["alt_description"] == null ? "" : json["alt_description"],
        urls: Urls.fromMap(json["urls"]),
        links: CoverPhotoLinks.fromMap(json["links"]),
        categories: List<dynamic>.from(json["categories"].map((x) => x)),
        likes: json["likes"],
        likedByUser: json["liked_by_user"],
        currentUserCollections:
            List<dynamic>.from(json["current_user_collections"].map((x) => x)),
        sponsorship: json["sponsorship"],
        topicSubmissions:
            PurpleTopicSubmissions.fromMap(json["topic_submissions"]),
        user: User.fromMap(json["user"]),
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "promoted_at": promotedAt == null ? "" : promotedAt!.toIso8601String(),
        "width": width,
        "height": height,
        "color": color,
        "blur_hash": blurHash,
        "description": description,
        "alt_description": altDescription,
        "urls": urls.toMap(),
        "links": links.toMap(),
        "categories": List<dynamic>.from(categories.map((x) => x)),
        "likes": likes,
        "liked_by_user": likedByUser,
        "current_user_collections":
            List<dynamic>.from(currentUserCollections.map((x) => x)),
        "sponsorship": sponsorship,
        "topic_submissions": topicSubmissions.toMap(),
        "user": user.toMap(),
      };
}

class CoverPhotoLinks {
  CoverPhotoLinks({
    required this.self,
    required this.html,
    required this.download,
    required this.downloadLocation,
  });

  final String self;
  final String html;
  final String download;
  final String downloadLocation;

  factory CoverPhotoLinks.fromMap(Map<String, dynamic> json) => CoverPhotoLinks(
        self: json["self"],
        html: json["html"],
        download: json["download"],
        downloadLocation: json["download_location"],
      );

  Map<String, dynamic> toMap() => {
        "self": self,
        "html": html,
        "download": download,
        "download_location": downloadLocation,
      };
}

class PurpleTopicSubmissions {
  PurpleTopicSubmissions({
    required this.wallpapers,
  });

  final Wallpapers? wallpapers;

  factory PurpleTopicSubmissions.fromMap(Map<String, dynamic> json) =>
      PurpleTopicSubmissions(
        wallpapers: json["wallpapers"] == null
            ? null
            : Wallpapers.fromMap(json["wallpapers"]),
      );

  Map<String, dynamic> toMap() => {
        "wallpapers": wallpapers == null ? "" : wallpapers!.toMap(),
      };
}

class Wallpapers {
  Wallpapers({
    required this.status,
    required this.approvedOn,
  });

  final String status;
  final DateTime approvedOn;

  factory Wallpapers.fromMap(Map<String, dynamic> json) => Wallpapers(
        status: json["status"],
        approvedOn: DateTime.parse(json["approved_on"]),
      );

  Map<String, dynamic> toMap() => {
        "status": status,
        "approved_on": approvedOn.toIso8601String(),
      };
}

class Urls {
  Urls({
    required this.raw,
    required this.full,
    required this.regular,
    required this.small,
    required this.thumb,
  });

  final String raw;
  final String full;
  final String regular;
  final String small;
  final String thumb;

  factory Urls.fromMap(Map<String, dynamic> json) => Urls(
        raw: json["raw"],
        full: json["full"],
        regular: json["regular"],
        small: json["small"],
        thumb: json["thumb"],
      );

  Map<String, dynamic> toMap() => {
        "raw": raw,
        "full": full,
        "regular": regular,
        "small": small,
        "thumb": thumb,
      };
}

class User {
  User({
    required this.id,
    required this.updatedAt,
    required this.username,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.twitterUsername,
    required this.portfolioUrl,
    required this.bio,
    required this.location,
    required this.links,
    required this.profileImage,
    required this.instagramUsername,
    required this.totalCollections,
    required this.totalLikes,
    required this.totalPhotos,
    required this.acceptedTos,
    required this.forHire,
    required this.social,
  });

  final String id;
  final DateTime updatedAt;
  final String username;
  final String name;
  final String firstName;
  final String lastName;
  final String twitterUsername;
  final String portfolioUrl;
  final String bio;
  final String location;
  final UserLinks links;
  final ProfileImage profileImage;
  final String instagramUsername;
  final int totalCollections;
  final int totalLikes;
  final int totalPhotos;
  final bool acceptedTos;
  final bool forHire;
  final Social social;

  factory User.fromMap(Map<String, dynamic> json) => User(
        id: json["id"],
        updatedAt: DateTime.parse(json["updated_at"]),
        username: json["username"],
        name: json["name"],
        firstName: json["first_name"],
        lastName: json["last_name"] == null ? "" : json["last_name"],
        twitterUsername:
            json["twitter_username"] == null ? "" : json["twitter_username"],
        portfolioUrl:
            json["portfolio_url"] == null ? "" : json["portfolio_url"],
        bio: json["bio"] == null ? "" : json["bio"],
        location: json["location"] == null ? "" : json["location"],
        links: UserLinks.fromMap(json["links"]),
        profileImage: ProfileImage.fromMap(json["profile_image"]),
        instagramUsername: json["instagram_username"] == null
            ? ""
            : json["instagram_username"],
        totalCollections: json["total_collections"],
        totalLikes: json["total_likes"],
        totalPhotos: json["total_photos"],
        acceptedTos: json["accepted_tos"],
        forHire: json["for_hire"],
        social: Social.fromMap(json["social"]),
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "updated_at": updatedAt.toIso8601String(),
        "username": username,
        "name": name,
        "first_name": firstName,
        "last_name": lastName,
        "twitter_username": twitterUsername,
        "portfolio_url": portfolioUrl,
        "bio": bio,
        "location": location,
        "links": links.toMap(),
        "profile_image": profileImage.toMap(),
        "instagram_username": instagramUsername,
        "total_collections": totalCollections,
        "total_likes": totalLikes,
        "total_photos": totalPhotos,
        "accepted_tos": acceptedTos,
        "for_hire": forHire,
        "social": social.toMap(),
      };
}

class UserLinks {
  UserLinks({
    required this.self,
    required this.html,
    required this.photos,
    required this.likes,
    required this.portfolio,
    required this.following,
    required this.followers,
  });

  final String self;
  final String html;
  final String photos;
  final String likes;
  final String portfolio;
  final String following;
  final String followers;

  factory UserLinks.fromMap(Map<String, dynamic> json) => UserLinks(
        self: json["self"],
        html: json["html"],
        photos: json["photos"],
        likes: json["likes"],
        portfolio: json["portfolio"],
        following: json["following"],
        followers: json["followers"],
      );

  Map<String, dynamic> toMap() => {
        "self": self,
        "html": html,
        "photos": photos,
        "likes": likes,
        "portfolio": portfolio,
        "following": following,
        "followers": followers,
      };
}

class ProfileImage {
  ProfileImage({
    required this.small,
    required this.medium,
    required this.large,
  });

  final String small;
  final String medium;
  final String large;

  factory ProfileImage.fromMap(Map<String, dynamic> json) => ProfileImage(
        small: json["small"],
        medium: json["medium"],
        large: json["large"],
      );

  Map<String, dynamic> toMap() => {
        "small": small,
        "medium": medium,
        "large": large,
      };
}

class Social {
  Social({
    required this.instagramUsername,
    required this.portfolioUrl,
    required this.twitterUsername,
    required this.paypalEmail,
  });

  final String instagramUsername;
  final String portfolioUrl;
  final String twitterUsername;
  final dynamic paypalEmail;

  factory Social.fromMap(Map<String, dynamic> json) => Social(
        instagramUsername: json["instagram_username"] == null
            ? ""
            : json["instagram_username"],
        portfolioUrl:
            json["portfolio_url"] == null ? "" : json["portfolio_url"],
        twitterUsername:
            json["twitter_username"] == null ? "" : json["twitter_username"],
        paypalEmail: json["paypal_email"],
      );

  Map<String, dynamic> toMap() => {
        "instagram_username": instagramUsername,
        "portfolio_url": portfolioUrl,
        "twitter_username": twitterUsername,
        "paypal_email": paypalEmail,
      };
}

class ResultLinks {
  ResultLinks({
    required this.self,
    required this.html,
    required this.photos,
    required this.related,
  });

  final String self;
  final String html;
  final String photos;
  final String related;

  factory ResultLinks.fromMap(Map<String, dynamic> json) => ResultLinks(
        self: json["self"],
        html: json["html"],
        photos: json["photos"],
        related: json["related"],
      );

  Map<String, dynamic> toMap() => {
        "self": self,
        "html": html,
        "photos": photos,
        "related": related,
      };
}

class PreviewPhoto {
  PreviewPhoto({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.blurHash,
    required this.urls,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String blurHash;
  final Urls urls;

  factory PreviewPhoto.fromMap(Map<String, dynamic> json) => PreviewPhoto(
        id: json["id"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        blurHash: json["blur_hash"],
        urls: Urls.fromMap(json["urls"]),
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "blur_hash": blurHash,
        "urls": urls.toMap(),
      };
}

class Tag {
  Tag({
    required this.type,
    required this.title,
    required this.source,
  });

  final String type;
  final String title;
  final Source? source;

  factory Tag.fromMap(Map<String, dynamic> json) => Tag(
        type: json["type"],
        title: json["title"],
        source: json["source"] == null ? null : Source.fromMap(json["source"]),
      );

  Map<String, dynamic> toMap() => {
        "type": type,
        "title": title,
        "source": source == null ? null : source!.toMap(),
      };
}

class Source {
  Source({
    required this.ancestry,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.metaTitle,
    required this.metaDescription,
    required this.coverPhoto,
  });

  final Ancestry ancestry;
  final String title;
  final String subtitle;
  final String description;
  final String metaTitle;
  final String metaDescription;
  final SourceCoverPhoto coverPhoto;

  factory Source.fromMap(Map<String, dynamic> json) => Source(
        ancestry: Ancestry.fromMap(json["ancestry"]),
        title: json["title"],
        subtitle: json["subtitle"],
        description: json["description"],
        metaTitle: json["meta_title"],
        metaDescription: json["meta_description"],
        coverPhoto: SourceCoverPhoto.fromMap(json["cover_photo"]),
      );

  Map<String, dynamic> toMap() => {
        "ancestry": ancestry.toMap(),
        "title": title,
        "subtitle": subtitle,
        "description": description,
        "meta_title": metaTitle,
        "meta_description": metaDescription,
        "cover_photo": coverPhoto.toMap(),
      };
}

class Ancestry {
  Ancestry({
    required this.type,
    required this.category,
    required this.subcategory,
  });

  final TypeClass? type;
  final TypeClass? category;
  final TypeClass? subcategory;

  factory Ancestry.fromMap(Map<String, dynamic> json) => Ancestry(
        type: TypeClass.fromMap(json["type"]),
        category: json["category"] == null
            ? null
            : TypeClass.fromMap(json["category"]),
        subcategory: json["subcategory"] == null
            ? null
            : TypeClass.fromMap(json["subcategory"]),
      );

  Map<String, dynamic> toMap() => {
        "type": type!.toMap(),
        "category": category == null ? null : category!.toMap(),
        "subcategory": subcategory == null ? null : subcategory!.toMap(),
      };
}

class TypeClass {
  TypeClass({
    required this.slug,
    required this.prettySlug,
  });

  final String slug;
  final String prettySlug;

  factory TypeClass.fromMap(Map<String, dynamic> json) => TypeClass(
        slug: json["slug"],
        prettySlug: json["pretty_slug"],
      );

  Map<String, dynamic> toMap() => {
        "slug": slug,
        "pretty_slug": prettySlug,
      };
}

class SourceCoverPhoto {
  SourceCoverPhoto({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.promotedAt,
    required this.width,
    required this.height,
    required this.color,
    required this.blurHash,
    required this.description,
    required this.altDescription,
    required this.urls,
    required this.links,
    required this.categories,
    required this.likes,
    required this.likedByUser,
    required this.currentUserCollections,
    required this.sponsorship,
    required this.topicSubmissions,
    required this.user,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? promotedAt;
  final int width;
  final int height;
  final String color;
  final String blurHash;
  final String description;
  final String altDescription;
  final Urls urls;
  final CoverPhotoLinks links;
  final List<dynamic> categories;
  final int likes;
  final bool likedByUser;
  final List<dynamic> currentUserCollections;
  final dynamic sponsorship;
  final FluffyTopicSubmissions topicSubmissions;
  final User user;

  factory SourceCoverPhoto.fromMap(Map<String, dynamic> json) =>
      SourceCoverPhoto(
        id: json["id"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        promotedAt: json["promoted_at"] == null
            ? null
            : DateTime.parse(json["promoted_at"]),
        width: json["width"],
        height: json["height"],
        color: json["color"],
        blurHash: json["blur_hash"],
        description: json["description"] == null ? "" : json["description"],
        altDescription:
            json["alt_description"] == null ? "" : json["alt_description"],
        urls: Urls.fromMap(json["urls"]),
        links: CoverPhotoLinks.fromMap(json["links"]),
        categories: List<dynamic>.from(json["categories"].map((x) => x)),
        likes: json["likes"],
        likedByUser: json["liked_by_user"],
        currentUserCollections:
            List<dynamic>.from(json["current_user_collections"].map((x) => x)),
        sponsorship: json["sponsorship"],
        topicSubmissions:
            FluffyTopicSubmissions.fromMap(json["topic_submissions"]),
        user: User.fromMap(json["user"]),
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "promoted_at":
            promotedAt == null ? null : promotedAt!.toIso8601String(),
        "width": width,
        "height": height,
        "color": color,
        "blur_hash": blurHash,
        "description": description,
        "alt_description": altDescription,
        "urls": urls.toMap(),
        "links": links.toMap(),
        "categories": List<dynamic>.from(categories.map((x) => x)),
        "likes": likes,
        "liked_by_user": likedByUser,
        "current_user_collections":
            List<dynamic>.from(currentUserCollections.map((x) => x)),
        "sponsorship": sponsorship,
        "topic_submissions": topicSubmissions.toMap(),
        "user": user.toMap(),
      };
}

class FluffyTopicSubmissions {
  FluffyTopicSubmissions({
    required this.spirituality,
    required this.animals,
    required this.texturesPatterns,
    required this.nature,
    required this.wallpapers,
    required this.people,
    required this.history,
    required this.artsCulture,
    required this.athletics,
    required this.health,
  });

  final Wallpapers? spirituality;
  final Wallpapers? animals;
  final Wallpapers? texturesPatterns;
  final Wallpapers? nature;
  final Wallpapers? wallpapers;
  final Wallpapers? people;
  final Wallpapers? history;
  final Wallpapers? artsCulture;
  final Wallpapers? athletics;
  final Wallpapers? health;

  factory FluffyTopicSubmissions.fromMap(Map<String, dynamic> json) =>
      FluffyTopicSubmissions(
        spirituality: json["spirituality"] == null
            ? null
            : Wallpapers.fromMap(json["spirituality"]),
        animals: json["animals"] == null
            ? null
            : Wallpapers.fromMap(json["animals"]),
        texturesPatterns: json["textures-patterns"] == null
            ? null
            : Wallpapers.fromMap(json["textures-patterns"]),
        nature:
            json["nature"] == null ? null : Wallpapers.fromMap(json["nature"]),
        wallpapers: json["wallpapers"] == null
            ? null
            : Wallpapers.fromMap(json["wallpapers"]),
        people:
            json["people"] == null ? null : Wallpapers.fromMap(json["people"]),
        history: json["history"] == null
            ? null
            : Wallpapers.fromMap(json["history"]),
        artsCulture: json["arts-culture"] == null
            ? null
            : Wallpapers.fromMap(json["arts-culture"]),
        athletics: json["athletics"] == null
            ? null
            : Wallpapers.fromMap(json["athletics"]),
        health:
            json["health"] == null ? null : Wallpapers.fromMap(json["health"]),
      );

  Map<String, dynamic> toMap() => {
        "spirituality": spirituality == null ? null : spirituality!.toMap(),
        "animals": animals == null ? null : animals!.toMap(),
        "textures-patterns":
            texturesPatterns == null ? null : texturesPatterns!.toMap(),
        "nature": nature == null ? null : nature!.toMap(),
        "wallpapers": wallpapers == null ? null : wallpapers!.toMap(),
        "people": people == null ? null : people!.toMap(),
        "history": history == null ? null : history!.toMap(),
        "arts-culture": artsCulture == null ? null : artsCulture!.toMap(),
        "athletics": athletics == null ? null : athletics!.toMap(),
        "health": health == null ? null : health!.toMap(),
      };
}
