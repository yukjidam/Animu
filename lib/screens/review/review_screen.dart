// lib/screens/review/review_screen.dart

import 'package:flutter/material.dart';
import '../../models/anime_model.dart';
import '../../services/library_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/star_rating.dart';

class ReviewScreen extends StatefulWidget {
  final AnimeModel anime;
  const ReviewScreen({super.key, required this.anime});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _library = LibraryService();
  final _reviewController = TextEditingController();
  double _starRating = 0;
  String? _emojiRating;
  bool _saving = false;

  static const List<String> _emojiOptions = [
    '🔥',
    '❤️',
    '✨',
    '💀',
    '😭',
    '🤯',
    '👑',
    '💯',
    '😐',
    '🗑️',
  ];

  @override
  void initState() {
    super.initState();
    _starRating = widget.anime.userRating ?? 0;
    _emojiRating = widget.anime.userEmojiRating;
    _reviewController.text = widget.anime.userReview ?? '';
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _saveReview() async {
    setState(() => _saving = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      debugPrint('▶ _saveReview: building updated model');
      final updated = widget.anime.copyWith(
        userRating: _starRating > 0 ? _starRating : null,
        userEmojiRating: _emojiRating,
        userReview: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
        dateFinished: widget.anime.watchStatus == WatchStatus.finished
            ? (widget.anime.dateFinished ?? DateTime.now())
            : null,
      );

      debugPrint('▶ _saveReview: calling addAnime...');
      await _library.addAnime(updated);
      debugPrint('✅ _saveReview: addAnime complete — popping now');

      navigator.pop(updated);
      debugPrint('✅ _saveReview: pop called');
    } catch (e, stack) {
      debugPrint('❌ _saveReview error: $e');
      debugPrint('$stack');
      if (mounted) setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save: $e',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppTheme.statusDropped,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Write Review',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveReview,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryViolet,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryVioletLight,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnimeHeader(anime: widget.anime),
            const SizedBox(height: 28),

            _SectionLabel(label: 'Star Rating', emoji: '⭐'),
            const SizedBox(height: 14),
            Center(
              child: Column(
                children: [
                  InteractiveStarRating(
                    initialRating: _starRating,
                    onRatingChanged: (v) => setState(() => _starRating = v),
                    starSize: 44,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _starRating > 0
                        ? '${_starRating % 1 == 0 ? _starRating.toInt() : _starRating} / 5'
                        : 'Tap a star to rate',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _SectionLabel(label: 'Emoji Reaction', emoji: '🎭'),
            const SizedBox(height: 14),
            _EmojiPicker(
              selected: _emojiRating,
              options: _emojiOptions,
              onSelected: (e) =>
                  setState(() => _emojiRating = _emojiRating == e ? null : e),
            ),
            const SizedBox(height: 28),

            _SectionLabel(label: 'Your Review', emoji: '✍️'),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: TextField(
                controller: _reviewController,
                maxLines: 8,
                minLines: 5,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  height: 1.6,
                ),
                decoration: const InputDecoration(
                  hintText:
                      'Share your thoughts about this anime...\n\nWhat did you love? What could be better? Who was your favourite character?',
                  hintStyle: TextStyle(
                    fontFamily: 'Nunito',
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ValueListenableBuilder(
                valueListenable: _reviewController,
                builder: (_, value, __) => Text(
                  '${value.text.length} chars',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Review',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimeHeader extends StatelessWidget {
  final AnimeModel anime;
  const _AnimeHeader({required this.anime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              anime.coverImageUrl,
              width: 50,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 70,
                color: AppTheme.cardElevated,
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
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (anime.type != null || anime.year != null)
                  Text(
                    [
                      if (anime.type != null) anime.type!,
                      if (anime.year != null) '${anime.year}',
                    ].join(' · '),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final String emoji;
  const _SectionLabel({required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  final String? selected;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const _EmojiPicker({
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((emoji) {
        final isSelected = selected == emoji;
        return GestureDetector(
          onTap: () => onSelected(emoji),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryViolet.withOpacity(0.2)
                  : AppTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppTheme.primaryViolet : AppTheme.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
