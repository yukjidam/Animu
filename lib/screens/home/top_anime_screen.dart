// lib/screens/home/top_anime_screen.dart

import 'package:flutter/material.dart';
import '../../models/anime_model.dart';
import '../../services/anime_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anime_card/anime_grid_card.dart';
import '../detail/anime_detail_screen.dart';

class TopAnimeScreen extends StatefulWidget {
  final int initialFilterIndex;
  const TopAnimeScreen({super.key, this.initialFilterIndex = 0});

  @override
  State<TopAnimeScreen> createState() => _TopAnimeScreenState();
}

class _TopAnimeScreenState extends State<TopAnimeScreen> {
  final _api = AnimeApiService();
  final _scrollController = ScrollController();

  static const _filters = [
    _TopFilter(label: 'Top Rated', filter: null),
    _TopFilter(label: 'Airing', filter: 'airing'),
    _TopFilter(label: 'Popular', filter: 'bypopularity'),
    _TopFilter(label: 'Favorited', filter: 'favorite'),
    _TopFilter(label: 'Upcoming', filter: 'upcoming'),
  ];

  late int _selectedFilter;
  List<AnimeModel> _anime = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilterIndex;
    _scrollController.addListener(_onScroll);
    _fetchPage(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_loadingMore &&
        _hasMore) {
      _fetchMore();
    }
  }

  Future<void> _fetchPage({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _anime = [];
        _page = 1;
        _hasMore = true;
      });
    }
    final data = await _api.getTopAnime(
      limit: 20,
      page: _page,
      filter: _filters[_selectedFilter].filter,
    );
    if (!mounted) return;
    setState(() {
      _anime = data;
      _loading = false;
      _hasMore = data.length == 20;
    });
  }

  Future<void> _fetchMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final data = await _api.getTopAnime(
      limit: 20,
      page: _page + 1,
      filter: _filters[_selectedFilter].filter,
    );
    if (!mounted) return;
    setState(() {
      _page += 1;
      _anime.addAll(data);
      _loadingMore = false;
      _hasMore = data.length == 20;
    });
  }

  void _switchFilter(int index) {
    if (index == _selectedFilter) return;
    _selectedFilter = index;
    _fetchPage(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.backgroundDark,
      appBar: AppBar(
        backgroundColor: t.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Top Ranked',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Filter tabs ────────────────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _selectedFilter;
                return GestureDetector(
                  onTap: () => _switchFilter(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(
                              colors: [t.primaryViolet, t.accentSakura],
                            )
                          : null,
                      color: selected ? null : t.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? Colors.transparent : t.divider,
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

          const SizedBox(height: 8),

          // ── Grid ───────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(color: t.primaryViolet),
                  )
                : _anime.isEmpty
                ? const Center(
                    child: Text(
                      'No results found.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: AppTheme.textMuted,
                      ),
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.52,
                        ),
                    itemCount: _anime.length + (_loadingMore ? 3 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _anime.length) {
                        return _SkeletonCard(t: t);
                      }
                      final anime = _anime[index];
                      return AnimeGridCard(
                        anime: anime,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AnimeDetailScreen(anime: anime),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton placeholder card ─────────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  final AppThemeTokens t;
  const _SkeletonCard({required this.t});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.4, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Opacity(
        opacity: _animation.value,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: widget.t.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: widget.t.cardDark,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 10,
              width: 60,
              decoration: BoxDecoration(
                color: widget.t.cardDark,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
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
