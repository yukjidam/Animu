// lib/screens/search/search_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/anime_model.dart';
import '../../services/anime_api_service.dart';
import '../../services/library_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anime_card/anime_grid_card.dart';
import '../../widgets/search/top_users_section.dart';
import '../detail/anime_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = AnimeApiService();
  final _library = LibraryService();
  final _searchController = TextEditingController();

  List<AnimeModel> _results = [];
  List<AnimeModel> _trending = [];
  Map<int, AnimeModel> _libraryMap = {};
  StreamSubscription<List<AnimeModel>>? _librarySub;

  bool _searching = false;
  bool _hasSearched = false;

  Timer? _debounce;
  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    _subscribeToLibrary();
    _loadTrending();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _librarySub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _subscribeToLibrary() {
    _librarySub = _library.libraryStream().listen((list) {
      if (!mounted) return;
      setState(() {
        _libraryMap = {for (final a in list) a.id: a};
      });
    });
  }

  AnimeModel _merge(AnimeModel api) {
    final saved = _libraryMap[api.id];
    if (saved == null) return api;
    return api.copyWith(
      watchStatus: saved.watchStatus,
      userRating: saved.userRating,
      userEmojiRating: saved.userEmojiRating,
      userReview: saved.userReview,
      dateAdded: saved.dateAdded,
      dateFinished: saved.dateFinished,
      episodesWatched: saved.episodesWatched,
    );
  }

  Future<void> _loadTrending() async {
    final results = await _api.getTopAnime(limit: 20);
    if (!mounted) return;
    setState(() => _trending = results.take(6).toList());
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _search(query.trim()),
    );
  }

  Future<void> _search(String query) async {
    _activeQuery = query;
    final raw = await _api.searchAnime(query);
    if (!mounted) return;
    if (_activeQuery != query) return;

    final q = query.toLowerCase();
    final sorted = List<AnimeModel>.from(raw)
      ..sort((a, b) {
        int score(AnimeModel m) {
          final t = (m.titleEnglish ?? m.title).toLowerCase();
          if (t == q) return 0;
          if (t.startsWith(q)) return 1;
          if (t.contains(q)) return 2;
          return 3;
        }

        return score(a).compareTo(score(b));
      });

    setState(() {
      _results = sorted;
      _searching = false;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Scaffold(
      backgroundColor: t.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Discover',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            fontSize: 22,
          ),
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search anime titles...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.textMuted,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.textMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _searching
                ? Center(
                    child: CircularProgressIndicator(color: t.primaryViolet),
                  )
                : _hasSearched
                ? _SearchResults(
                    results: _results,
                    query: _searchController.text.trim(),
                    merge: _merge,
                  )
                : _DiscoverSection(animes: _trending, merge: _merge),
          ),
        ],
      ),
    );
  }
}

// ── Search results ─────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final List<AnimeModel> results;
  final String query;
  final AnimeModel Function(AnimeModel) merge;

  const _SearchResults({
    required this.results,
    required this.query,
    required this.merge,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No results for "$query"',
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: AppTheme.textMuted,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different search term',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: AppTheme.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final anime = merge(results[index]);
        return AnimeListCard(
          anime: anime,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AnimeDetailScreen(anime: anime)),
          ),
        );
      },
    );
  }
}

// ── Discover section ───────────────────────────────────────────────────────

class _DiscoverSection extends StatelessWidget {
  final List<AnimeModel> animes;
  final AnimeModel Function(AnimeModel) merge;

  const _DiscoverSection({required this.animes, required this.merge});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Top Rated',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Most beloved anime of all time',
            style: TextStyle(
              fontFamily: 'Nunito',
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.58,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: animes.length,
            itemBuilder: (context, index) {
              final anime = merge(animes[index]);
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
          const SizedBox(height: 32),
          const TopUsersSection(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
