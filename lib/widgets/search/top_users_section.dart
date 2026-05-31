// lib/widgets/search/top_users_section.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../screens/profile/public_profile_screen.dart';
// ── Data model ────────────────────────────────────────────────────────────────

class UserEntry {
  final String uid;
  final String? displayName;
  final String? photoURL;
  final int watchedCount;
  final int reviewCount;

  const UserEntry({
    required this.uid,
    required this.displayName,
    required this.photoURL,
    required this.watchedCount,
    required this.reviewCount,
  });

  factory UserEntry.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return UserEntry(
      uid: doc.id,
      displayName: d['displayName'] as String?,
      photoURL: d['photoURL'] as String?,
      watchedCount: (d['watchedCount'] as num?)?.toInt() ?? 0,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── TopUsersSection widget ────────────────────────────────────────────────────

class TopUsersSection extends StatefulWidget {
  const TopUsersSection({super.key});

  @override
  State<TopUsersSection> createState() => _TopUsersSectionState();
}

class _TopUsersSectionState extends State<TopUsersSection>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  List<UserEntry> _topWatched = [];
  List<UserEntry> _topReviewers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboards();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboards() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _firestore
            .collection('users')
            .orderBy('watchedCount', descending: true)
            .limit(5)
            .get(),
        _firestore
            .collection('users')
            .orderBy('reviewCount', descending: true)
            .limit(5)
            .get(),
      ]);

      if (!mounted) return;
      setState(() {
        _topWatched = results[0].docs
            .map((d) => UserEntry.fromDoc(d))
            .where((u) => u.watchedCount > 0)
            .toList();
        _topReviewers = results[1].docs
            .map((d) => UserEntry.fromDoc(d))
            .where((u) => u.reviewCount > 0)
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '👥 Top Users',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Community\'s most active members',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: AppTheme.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),

        // Tab bar
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryViolet, AppTheme.accentSakura],
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
              Tab(text: '✅  Top Watched'),
              Tab(text: '✍️  Top Reviewers'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryViolet,
                    strokeWidth: 2,
                  ),
                ),
              )
            : SizedBox(
                height: 38.0 * 5 + 4.0 * 4,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _LeaderboardList(
                      entries: _topWatched,
                      statLabel: 'watched',
                      statValue: (e) => e.watchedCount,
                      emptyMessage: 'No watched data yet',
                    ),
                    _LeaderboardList(
                      entries: _topReviewers,
                      statLabel: 'reviews',
                      statValue: (e) => e.reviewCount,
                      emptyMessage: 'No reviews yet',
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}

// ── Leaderboard list ──────────────────────────────────────────────────────────

class _LeaderboardList extends StatelessWidget {
  final List<UserEntry> entries;
  final String statLabel;
  final int Function(UserEntry) statValue;
  final String emptyMessage;

  const _LeaderboardList({
    required this.entries,
    required this.statLabel,
    required this.statValue,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            fontFamily: 'Nunito',
            color: AppTheme.textMuted,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) => _UserRow(
        entry: entries[index],
        rank: index + 1,
        statLabel: statLabel,
        statValue: statValue(entries[index]),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              uid: entries[index].uid,
              preloadedName: entries[index].displayName,
              preloadedPhotoURL: entries[index].photoURL,
            ),
          ),
        ),
      ),
    );
  }
}

// ── User row ──────────────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  final UserEntry entry;
  final int rank;
  final String statLabel;
  final int statValue;
  final VoidCallback onTap;

  const _UserRow({
    required this.entry,
    required this.rank,
    required this.statLabel,
    required this.statValue,
    required this.onTap,
  });

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFB0BEC5);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppTheme.textMuted;
    }
  }

  String get _rankLabel {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rank <= 3 ? _rankColor.withOpacity(0.25) : AppTheme.divider,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                _rankLabel,
                style: rank <= 3
                    ? const TextStyle(fontSize: 16)
                    : TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _rankColor,
                      ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            _Avatar(photoURL: entry.photoURL, size: 24, radius: 7),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.displayName ?? 'Anonymous',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$statValue ',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppTheme.primaryViolet,
                    ),
                  ),
                  TextSpan(
                    text: statLabel,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared avatar widget ──────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? photoURL;
  final double size;
  final double radius;

  const _Avatar({
    required this.photoURL,
    required this.size,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryViolet, AppTheme.accentSakura],
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: photoURL != null
            ? Image.network(
                photoURL!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('🧑', style: TextStyle(fontSize: 12)),
                ),
              )
            : const Center(child: Text('🧑', style: TextStyle(fontSize: 12))),
      ),
    );
  }
}

// ── UserSearchDelegate — in-memory, case-insensitive substring search ─────────
//
// Instead of relying on Firestore range queries (which only do prefix matching
// and require an index), we load ALL users once and filter client-side.
// This means "nar" matches "Naruto", "tuna" matches "Fortunate" etc.

class UserSearchDelegate extends SearchDelegate<UserEntry?> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _currentUid = FirebaseAuth.instance.currentUser?.uid;

  // Cache the full user list so we only fetch once per delegate instance
  List<UserEntry>? _allUsers;
  bool _loadedUsers = false;

  @override
  String get searchFieldLabel => 'Search users...';

  @override
  TextStyle get searchFieldStyle => const TextStyle(
    fontFamily: 'Nunito',
    color: AppTheme.textPrimary,
    fontSize: 15,
  );

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textSecondary),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(fontFamily: 'Nunito', color: AppTheme.textMuted),
      ),
      scaffoldBackgroundColor: AppTheme.backgroundDark,
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textSecondary),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildBody(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildBody(context);

  Widget _buildBody(BuildContext context) {
    // Empty query — show hint
    if (query.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔎', style: TextStyle(fontSize: 40)),
            SizedBox(height: 12),
            Text(
              'Search by display name',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Finds partial matches — try "nar" for Naruto fans',
              style: TextStyle(
                fontFamily: 'Nunito',
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Load users once, then filter in-memory on every query change
    return FutureBuilder<List<UserEntry>>(
      future: _getUsers(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryViolet,
              strokeWidth: 2,
            ),
          );
        }

        if (snap.hasError) {
          return Center(
            child: Text(
              'Error loading users',
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: AppTheme.textMuted,
              ),
            ),
          );
        }

        final q = query.trim().toLowerCase();
        final filtered = (snap.data ?? [])
            .where(
              (u) =>
                  u.uid != _currentUid &&
                  // Substring match — works for any part of the name
                  (u.displayName ?? '').toLowerCase().contains(q),
            )
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👤', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  'No users found for "$query"',
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

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final e = filtered[index];
            return _SearchUserTile(
              entry: e,
              query: q,
              onTap: () {
                close(context, e);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PublicProfileScreen(
                      uid: e.uid,
                      preloadedName: e.displayName,
                      preloadedPhotoURL: e.photoURL,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Loads all users once and caches them for the lifetime of this delegate.
  Future<List<UserEntry>> _getUsers() async {
    if (_loadedUsers) return _allUsers ?? [];
    _loadedUsers = true;
    try {
      final snap = await _firestore.collection('users').limit(500).get();
      _allUsers = snap.docs.map((d) => UserEntry.fromDoc(d)).toList();
    } catch (_) {
      _allUsers = [];
    }
    return _allUsers!;
  }
}

// ── Search result tile with highlighted match ─────────────────────────────────

class _SearchUserTile extends StatelessWidget {
  final UserEntry entry;
  final String query;
  final VoidCallback onTap;

  const _SearchUserTile({
    required this.entry,
    required this.query,
    required this.onTap,
  });

  /// Builds a RichText that bolds the matched substring.
  Widget _highlightedName() {
    final name = entry.displayName ?? 'Anonymous';
    final lower = name.toLowerCase();
    final idx = lower.indexOf(query);

    if (idx < 0 || query.isEmpty) {
      return Text(
        name,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        children: [
          if (idx > 0)
            TextSpan(
              text: name.substring(0, idx),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          TextSpan(
            text: name.substring(idx, idx + query.length),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: AppTheme.primaryVioletLight,
            ),
          ),
          if (idx + query.length < name.length)
            TextSpan(
              text: name.substring(idx + query.length),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            _Avatar(photoURL: entry.photoURL, size: 42, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _highlightedName(),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.watchedCount} watched · ${entry.reviewCount} reviews',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
