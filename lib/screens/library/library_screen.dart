import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../models/anime_model.dart';
import '../../services/library_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/anime_card/anime_grid_card.dart';
import '../../widgets/common/ani_app_bar.dart';
import '../detail/anime_detail_screen.dart';
import '../search/search_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _service = LibraryService();

  WatchStatus? _filterStatus;
  bool _isGridView = true;

  List<AnimeModel> _applyFilter(List<AnimeModel> all) {
    if (_filterStatus == null) return all;
    return all.where((a) => a.watchStatus == _filterStatus).toList();
  }

  Map<WatchStatus, int> _buildCounts(List<AnimeModel> all) => {
    for (final s in WatchStatus.values)
      s: all.where((a) => a.watchStatus == s).length,
  };

  void _removeAnime(BuildContext context, AnimeModel anime) async {
    final t = AppTheme.of(context);
    await _service.removeAnime(anime.id.toString());
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: t.cardDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          '${anime.title} removed.',
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: AppTheme.textPrimary,
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: t.primaryVioletLight,
          onPressed: () => _service.addAnime(anime),
        ),
      ),
    );
  }

  void _showStatusSheet(BuildContext context, AnimeModel anime) {
    final t = AppTheme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: t.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              anime.title,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            const Text(
              'Change status',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            ...WatchStatus.values.map(
              (s) => _StatusTile(
                status: s,
                isSelected: anime.watchStatus == s,
                onTap: () async {
                  Navigator.pop(context);
                  await _service.updateStatus(anime.id.toString(), s);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: t.backgroundDark,
        body: Center(
          child: Text(
            'Please log in to view your library.',
            style: TextStyle(fontFamily: 'Nunito', color: AppTheme.textMuted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: t.backgroundDark,
      appBar: AniAppBar(
        title: 'My Library',
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        backgroundColor: t.primaryViolet,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Anime',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: StreamBuilder<List<AnimeModel>>(
        stream: _service.libraryStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: t.primaryViolet),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text(
                    'Something went wrong.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final all = snapshot.data ?? [];
          final filtered = _applyFilter(all);
          final counts = _buildCounts(all);

          return Column(
            children: [
              _FilterRow(
                selected: _filterStatus,
                onSelected: (s) => setState(() => _filterStatus = s),
                counts: counts,
                t: t,
              ),
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyLibrary(status: _filterStatus)
                    : RefreshIndicator(
                        color: t.primaryViolet,
                        backgroundColor: t.cardDark,
                        onRefresh: () async {},
                        child: _isGridView
                            ? _GridBody(
                                animes: filtered,
                                onLongPress: (anime) =>
                                    _showStatusSheet(context, anime),
                                onDelete: (anime) =>
                                    _removeAnime(context, anime),
                              )
                            : _ListBody(
                                animes: filtered,
                                onLongPress: (anime) =>
                                    _showStatusSheet(context, anime),
                                onDelete: (anime) =>
                                    _removeAnime(context, anime),
                              ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Status tile ────────────────────────────────────────────────────────────

class _StatusTile extends StatelessWidget {
  final WatchStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusTile({
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Text(status.emoji, style: const TextStyle(fontSize: 20)),
      title: Text(
        status.label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: isSelected ? t.primaryVioletLight : AppTheme.textPrimary,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: t.primaryVioletLight)
          : null,
    );
  }
}

// ── Filter row ─────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  final WatchStatus? selected;
  final ValueChanged<WatchStatus?> onSelected;
  final Map<WatchStatus, int> counts;
  final AppThemeTokens t;

  const _FilterRow({
    required this.selected,
    required this.onSelected,
    required this.counts,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      (null, 'All', '📚'),
      (WatchStatus.ongoing, 'Watching', '▶️'),
      (WatchStatus.finished, 'Finished', '✅'),
      (WatchStatus.planToWatch, 'Plan to Watch', '📋'),
      (WatchStatus.dropped, 'Dropped', '🚫'),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (status, label, emoji) = filters[index];
          final isSelected = selected == status;
          final count = status != null ? counts[status] : null;

          return GestureDetector(
            onTap: () => onSelected(status),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? t.primaryViolet : t.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? t.primaryViolet : t.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : t.primaryViolet.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : t.primaryVioletLight,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Grid body ──────────────────────────────────────────────────────────────

class _GridBody extends StatelessWidget {
  final List<AnimeModel> animes;
  final void Function(AnimeModel) onLongPress;
  final void Function(AnimeModel) onDelete;

  const _GridBody({
    required this.animes,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: animes.length,
      itemBuilder: (context, index) {
        final anime = animes[index];
        return GestureDetector(
          onLongPress: () => onLongPress(anime),
          child: Dismissible(
            key: ValueKey(anime.id.toString()),
            direction: DismissDirection.vertical,
            background: const _DismissBackground(),
            onDismissed: (_) => onDelete(anime),
            child: AnimeGridCard(
              anime: anime,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnimeDetailScreen(anime: anime),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── List body ──────────────────────────────────────────────────────────────

class _ListBody extends StatelessWidget {
  final List<AnimeModel> animes;
  final void Function(AnimeModel) onLongPress;
  final void Function(AnimeModel) onDelete;

  const _ListBody({
    required this.animes,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: animes.length,
      itemBuilder: (context, index) {
        final anime = animes[index];
        return GestureDetector(
          onLongPress: () => onLongPress(anime),
          child: Dismissible(
            key: ValueKey(anime.id.toString()),
            direction: DismissDirection.endToStart,
            background: const _DismissBackground(fromEnd: true),
            onDismissed: (_) => onDelete(anime),
            child: AnimeListCard(
              anime: anime,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnimeDetailScreen(anime: anime),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Dismiss background ─────────────────────────────────────────────────────

class _DismissBackground extends StatelessWidget {
  final bool fromEnd;
  const _DismissBackground({this.fromEnd = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: fromEnd ? Alignment.centerRight : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyLibrary extends StatelessWidget {
  final WatchStatus? status;
  const _EmptyLibrary({this.status});

  @override
  Widget build(BuildContext context) {
    final message = status == null
        ? 'Your library is empty.\nSearch and add some anime!'
        : 'No anime with "${status!.label}" status yet.';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              color: AppTheme.textMuted,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
