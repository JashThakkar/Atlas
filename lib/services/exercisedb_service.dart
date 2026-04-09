import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service to fetch exercise media (images and video links) from the ExerciseDB API.
/// API docs: https://github.com/exercisedb/exercisedb-api
class ExerciseDBService {
  static const String _defaultBaseUrl = 'https://exercisedb.dev/api/v2';
  static const String _cdnBase = 'https://cdn.exercisedb.dev/exercisedb/';

  String get _baseUrl => dotenv.env['EXERCISEDB_BASE_URL'] ?? _defaultBaseUrl;
  String get _apiKey => dotenv.env['EXERCISEDB_API_KEY'] ?? '';

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_apiKey.isNotEmpty) {
      headers['X-RapidAPI-Key'] = _apiKey;
      headers['X-RapidAPI-Host'] = 'exercisedb.p.rapidapi.com';
    }
    return headers;
  }

  /// Searches ExerciseDB for an exercise by name and returns its image and video URLs.
  /// Returns null if the exercise cannot be found or the API is unavailable.
  Future<ExerciseMedia?> getExerciseMedia(String name) async {
    try {
      final encodedName = Uri.encodeComponent(name.toLowerCase());
      final uri = Uri.parse('$_baseUrl/exercises/search?q=$encodedName&limit=5');

      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);

      // The API may return a list directly or wrapped in a "data" field.
      List<dynamic> exercises;
      if (body is List) {
        exercises = body;
      } else if (body is Map && body['data'] is List) {
        exercises = body['data'] as List<dynamic>;
      } else {
        return null;
      }

      if (exercises.isEmpty) return null;

      // Pick the best match: prefer an exact name match, else take the first result.
      final match = exercises.firstWhere(
        (e) =>
            e is Map &&
            (e['name'] as String?)?.toLowerCase() == name.toLowerCase(),
        orElse: () => exercises.first,
      );

      if (match is! Map) return null;

      final imageUrl = _resolveUrl(match['imageUrl'] as String?);
      final videoUrl = _resolveUrl(match['videoUrl'] as String?);

      if (imageUrl == null && videoUrl == null) return null;

      return ExerciseMedia(imageUrl: imageUrl, videoUrl: videoUrl);
    } catch (_) {
      // Any network or parse error: fail silently and return null.
      return null;
    }
  }

  /// Resolves a URL that may be relative (filename only) or absolute.
  String? _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$_cdnBase$url';
  }
}

class ExerciseMedia {
  final String? imageUrl;
  final String? videoUrl;

  const ExerciseMedia({this.imageUrl, this.videoUrl});
}
