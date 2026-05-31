import 'dart:convert';
import 'package:http/http.dart' as http;

class SafebooruService {
  static const String _base = 'https://safebooru.org/index.php';

  Future<List<String>> searchImages(
    String animeName, {
    int limit = 60, // ← increased default
    int page = 0, // ← page support (0-indexed)
  }) async {
    try {
      final results = await _fetch(animeName, limit: limit, page: page);
      if (results.isNotEmpty) return results;

      // Fallback: strip subtitle after colon
      // e.g. "Frieren: Beyond Journey's End" → "Frieren"
      final simplified = animeName.split(':').first.trim();
      if (simplified != animeName) {
        return await _fetch(simplified, limit: limit, page: page);
      }

      return [];
    } catch (e) {
      print('SafebooruService error: $e');
      return [];
    }
  }

  Future<List<String>> _fetch(
    String name, {
    int limit = 60,
    int page = 0,
  }) async {
    final tag = name
        .toLowerCase()
        .trim()
        .replaceAll(':', '')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    final uri = Uri.parse(
      '$_base?page=dapi&s=post&q=index&json=1'
      '&tags=$tag'
      '&limit=$limit'
      '&pid=$page', // ← pid = page index
    );

    print('SafebooruService fetching: $uri');

    final response = await http.get(
      uri,
      headers: {'User-Agent': 'Mozilla/5.0'},
    );

    print('SafebooruService status: ${response.statusCode}');
    print(
      'SafebooruService body preview: ${response.body.substring(0, response.body.length.clamp(0, 200))}',
    );

    if (response.statusCode != 200) return [];
    if (response.body.isEmpty || response.body == 'null') return [];

    final decoded = jsonDecode(response.body);

    final List data;
    if (decoded is List) {
      data = decoded;
    } else if (decoded is Map) {
      data = [decoded];
    } else {
      return [];
    }

    return data
        .whereType<Map>()
        .map((post) {
          final directory = post['directory']?.toString() ?? '';
          final image = post['image']?.toString() ?? '';
          if (directory.isEmpty || image.isEmpty) return '';
          return 'https://safebooru.org/images/$directory/$image';
        })
        .where((url) => url.isNotEmpty)
        .toList();
  }
}
