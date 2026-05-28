// lib/screens/home/home_content.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/anime_model.dart';
import '../../services/anime_api_service.dart';
import '../../services/library_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anime_card/anime_grid_card.dart';
import '../detail/anime_detail_screen.dart';
import 'top_anime_screen.dart';

class HomeContent extends StatefulWidget {
  final void Function(int index)? onNavigate;

  const HomeContent({super.key, this.onNavigate});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _api = AnimeApiService();
  final _libraryService = LibraryService();

  StreamSubscription<List<AnimeModel>>? _librarySub;
  List<AnimeModel> _library = [];
  List<AnimeModel> _ongoingShuffled = [];
  List<AnimeModel> _recentlyAdded = [];
  bool _loading = true;

  int get _totalAnime => _library.length;
  int get _totalFinished =>
      _library.where((a) => a.watchStatus == WatchStatus.finished).length;
  int get _totalWatching =>
      _library.where((a) => a.watchStatus == WatchStatus.ongoing).length;

  final List<_TopFilter> _filters = const [
    _TopFilter(label: 'Top Rated', filter: null),
    _TopFilter(label: 'Airing', filter: 'airing'),
    _TopFilter(label: 'Popular', filter: 'bypopularity'),
    _TopFilter(label: 'Favorited', filter: 'favorite'),
    _TopFilter(label: 'Upcoming', filter: 'upcoming'),
  ];

  int _selectedFilter = 0;
  List<AnimeModel> _topAnime = [];
  bool _topLoading = false;

  @override
  void initState() {
    super.initState();
    _subscribeToLibrary();
    _loadTopAnime(0);
  }

  @override
  void dispose() {
    _librarySub?.cancel();
    super.dispose();
  }

  void _subscribeToLibrary() {
    _librarySub = _libraryService.libraryStream().listen((library) {
      if (!mounted) return;

      final ongoing =
          library.where((a) => a.watchStatus == WatchStatus.ongoing).toList()
            ..shuffle(Random());

      final recent = library.take(6).toList();

      setState(() {
        _library = library;
        _ongoingShuffled = ongoing;
        _recentlyAdded = recent;
        _loading = false;
      });
    });
  }

  Future<void> _loadTopAnime(int filterIndex) async {
    if (_topLoading) return;
    setState(() {
      _selectedFilter = filterIndex;
      _topLoading = true;
    });

    final data = await _api.getTopAnime(
      limit: 10,
      filter: _filters[filterIndex].filter,
    );

    if (!mounted) return;
    setState(() {
      _topAnime = data;
      _topLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    await _loadTopAnime(_selectedFilter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: _AnimuAppBar(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryViolet),
            )
          : RefreshIndicator(
              color: AppTheme.primaryViolet,
              backgroundColor: AppTheme.cardDark,
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingBanner(),
                    const SizedBox(height: 24),
                    // ── Continue Watching — no See All ────────────────────
                    _buildSection(
                      title: 'Continue Watching',
                      subtitle: 'Pick up where you left off',
                      showSeeAll: false,
                      child: _OngoingCarousel(animes: _ongoingShuffled),
                    ),
                    const SizedBox(height: 28),
                    // ── Recently Added — See All → Library tab ────────────
                    _buildSection(
                      title: 'Recently Added',
                      subtitle: 'From your library',
                      onSeeAll: () => widget.onNavigate?.call(1),
                      child: _HorizontalAnimeScroll(animes: _recentlyAdded),
                    ),
                    const SizedBox(height: 28),
                    _buildTopRankedSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Reusable section wrapper ───────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
    VoidCallback? onSeeAll,
    bool showSeeAll = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              if (showSeeAll)
                TextButton(
                  onPressed: onSeeAll,
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: AppTheme.primaryVioletLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  // ── Top Ranked section ────────────────────────────────────────────────────

  Widget _buildTopRankedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Ranked',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'Rankings from MyAnimeList',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TopAnimeScreen(initialFilterIndex: _selectedFilter),
                  ),
                ),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    color: AppTheme.primaryVioletLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Filter tabs
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = index == _selectedFilter;
              return GestureDetector(
                onTap: () => _loadTopAnime(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [
                              AppTheme.primaryViolet,
                              AppTheme.accentSakura,
                            ],
                          )
                        : null,
                    color: selected ? null : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? Colors.transparent : AppTheme.divider,
                    ),
                  ),
                  child: Text(
                    _filters[index].label,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        _topLoading
            ? const SizedBox(
                height: 220,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryViolet,
                  ),
                ),
              )
            : _HorizontalAnimeScroll(animes: _topAnime),
      ],
    );
  }

  // ── Greeting banner ───────────────────────────────────────────────────────

  Widget _buildGreetingBanner() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
        ? 'Good Afternoon'
        : 'Good Evening';

    final displayName = FirebaseAuth.instance.currentUser?.displayName;
    final firstName = displayName?.split(' ').first;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1A5E), Color(0xFF1A1030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryViolet.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName != null
                      ? '$greeting, $firstName! 👋'
                      : '$greeting! 👋',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ready to binge?',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 22,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatChip(
                      label: '$_totalAnime',
                      sublabel: 'Total',
                      color: AppTheme.primaryVioletLight,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: '$_totalFinished',
                      sublabel: 'Done',
                      color: AppTheme.accentCyan,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: '$_totalWatching',
                      sublabel: 'Watching',
                      color: AppTheme.accentSakura,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Image.asset(
            'assets/images/anime-drama.gif',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

// ── Filter model ──────────────────────────────────────────────────────────────

class _TopFilter {
  final String label;
  final String? filter;
  const _TopFilter({required this.label, required this.filter});
}

// ── AppBar ────────────────────────────────────────────────────────────────────

class _AnimuAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: RichText(
        text: const TextSpan(
          children: [
            TextSpan(
              text: 'Animu ',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: AppTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            TextSpan(
              text: 'アニム',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.primaryVioletLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color color;

  const _StatChip({
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            sublabel,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: AppTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Horizontal scroll ─────────────────────────────────────────────────────────

class _HorizontalAnimeScroll extends StatelessWidget {
  final List<AnimeModel> animes;
  const _HorizontalAnimeScroll({required this.animes});

  @override
  Widget build(BuildContext context) {
    if (animes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Text(
          'No anime here yet.',
          style: TextStyle(color: AppTheme.textMuted, fontFamily: 'Nunito'),
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: animes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final anime = animes[index];
          return SizedBox(
            width: 130,
            child: AnimeGridCard(
              anime: anime,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnimeDetailScreen(anime: anime),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Ongoing carousel ──────────────────────────────────────────────────────────

class _OngoingCarousel extends StatelessWidget {
  final List<AnimeModel> animes;
  const _OngoingCarousel({required this.animes});

  @override
  Widget build(BuildContext context) {
    if (animes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.divider),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.play_circle_outline_rounded,
                color: AppTheme.textMuted,
              ),
              SizedBox(width: 12),
              Text(
                'No ongoing anime. Start watching!',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (animes.length == 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _FullWidthCard(anime: animes.first),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: animes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _CompactCard(anime: animes[index]),
      ),
    );
  }
}

// ── Full-width card ───────────────────────────────────────────────────────────

class _FullWidthCard extends StatelessWidget {
  final AnimeModel anime;
  const _FullWidthCard({required this.anime});

  @override
  Widget build(BuildContext context) {
    final progress = (anime.episodesWatched != null && anime.episodes != null)
        ? (anime.episodesWatched! / anime.episodes!).clamp(0.0, 1.0)
        : null;
    final progressPct = progress != null ? (progress * 100).toInt() : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AnimeDetailScreen(anime: anime)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.statusOngoing.withOpacity(0.35)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                anime.bannerImageUrl ?? anime.coverImageUrl,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.72),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppTheme.cardElevated),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 100,
                      child: Image.network(
                        anime.coverImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.cardElevated,
                          child: const Icon(
                            Icons.broken_image_rounded,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        loadingBuilder: (_, child, p) {
                          if (p == null) return child;
                          return Container(
                            color: AppTheme.cardElevated,
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppTheme.primaryViolet,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.statusOngoing.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.statusOngoing.withOpacity(0.4),
                            ),
                          ),
                          child: const Text(
                            '▶  Watching',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              color: AppTheme.statusOngoing,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          anime.titleEnglish ?? anime.title,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (anime.type != null ||
                            anime.studio != null ||
                            anime.year != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            [
                              if (anime.type != null) anime.type!,
                              if (anime.studio != null) anime.studio!,
                              if (anime.year != null) '${anime.year}',
                            ].join(' · '),
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (progress != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: AppTheme.divider,
                                    valueColor: const AlwaysStoppedAnimation(
                                      AppTheme.statusOngoing,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$progressPct%',
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  color: AppTheme.statusOngoing,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Episode ${anime.episodesWatched} of ${anime.episodes}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compact card ──────────────────────────────────────────────────────────────

class _CompactCard extends StatelessWidget {
  final AnimeModel anime;
  const _CompactCard({required this.anime});

  @override
  Widget build(BuildContext context) {
    final progress = (anime.episodesWatched != null && anime.episodes != null)
        ? (anime.episodesWatched! / anime.episodes!).clamp(0.0, 1.0)
        : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AnimeDetailScreen(anime: anime)),
      ),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.statusOngoing.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 86,
                child: Image.network(
                  anime.coverImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.cardElevated,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ),
                  loadingBuilder: (_, child, p) {
                    if (p == null) return child;
                    return Container(
                      color: AppTheme.cardElevated,
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppTheme.primaryViolet,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
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
                  const SizedBox(height: 6),
                  if (progress != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppTheme.divider,
                        valueColor: const AlwaysStoppedAnimation(
                          AppTheme.statusOngoing,
                        ),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ep ${anime.episodesWatched} / ${anime.episodes}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.statusOngoing.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '▶  Watching',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: AppTheme.statusOngoing,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
