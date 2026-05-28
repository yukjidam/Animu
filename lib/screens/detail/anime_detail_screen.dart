// lib/screens/detail/anime_detail_screen.dart

import 'package:flutter/material.dart';
import '../../models/anime_model.dart';
import '../../services/anime_api_service.dart';
import '../../services/library_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/star_rating.dart';
import '../review/review_screen.dart';

class AnimeDetailScreen extends StatefulWidget {
  final AnimeModel anime;
  const AnimeDetailScreen({super.key, required this.anime});

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  late AnimeModel _anime;
  final _api = AnimeApiService();
  final _library = LibraryService(); // ← added

  @override
  void initState() {
    super.initState();
    _anime = widget.anime;
  }

  Future<void> _saveToLibrary(WatchStatus status) async {
    setState(() {
      _anime = _anime.copyWith(
        watchStatus: status,
        dateAdded: _anime.dateAdded ?? DateTime.now(),
      );
    });

    // ── Save to Firestore via LibraryService ──────────────────────────
    await _library.addAnime(_anime);
    // ─────────────────────────────────────────────────────────────────

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.cardElevated,
        content: Text(
          '${status.emoji} Added to "${status.label}"',
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: AppTheme.textPrimary,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: 16),
                  _buildMetaChips(),
                  const SizedBox(height: 20),
                  _buildWatchStatusSelector(),
                  const SizedBox(height: 20),
                  if (_anime.synopsis != null) _buildSynopsis(),
                  const SizedBox(height: 20),
                  if (_anime.watchStatus != null) _buildUserSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: AppTheme.backgroundDark,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_anime.bannerImageUrl != null ||
                _anime.coverImageUrl.isNotEmpty)
              Image.network(
                _anime.bannerImageUrl ?? _anime.coverImageUrl,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.5),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppTheme.cardDark),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [AppTheme.backgroundDark, Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _anime.coverImageUrl,
                      width: 100,
                      height: 145,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 145,
                        color: AppTheme.cardElevated,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_anime.score != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.accentGold.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppTheme.accentGold,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _anime.score!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  color: AppTheme.accentGold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_anime.watchStatus != null) ...[
                        const SizedBox(height: 8),
                        StatusBadge(status: _anime.watchStatus!),
                      ],
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

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _anime.titleEnglish ?? _anime.title,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary,
            height: 1.2,
          ),
        ),
        if (_anime.titleJapanese != null) ...[
          const SizedBox(height: 4),
          Text(
            _anime.titleJapanese!,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetaChips() {
    final metas = [
      if (_anime.type != null) ('📺', _anime.type!),
      if (_anime.episodes != null) ('🎬', '${_anime.episodes} eps'),
      if (_anime.season != null) ('📅', _anime.season!),
      if (_anime.studio != null) ('🎨', _anime.studio!),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...metas.map((m) => _MetaChip(emoji: m.$1, label: m.$2)),
        ..._anime.genres.take(3).map((g) => _GenreChip(label: g)),
      ],
    );
  }

  Widget _buildWatchStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add to Library',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: WatchStatus.values.map((status) {
            final selected = _anime.watchStatus == status;
            return Expanded(
              child: GestureDetector(
                onTap: () => _saveToLibrary(status),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primaryViolet
                        : AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primaryViolet
                          : AppTheme.divider,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(status.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(
                        status.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSynopsis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Synopsis',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _ExpandableSynopsis(text: _anime.synopsis!),
      ],
    );
  }

  Widget _buildUserSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Review',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final updated = await Navigator.push<AnimeModel>(
              context,
              MaterialPageRoute(builder: (_) => ReviewScreen(anime: _anime)),
            );
            if (updated != null) setState(() => _anime = updated);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _anime.userRating != null
                    ? AppTheme.primaryViolet.withOpacity(0.4)
                    : AppTheme.divider,
              ),
            ),
            child: _anime.userRating != null
                ? _FilledReviewPreview(anime: _anime)
                : const _EmptyReviewPrompt(),
          ),
        ),
      ],
    );
  }
}

// ── Supporting widgets (unchanged) ────────────────────────────────────────────

class _FilledReviewPreview extends StatelessWidget {
  final AnimeModel anime;
  const _FilledReviewPreview({required this.anime});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StarRating(rating: anime.userRating!, starSize: 20),
            const SizedBox(width: 8),
            if (anime.userEmojiRating != null)
              Text(
                anime.userEmojiRating!,
                style: const TextStyle(fontSize: 20),
              ),
            const Spacer(),
            const Icon(Icons.edit_rounded, color: AppTheme.textMuted, size: 16),
          ],
        ),
        if (anime.userReview != null && anime.userReview!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            anime.userReview!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyReviewPrompt extends StatelessWidget {
  const _EmptyReviewPrompt();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(
          Icons.rate_review_rounded,
          color: AppTheme.primaryVioletLight,
          size: 20,
        ),
        SizedBox(width: 10),
        Text(
          'Tap to rate & write a review',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Spacer(),
        Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ],
    );
  }
}

class _ExpandableSynopsis extends StatefulWidget {
  final String text;
  const _ExpandableSynopsis({required this.text});

  @override
  State<_ExpandableSynopsis> createState() => _ExpandableSynopsisState();
}

class _ExpandableSynopsisState extends State<_ExpandableSynopsis> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Read more',
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: AppTheme.primaryVioletLight,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String emoji;
  final String label;
  const _MetaChip({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  const _GenreChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryViolet.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Nunito',
          color: AppTheme.primaryVioletLight,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
