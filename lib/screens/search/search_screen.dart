// lib/screens/search/search_screen.dart

import 'package:flutter/material.dart';
import '../../models/anime_model.dart';
import '../../services/anime_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anime_card/anime_grid_card.dart';
import '../detail/anime_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _api = AnimeApiService();
  final _searchController = TextEditingController();
  List<AnimeModel> _results = [];
  List<AnimeModel> _trending = [];
  bool _searching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    final results = await _api.getTopAnime(limit: 6);
    if (!mounted) return;
    setState(() => _trending = results);
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = []; _hasSearched = false; });
      return;
    }
    setState(() => _searching = true);
    final results = await _api.searchAnime(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
      _hasSearched = true;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Discover',
          style: TextStyle(
            fontFamily: 'Nunito', fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary, fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              style: const TextStyle(fontFamily: 'Nunito', color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search anime titles...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
                : _hasSearched
                    ? _SearchResults(
                        results: _results,
                        query: _searchController.text,
                      )
                    : _TrendingSection(animes: _trending),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<AnimeModel> results;
  final String query;

  const _SearchResults({required this.results, required this.query});

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
              style: const TextStyle(fontFamily: 'Nunito', color: AppTheme.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different search term',
              style: TextStyle(fontFamily: 'Nunito', color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) => AnimeListCard(
        anime: results[index],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AnimeDetailScreen(anime: results[index])),
        ),
      ),
    );
  }
}

class _TrendingSection extends StatelessWidget {
  final List<AnimeModel> animes;
  const _TrendingSection({required this.animes});

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
              fontFamily: 'Nunito', fontSize: 18,
              fontWeight: FontWeight.w800, color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Most beloved anime of all time',
            style: TextStyle(fontFamily: 'Nunito', color: AppTheme.textMuted, fontSize: 12),
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
            itemBuilder: (context, index) => AnimeGridCard(
              anime: animes[index],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AnimeDetailScreen(anime: animes[index])),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
