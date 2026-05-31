import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../models/anime_model.dart';
import '../../services/library_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/profile_card_themes.dart';
import '../../widgets/common/ani_app_bar.dart';
import '../../widgets/common/star_rating.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/profile/profile_theme_picker.dart';
import '../../widgets/search/top_users_section.dart';
import '../detail/anime_detail_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _library = LibraryService();
  final _auth = AuthService();
  final _firebaseAuth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();

  StreamSubscription<List<AnimeModel>>? _librarySub;
  List<AnimeModel> _animeList = [];
  bool _loading = true;
  bool _uploadingPhoto = false;

  String? _displayName;
  String? _photoURL;
  ProfileCardTheme _cardTheme = ProfileCardTheme.defaultDark;

  @override
  void initState() {
    super.initState();
    _syncUserInfo();
    _loadTheme();
    _subscribeToLibrary();
  }

  @override
  void dispose() {
    _librarySub?.cancel();
    super.dispose();
  }

  void _syncUserInfo() {
    final user = _firebaseAuth.currentUser;
    final emailName = user?.email?.split('@').first;
    _displayName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName
        : emailName;
    _photoURL = user?.photoURL;
  }

  Future<void> _loadTheme() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final themeId = doc.data()?['profileCardTheme'] as String?;
      if (!mounted) return;
      setState(() => _cardTheme = ProfileCardThemeX.fromId(themeId));
    } catch (_) {}
  }

  Future<void> _saveTheme(ProfileCardTheme theme) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'profileCardTheme': theme.id,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _openThemePicker() async {
    final chosen = await ProfileThemePicker.show(context, current: _cardTheme);
    if (chosen == null || chosen == _cardTheme) return;
    setState(() => _cardTheme = chosen);
    await _saveTheme(chosen);
  }

  void _subscribeToLibrary() {
    _librarySub = _library.libraryStream().listen((data) {
      if (!mounted) return;
      setState(() {
        _animeList = data;
        _loading = false;
      });
      _syncStatsToFirestore(data);
    });
  }

  Future<void> _syncStatsToFirestore(List<AnimeModel> data) async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    try {
      final watchedCount = data
          .where((a) => a.watchStatus == WatchStatus.finished)
          .length;
      final reviewCount = data
          .where(
            (a) => a.userRating != null || (a.userReview?.isNotEmpty == true),
          )
          .length;
      await _firestore.collection('users').doc(uid).set({
        'watchedCount': watchedCount,
        'reviewCount': reviewCount,
        'displayName': _displayName,
        'displayNameLower': _displayName?.toLowerCase(),
        'photoURL': _firebaseAuth.currentUser?.photoURL,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  int get _totalWatched =>
      _animeList.where((a) => a.watchStatus == WatchStatus.finished).length;
  int get _totalOngoing =>
      _animeList.where((a) => a.watchStatus == WatchStatus.ongoing).length;
  int get _totalPtw =>
      _animeList.where((a) => a.watchStatus == WatchStatus.planToWatch).length;

  double get _avgRating {
    final rated = _animeList.where((a) => a.userRating != null).toList();
    if (rated.isEmpty) return 0;
    return rated.map((a) => a.userRating!).reduce((a, b) => a + b) /
        rated.length;
  }

  List<AnimeModel> get _reviewed => _animeList
      .where((a) => a.userRating != null || (a.userReview?.isNotEmpty == true))
      .toList();

  Future<void> _editName() async {
    final t = AppTheme.of(context);
    final controller = TextEditingController(text: _displayName ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: t.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: t.primaryViolet.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: t.primaryViolet,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Display Name',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 30,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Your display name',
                    hintStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      color: AppTheme.textMuted,
                    ),
                    filled: true,
                    fillColor: t.backgroundDark,
                    counterStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: t.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: t.primaryViolet,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: t.divider),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: t.backgroundDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: t.divider),
                          ),
                          child: const Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(ctx, controller.text.trim()),
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [t.primaryViolet, t.accentSakura],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'Save',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _firebaseAuth.currentUser?.updateDisplayName(result);
        await _firebaseAuth.currentUser?.reload();
        if (!mounted) return;
        setState(() => _displayName = result);
        _syncStatsToFirestore(_animeList);
        _showSnack('Display name updated!');
      } catch (e) {
        if (!mounted) return;
        _showSnack('Failed to update name.', isError: true);
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      final user = _firebaseAuth.currentUser;
      if (user == null) return;
      if (!mounted) return;
      setState(() => _uploadingPhoto = true);

      final bytes = await File(picked.path).readAsBytes();
      if (bytes.length > 20 * 1024 * 1024)
        throw Exception('Image too large. Please choose a smaller one.');

      final base64Image = base64Encode(bytes);
      const apiKey = 'bc6c02ea66a214f0b1e89af25c1c7db7';
      final response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
        body: {'image': base64Image},
      );
      if (response.statusCode != 200)
        throw Exception('Upload failed (HTTP ${response.statusCode})');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true)
        throw Exception(data['error']?['message'] ?? 'Upload failed');

      final imageUrl =
          data['data']?['display_url'] as String? ??
          data['data']?['url'] as String?;
      if (imageUrl == null) throw Exception('No image URL returned');

      await user.updatePhotoURL(imageUrl);
      await user.reload();
      if (!mounted) return;
      setState(() {
        _photoURL = imageUrl;
        _uploadingPhoto = false;
      });
      _syncStatsToFirestore(_animeList);
      _showSnack('Profile photo updated!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    final t = AppTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? AppTheme.statusDropped : t.primaryViolet,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.backgroundDark,
      appBar: AniAppBar(
        title: 'Profile',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_search_rounded,
              color: AppTheme.textSecondary,
            ),
            tooltip: 'Search users',
            onPressed: () =>
                showSearch(context: context, delegate: UserSearchDelegate()),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: AppTheme.textSecondary,
            ),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: t.primaryViolet))
          : RefreshIndicator(
              color: t.primaryViolet,
              backgroundColor: t.cardDark,
              onRefresh: () async {},
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileCard(t),
                    const SizedBox(height: 20),
                    _buildStatsGrid(t),
                    const SizedBox(height: 24),
                    if (_reviewed.isNotEmpty) ...[
                      _buildReviewedSection(t),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileCard(AppThemeTokens t) {
    return ThemedProfileCard(
      theme: _cardTheme,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GestureDetector(
              onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
              child: Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [t.primaryViolet, t.accentSakura],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _uploadingPhoto
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : _photoURL != null
                          ? Image.network(
                              _photoURL!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text(
                                  '🧑',
                                  style: TextStyle(fontSize: 36),
                                ),
                              ),
                            )
                          : const Center(
                              child: Text('🧑', style: TextStyle(fontSize: 36)),
                            ),
                    ),
                  ),
                  if (!_uploadingPhoto)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: t.primaryViolet,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: t.backgroundDark, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_displayName?.trim().isNotEmpty == true)
                        ? _displayName!
                        : 'Anime Fan',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_animeList.length} anime in library',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_avgRating > 0)
                    Row(
                      children: [
                        StarRating(rating: _avgRating, starSize: 14),
                        const SizedBox(width: 6),
                        Text(
                          'avg ${_avgRating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppTheme.textMuted,
                  ),
                  tooltip: 'Edit name',
                  onPressed: _editName,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.palette_outlined,
                    color: AppTheme.textMuted,
                  ),
                  tooltip: 'Change theme',
                  onPressed: _openThemePicker,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AppThemeTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stats',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _StatCard(
              emoji: '✅',
              value: '$_totalWatched',
              label: 'Completed',
              color: AppTheme.statusFinished,
              cardColor: t.cardDark,
            ),
            _StatCard(
              emoji: '▶️',
              value: '$_totalOngoing',
              label: 'Watching',
              color: AppTheme.statusOngoing,
              cardColor: t.cardDark,
            ),
            _StatCard(
              emoji: '📋',
              value: '$_totalPtw',
              label: 'Plan to Watch',
              color: AppTheme.statusPlanToWatch,
              cardColor: t.cardDark,
            ),
            _StatCard(
              emoji: '✍️',
              value: '${_reviewed.length}',
              label: 'Reviews',
              color: t.accentSakura,
              cardColor: t.cardDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewedSection(AppThemeTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Reviews',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._reviewed.map(
          (anime) => _ReviewCard(
            anime: anime,
            t: t,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnimeDetailScreen(anime: anime),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  final Color cardColor;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final AnimeModel anime;
  final AppThemeTokens t;
  final VoidCallback onTap;

  const _ReviewCard({
    required this.anime,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    anime.coverImageUrl,
                    width: 36,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(width: 36, height: 50, color: t.cardElevated),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime.titleEnglish ?? anime.title,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (anime.userRating != null)
                            StarRating(rating: anime.userRating!, starSize: 14),
                          if (anime.userEmojiRating != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              anime.userEmojiRating!,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (anime.watchStatus != null)
                  StatusBadge(status: anime.watchStatus!, compact: true),
              ],
            ),
            if (anime.userReview != null && anime.userReview!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(color: t.divider, height: 1),
              const SizedBox(height: 10),
              Text(
                anime.userReview!,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
