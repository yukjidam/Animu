// lib/services/library_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/anime_model.dart';

/// All Firestore reads/writes for the current user's personal anime library.
///
/// Firestore structure:
///   users/{uid}/library/{animeId}  →  AnimeModel fields
class LibraryService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Helpers ────────────────────────────────────────────────────────────────

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User is not logged in.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _libraryRef =>
      _db.collection('users').doc(_uid).collection('library');

  // ── Real-time stream ───────────────────────────────────────────────────────

  Stream<List<AnimeModel>> libraryStream() {
    return _libraryRef
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => AnimeModel.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<AnimeModel>> libraryStreamByStatus(WatchStatus status) {
    return _libraryRef
        .where('watchStatus', isEqualTo: status.name)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => AnimeModel.fromFirestore(doc)).toList(),
        );
  }

  // ── One-time fetch ─────────────────────────────────────────────────────────

  Future<List<AnimeModel>> getUserLibrary() async {
    final snap = await _libraryRef.orderBy('addedAt', descending: true).get();
    return snap.docs.map((doc) => AnimeModel.fromFirestore(doc)).toList();
  }

  // ── Write operations ───────────────────────────────────────────────────────

  /// Adds or fully updates an anime entry — single write, zero pre-reads.
  ///
  /// Uses .set() with merge:true which:
  ///   - Creates the doc if it doesn't exist
  ///   - Updates only the provided fields if it already exists
  ///   - Never throws on null values (unlike .update())
  ///
  /// Note: addedAt is always written. For a new doc it acts as the creation
  /// timestamp. On review updates it refreshes — acceptable since the
  /// library ordering query uses 'addedAt' and the difference is negligible.
  Future<void> addAnime(AnimeModel anime) async {
    await _libraryRef.doc(anime.id.toString()).set({
      ...anime.toFirestore(),
      'addedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Updates only the watch status of an existing entry.
  Future<void> updateStatus(String animeId, WatchStatus status) async {
    await _libraryRef.doc(animeId).set({
      'watchStatus': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Updates episodes watched progress.
  Future<void> updateEpisode(String animeId, int episodesWatched) async {
    await _libraryRef.doc(animeId).set({
      'episodesWatched': episodesWatched,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Updates the user's rating (0.0 – 5.0).
  Future<void> updateRating(String animeId, double userRating) async {
    await _libraryRef.doc(animeId).set({
      'userRating': userRating,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Updates the user's emoji rating.
  Future<void> updateEmojiRating(String animeId, String emoji) async {
    await _libraryRef.doc(animeId).set({
      'userEmojiRating': emoji,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Updates the user's review text.
  Future<void> updateReview(String animeId, String review) async {
    await _libraryRef.doc(animeId).set({
      'userReview': review,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Batch update — only provided fields are written.
  Future<void> updateAnime({
    required String animeId,
    WatchStatus? status,
    int? episodesWatched,
    double? userRating,
    String? userEmojiRating,
    String? userReview,
    DateTime? dateFinished,
  }) async {
    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (status != null) data['watchStatus'] = status.name;
    if (episodesWatched != null) data['episodesWatched'] = episodesWatched;
    if (userRating != null) data['userRating'] = userRating;
    if (userEmojiRating != null) data['userEmojiRating'] = userEmojiRating;
    if (userReview != null) data['userReview'] = userReview;
    if (dateFinished != null)
      data['dateFinished'] = dateFinished.toIso8601String();

    // ✅ set() with merge instead of update() — never throws on partial data
    await _libraryRef.doc(animeId).set(data, SetOptions(merge: true));
  }

  /// Removes an anime from the library permanently.
  Future<void> removeAnime(String animeId) async {
    await _libraryRef.doc(animeId).delete();
  }

  // ── Existence check ────────────────────────────────────────────────────────

  Future<bool> isInLibrary(int animeId) async {
    final doc = await _libraryRef.doc(animeId.toString()).get();
    return doc.exists;
  }
}
