// lib/models/anime_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum WatchStatus { ongoing, finished, planToWatch, dropped }

extension WatchStatusExtension on WatchStatus {
  String get label {
    switch (this) {
      case WatchStatus.ongoing:
        return 'Watching';
      case WatchStatus.finished:
        return 'Finished';
      case WatchStatus.planToWatch:
        return 'Plan to Watch';
      case WatchStatus.dropped:
        return 'Dropped';
    }
  }

  String get emoji {
    switch (this) {
      case WatchStatus.ongoing:
        return '▶️';
      case WatchStatus.finished:
        return '✅';
      case WatchStatus.planToWatch:
        return '📋';
      case WatchStatus.dropped:
        return '🚫';
    }
  }

  static WatchStatus fromString(String value) {
    return WatchStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WatchStatus.planToWatch,
    );
  }
}

class AnimeModel {
  final int id;
  final String title;
  final String? titleEnglish;
  final String? titleJapanese;
  final String coverImageUrl;
  final String? bannerImageUrl;
  final String? synopsis;
  final String? type;
  final int? episodes;
  final String? status;
  final double? score;
  final List<String> genres;
  final String? studio;
  final String? season;
  final int? year;
  // MAL content rating code: 'g', 'pg', 'pg13', 'r17', 'r+', 'rx'
  final String? rating;
  // YouTube trailer URL — sourced from Jikan trailer.url or trailer.youtube_id
  final String? trailerUrl;

  // User-specific fields
  WatchStatus? watchStatus;
  double? userRating;
  String? userEmojiRating;
  String? userReview;
  DateTime? dateAdded;
  DateTime? dateFinished;
  int? episodesWatched;

  AnimeModel({
    required this.id,
    required this.title,
    this.titleEnglish,
    this.titleJapanese,
    required this.coverImageUrl,
    this.bannerImageUrl,
    this.synopsis,
    this.type,
    this.episodes,
    this.status,
    this.score,
    this.genres = const [],
    this.studio,
    this.season,
    this.year,
    this.rating,
    this.trailerUrl,
    this.watchStatus,
    this.userRating,
    this.userEmojiRating,
    this.userReview,
    this.dateAdded,
    this.dateFinished,
    this.episodesWatched,
  });

  // ── Factory: Jikan v4 ─────────────────────────────────────────────────────
  factory AnimeModel.fromJikan(Map<String, dynamic> json) {
    final genreList =
        (json['genres'] as List<dynamic>?)
            ?.map((g) => g['name'] as String)
            .toList() ??
        [];
    final studioList = (json['studios'] as List<dynamic>?)
        ?.map((s) => s['name'] as String)
        .toList();

    final trailer = json['trailer'] as Map<String, dynamic>?;
    final trailerUrl =
        trailer?['url'] as String? ??
        (trailer?['youtube_id'] != null
            ? 'https://www.youtube.com/watch?v=${trailer!['youtube_id']}'
            : null);

    return AnimeModel(
      id: json['mal_id'] as int,
      title: json['title'] as String,
      titleEnglish: json['title_english'] as String?,
      titleJapanese: json['title_japanese'] as String?,
      coverImageUrl:
          json['images']?['jpg']?['large_image_url'] as String? ??
          json['images']?['jpg']?['image_url'] as String? ??
          '',
      bannerImageUrl: trailer?['images']?['maximum_image_url'] as String?,
      synopsis: json['synopsis'] as String?,
      type: json['type'] as String?,
      episodes: json['episodes'] as int?,
      status: json['status'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      genres: genreList,
      studio: studioList?.isNotEmpty == true ? studioList!.first : null,
      season: json['season'] != null && json['year'] != null
          ? '${json['season']} ${json['year']}'
          : null,
      year: json['year'] as int?,
      rating: (json['rating'] as String?)?.split(' ').first.toLowerCase(),
      trailerUrl: trailerUrl,
    );
  }

  // ── Factory: AniList GraphQL ──────────────────────────────────────────────
  factory AnimeModel.fromAniList(Map<String, dynamic> json) {
    final title = json['title'] as Map<String, dynamic>;
    final coverImage = json['coverImage'] as Map<String, dynamic>?;
    final genreList =
        (json['genres'] as List<dynamic>?)?.map((g) => g as String).toList() ??
        [];
    final studioEdges = (json['studios']?['edges'] as List<dynamic>?) ?? [];
    final mainStudio = studioEdges
        .where((e) => e['isMain'] == true)
        .map((e) => e['node']?['name'] as String?)
        .firstOrNull;

    return AnimeModel(
      id: json['id'] as int,
      title:
          title['romaji'] as String? ??
          title['english'] as String? ??
          'Unknown',
      titleEnglish: title['english'] as String?,
      titleJapanese: title['native'] as String?,
      coverImageUrl: coverImage?['large'] as String? ?? '',
      bannerImageUrl: json['bannerImage'] as String?,
      synopsis: json['description'] as String?,
      type: json['format'] as String?,
      episodes: json['episodes'] as int?,
      status: json['status'] as String?,
      score: json['averageScore'] != null
          ? (json['averageScore'] as int) / 10.0
          : null,
      genres: genreList,
      studio: mainStudio,
      season: json['season'] != null && json['seasonYear'] != null
          ? '${json['season']} ${json['seasonYear']}'
          : null,
      year: json['seasonYear'] as int?,
    );
  }

  // ── Firestore: write ──────────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() => {
    'id': id,
    'title': title,
    'titleEnglish': titleEnglish,
    'titleJapanese': titleJapanese,
    'coverImageUrl': coverImageUrl,
    'bannerImageUrl': bannerImageUrl,
    'synopsis': synopsis,
    'type': type,
    'episodes': episodes,
    'status': status,
    'score': score,
    'genres': genres,
    'studio': studio,
    'season': season,
    'year': year,
    'rating': rating,
    'trailerUrl': trailerUrl,
    'watchStatus': watchStatus?.name,
    'userRating': userRating,
    'userEmojiRating': userEmojiRating,
    'userReview': userReview,
    'dateAdded': dateAdded?.toIso8601String(),
    'dateFinished': dateFinished?.toIso8601String(),
    'episodesWatched': episodesWatched,
  };

  // ── Firestore: read ───────────────────────────────────────────────────────
  factory AnimeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AnimeModel(
      id: d['id'] as int,
      title: d['title'] as String? ?? '',
      titleEnglish: d['titleEnglish'] as String?,
      titleJapanese: d['titleJapanese'] as String?,
      coverImageUrl: d['coverImageUrl'] as String? ?? '',
      bannerImageUrl: d['bannerImageUrl'] as String?,
      synopsis: d['synopsis'] as String?,
      type: d['type'] as String?,
      episodes: d['episodes'] as int?,
      status: d['status'] as String?,
      score: (d['score'] as num?)?.toDouble(),
      genres: List<String>.from(d['genres'] ?? []),
      studio: d['studio'] as String?,
      season: d['season'] as String?,
      year: d['year'] as int?,
      rating: d['rating'] as String?,
      trailerUrl: d['trailerUrl'] as String?,
      watchStatus: d['watchStatus'] != null
          ? WatchStatusExtension.fromString(d['watchStatus'])
          : null,
      userRating: (d['userRating'] as num?)?.toDouble(),
      userEmojiRating: d['userEmojiRating'] as String?,
      userReview: d['userReview'] as String?,
      dateAdded: d['dateAdded'] != null
          ? DateTime.tryParse(d['dateAdded'])
          : null,
      dateFinished: d['dateFinished'] != null
          ? DateTime.tryParse(d['dateFinished'])
          : null,
      episodesWatched: d['episodesWatched'] as int?,
    );
  }

  // ── userDataToJson ────────────────────────────────────────────────────────
  Map<String, dynamic> userDataToJson() => {
    'anime_id': id,
    'watch_status': watchStatus?.name,
    'user_rating': userRating,
    'user_emoji_rating': userEmojiRating,
    'user_review': userReview,
    'date_added': dateAdded?.toIso8601String(),
    'date_finished': dateFinished?.toIso8601String(),
    'episodes_watched': episodesWatched,
  };

  // ── copyWith ──────────────────────────────────────────────────────────────
  AnimeModel copyWith({
    WatchStatus? watchStatus,
    double? userRating,
    String? userEmojiRating,
    String? userReview,
    DateTime? dateAdded,
    DateTime? dateFinished,
    int? episodesWatched,
  }) {
    return AnimeModel(
      id: id,
      title: title,
      titleEnglish: titleEnglish,
      titleJapanese: titleJapanese,
      coverImageUrl: coverImageUrl,
      bannerImageUrl: bannerImageUrl,
      synopsis: synopsis,
      type: type,
      episodes: episodes,
      status: status,
      score: score,
      genres: genres,
      studio: studio,
      season: season,
      year: year,
      rating: rating,
      trailerUrl: trailerUrl,
      watchStatus: watchStatus ?? this.watchStatus,
      userRating: userRating ?? this.userRating,
      userEmojiRating: userEmojiRating ?? this.userEmojiRating,
      userReview: userReview ?? this.userReview,
      dateAdded: dateAdded ?? this.dateAdded,
      dateFinished: dateFinished ?? this.dateFinished,
      episodesWatched: episodesWatched ?? this.episodesWatched,
    );
  }
}
