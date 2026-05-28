// lib/widgets/anime_card/anime_grid_card.dart

import 'package:flutter/material.dart';
import '../../models/anime_model.dart';
import '../../theme/app_theme.dart';
import '../common/star_rating.dart';

class AnimeGridCard extends StatelessWidget {
  final AnimeModel anime;
  final VoidCallback? onTap;

  const AnimeGridCard({super.key, required this.anime, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover Image ──────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _CoverImage(url: anime.coverImageUrl),

                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [AppTheme.cardDark, Colors.transparent],
                            ),
                          ),
                        ),
                      ),

                      // Emoji rating top-right
                      if (anime.userEmojiRating != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              anime.userEmojiRating!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Info section ─────────────────────────────────────
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          anime.titleEnglish ?? anime.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            fontFamily: 'Nunito',
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 2),

                        // Status tag OR score
                        anime.watchStatus != null
                            ? _StatusTag(status: anime.watchStatus!)
                            : anime.score != null
                            ? Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: AppTheme.accentGold,
                                    size: 11,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      anime.score!.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status tag ─────────────────────────────────────────────────────────────

class _StatusTag extends StatelessWidget {
  final WatchStatus status;
  const _StatusTag({required this.status});

  Color get _color {
    switch (status) {
      case WatchStatus.ongoing:
        return const Color(0xFF3B82F6);
      case WatchStatus.finished:
        return const Color(0xFF22C55E);
      case WatchStatus.planToWatch:
        return const Color(0xFFA855F7);
      case WatchStatus.dropped:
        return const Color(0xFFEF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status.emoji, style: const TextStyle(fontSize: 9)),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              status.label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── List card ──────────────────────────────────────────────────────────────

class AnimeListCard extends StatelessWidget {
  final AnimeModel anime;
  final VoidCallback? onTap;

  const AnimeListCard({super.key, required this.anime, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider, width: 1),
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 85,
                child: _CoverImage(url: anime.coverImageUrl),
              ),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.titleEnglish ?? anime.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      fontFamily: 'Nunito',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  if (anime.type != null || anime.episodes != null)
                    Text(
                      [
                        if (anime.type != null) anime.type!,
                        if (anime.episodes != null) '${anime.episodes} eps',
                      ].join(' · '),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                        fontFamily: 'Nunito',
                      ),
                    ),

                  const SizedBox(height: 6),

                  // Status tag replaces StatusBadge
                  if (anime.watchStatus != null)
                    _StatusTag(status: anime.watchStatus!),

                  const SizedBox(height: 6),

                  if (anime.userRating != null)
                    Row(
                      children: [
                        StarRating(rating: anime.userRating!, starSize: 14),
                        if (anime.userEmojiRating != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            anime.userEmojiRating!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),

                  // Progress bar for ongoing
                  if (anime.watchStatus == WatchStatus.ongoing &&
                      anime.episodesWatched != null &&
                      anime.episodes != null) ...[
                    const SizedBox(height: 6),
                    _EpisodeProgress(
                      watched: anime.episodesWatched!,
                      total: anime.episodes!,
                    ),
                  ],
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _CoverImage extends StatelessWidget {
  final String url;
  const _CoverImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppTheme.cardElevated,
        child: const Center(
          child: Icon(Icons.broken_image_rounded, color: AppTheme.textMuted),
        ),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppTheme.cardElevated,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryViolet,
            ),
          ),
        );
      },
    );
  }
}

class _EpisodeProgress extends StatelessWidget {
  final int watched;
  final int total;
  const _EpisodeProgress({required this.watched, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = (watched / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.divider,
            valueColor: const AlwaysStoppedAnimation(AppTheme.statusOngoing),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$watched / $total eps',
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }
}
