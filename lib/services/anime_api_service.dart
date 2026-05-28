import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/anime_model.dart';

class AnimeApiService {
  static const String _jikanBase = 'https://api.jikan.moe/v4';

  // ── Search ────────────────────────────────────────────────────────────────

  Future<List<AnimeModel>> searchAnime(String query, {int limit = 20}) async {
    try {
      final uri = Uri.parse(
        '$_jikanBase/anime?q=${Uri.encodeComponent(query)}&limit=$limit',
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to search anime');
      }

      final json = jsonDecode(response.body);
      final List data = json['data'];

      return data.map((e) => _fromJikan(e)).toList();
    } catch (e) {
      print('searchAnime error: $e');
      return [];
    }
  }

  // ── Anime Detail ──────────────────────────────────────────────────────────

  Future<AnimeModel?> getAnimeDetail(int id) async {
    try {
      final uri = Uri.parse('$_jikanBase/anime/$id/full');

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch anime detail');
      }

      final json = jsonDecode(response.body);
      final data = json['data'];

      return _fromJikan(data);
    } catch (e) {
      print('getAnimeDetail error: $e');
      return null;
    }
  }

  // ── Current Season ────────────────────────────────────────────────────────

  Future<List<AnimeModel>> getCurrentSeasonAnime() async {
    try {
      final uri = Uri.parse('$_jikanBase/seasons/now');

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch current season anime');
      }

      final json = jsonDecode(response.body);
      final List data = json['data'];

      return data.map((e) => _fromJikan(e)).toList();
    } catch (e) {
      print('getCurrentSeasonAnime error: $e');
      return [];
    }
  }

  // ── Top Anime ─────────────────────────────────────────────────────────────

  Future<List<AnimeModel>> getTopAnime({
    int limit = 10,
    int page = 1,
    String? filter,
  }) async {
    try {
      final query = [
        'limit=$limit',
        'page=$page',
        if (filter != null) 'filter=$filter',
      ].join('&');

      final uri = Uri.parse('$_jikanBase/top/anime?$query');
      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch top anime');
      }

      final json = jsonDecode(response.body);
      final List data = json['data'];

      return data.map((e) => _fromJikan(e)).toList();
    } catch (e) {
      print('getTopAnime error: $e');
      return [];
    }
  }
  // ── User Library (Temporary Mock) ────────────────────────────────────────

  Future<List<AnimeModel>> getUserLibrary() async {
    return [];
  }

  Future<bool> saveToLibrary(AnimeModel anime) async {
    return true;
  }

  Future<bool> removeFromLibrary(int animeId) async {
    return true;
  }

  // ── Jikan → AnimeModel Mapper ────────────────────────────────────────────

  AnimeModel _fromJikan(Map<String, dynamic> json) {
    return AnimeModel(
      id: json['mal_id'] ?? 0,

      title: json['title'] ?? '',

      titleEnglish: json['title_english'],

      titleJapanese: json['title_japanese'],

      coverImageUrl:
          json['images']?['jpg']?['large_image_url'] ??
          json['images']?['jpg']?['image_url'] ??
          '',

      bannerImageUrl: json['trailer']?['images']?['maximum_image_url'],

      synopsis: json['synopsis'] ?? 'No synopsis available.',

      type: json['type'] ?? 'Unknown',

      episodes: json['episodes'] ?? 0,

      status: json['status'] ?? 'Unknown',

      score: (json['score'] ?? 0).toDouble(),

      genres:
          (json['genres'] as List?)
              ?.map((g) => g['name'].toString())
              .toList() ??
          [],

      studio: (json['studios'] as List?)?.isNotEmpty == true
          ? json['studios'][0]['name']
          : 'Unknown',

      season: json['season'] != null
          ? '${json['season']} ${json['year'] ?? ''}'
          : null,

      year: json['year'],
    );
  }
}
