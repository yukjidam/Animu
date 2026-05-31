import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/anime_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/profile_card_themes.dart';
import '../../widgets/common/ani_app_bar.dart';
import '../../widgets/common/star_rating.dart';
import '../../widgets/common/status_badge.dart';
import '../detail/anime_detail_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String uid;
  final String? preloadedName;
  final String? preloadedPhotoURL;

  const PublicProfileScreen({
    super.key,
    required this.uid,
    this.preloadedName,
    this.preloadedPhotoURL,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  bool _loading = true;
  String? _displayName;
  String? _photoURL;
  ProfileCardTheme _cardTheme = ProfileCardTheme.defaultDark;
  List<AnimeModel> _library = [];
  bool _libraryPrivate = false;
  bool _reviewsPrivate = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _displayName = widget.preloadedName;
    _photoURL = widget.preloadedPhotoURL;
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final results = await Future.wait([
        _firestore.collection('users').doc(widget.uid).get(),
        _firestore
            .collection('users')
            .doc(widget.uid)
            .collection('library')
            .get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final librarySnap = results[1] as QuerySnapshot;
      if (!mounted) return;

      final data = userDoc.data() as Map<String, dynamic>?;
      final library = librarySnap.docs
          .map((doc) => doc as DocumentSnapshot<Map<String, dynamic>>)
          .map((doc) => AnimeModel.fromFirestore(doc))
          .toList();

      setState(() {
        _displayName = data?['displayName'] as String? ?? _displayName;
        _photoURL = data?['photoURL'] as String? ?? _photoURL;
        _cardTheme = ProfileCardThemeX.fromId(
          data?['profileCardTheme'] as String?,
        );
        _libraryPrivate = data?['libraryPrivate'] as bool? ?? false;
        _reviewsPrivate = data?['reviewsPrivate'] as bool? ?? false;
        _library = library;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int get _totalWatched =>
      _library.where((a) => a.watchStatus == WatchStatus.finished).length;
  int get _totalOngoing =>
      _library.where((a) => a.watchStatus == WatchStatus.ongoing).length;
  int get _totalPtw =>
      _library.where((a) => a.watchStatus == WatchStatus.planToWatch).length;

  double get _avgRating {
    final rated = _library.where((a) => a.userRating != null).toList();
    if (rated.isEmpty) return 0;
    return rated.map((a) => a.userRating!).reduce((a, b) => a + b) /
        rated.length;
  }

  List<AnimeModel> get _reviewed => _library
      .where((a) => a.userRating != null || (a.userReview?.isNotEmpty == true))
      .toList();

  String get _firstName => _displayName?.split(' ').first ?? 'This user';

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.backgroundDark,
      appBar: AniAppBar(title: _displayName ?? 'Profile'),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: t.primaryViolet))
          : RefreshIndicator(
              color: t.primaryViolet,
              backgroundColor: t.cardDark,
              onRefresh: _loadProfile,
              child: NestedScrollView(
                headerSliverBuilder: (context, _) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileCard(t),
                          const SizedBox(height: 20),
                          _buildStatsGrid(t),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      tabBar: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [t.primaryViolet, t.accentSakura],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppTheme.textMuted,
                        tabs: const [
                          Tab(text: '✍️  Reviews'),
                          Tab(text: '📚  Library'),
                        ],
                      ),
                      backgroundColor: t.backgroundDark,
                      containerColor: t.cardDark,
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _reviewsPrivate
                        ? _PrivateSection(
                            emoji: '🔒',
                            message:
                                '$_firstName has kept their reviews private',
                          )
                        : _reviewed.isEmpty
                        ? _PrivateSection(
                            emoji: '📭',
                            message:
                                '$_firstName hasn\'t reviewed anything yet',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                            itemCount: _reviewed.length,
                            itemBuilder: (context, index) {
                              final tt = AppTheme.of(context);
                              return _ReviewCard(
                                anime: _reviewed[index],
                                t: tt,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AnimeDetailScreen(
                                      anime: _reviewed[index],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    _libraryPrivate
                        ? _PrivateSection(
                            emoji: '🔒',
                            message:
                                '$_firstName has kept their library private',
                          )
                        : _library.isEmpty
                        ? _PrivateSection(
                            emoji: '📭',
                            message: '$_firstName\'s library is empty',
                          )
                        : _LibraryTab(
                            library: _library,
                            onAnimeTap: (anime) => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AnimeDetailScreen(anime: anime),
                              ),
                            ),
                          ),
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
                child: _photoURL != null
                    ? Image.network(
                        _photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('🧑', style: TextStyle(fontSize: 36)),
                        ),
                      )
                    : const Center(
                        child: Text('🧑', style: TextStyle(fontSize: 36)),
                      ),
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
                    '${_library.length} anime in library',
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
}

// ── Library tab ───────────────────────────────────────────────────────────────

class _LibraryTab extends StatelessWidget {
  final List<AnimeModel> library;
  final void Function(AnimeModel) onAnimeTap;
  const _LibraryTab({required this.library, required this.onAnimeTap});

  static const _statusOrder = [
    WatchStatus.ongoing,
    WatchStatus.finished,
    WatchStatus.planToWatch,
    WatchStatus.dropped,
  ];
  static const _statusLabels = {
    WatchStatus.ongoing: '▶️  Watching',
    WatchStatus.finished: '✅  Completed',
    WatchStatus.planToWatch: '📋  Plan to Watch',
    WatchStatus.dropped: '🚫  Dropped',
  };

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        for (final status in _statusOrder)
          Builder(
            builder: (context) {
              final group = library
                  .where((a) => a.watchStatus == status)
                  .toList();
              if (group.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _statusLabels[status] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  ...group.map(
                    (anime) => _LibraryAnimeRow(
                      anime: anime,
                      t: t,
                      onTap: () => onAnimeTap(anime),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _LibraryAnimeRow extends StatelessWidget {
  final AnimeModel anime;
  final AppThemeTokens t;
  final VoidCallback onTap;
  const _LibraryAnimeRow({
    required this.anime,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.divider),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                anime.coverImageUrl,
                width: 40,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 40,
                  height: 56,
                  decoration: BoxDecoration(
                    color: t.cardElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (anime.userRating != null) ...[
                        StarRating(rating: anime.userRating!, starSize: 11),
                        const SizedBox(width: 4),
                      ],
                      if (anime.userEmojiRating != null)
                        Text(
                          anime.userEmojiRating!,
                          style: const TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (anime.watchStatus != null)
              StatusBadge(status: anime.watchStatus!, compact: true),
          ],
        ),
      ),
    );
  }
}

// ── Private/empty placeholder ─────────────────────────────────────────────────

class _PrivateSection extends StatelessWidget {
  final String emoji;
  final String message;
  const _PrivateSection({required this.emoji, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: AppTheme.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pinned tab bar delegate ───────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;
  final Color containerColor;
  const _TabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
    required this.containerColor,
  });

  @override
  double get minExtent => 54;
  @override
  double get maxExtent => 54;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.backgroundColor != backgroundColor ||
      old.containerColor != containerColor;
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
