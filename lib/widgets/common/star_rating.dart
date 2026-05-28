// lib/widgets/common/star_rating.dart

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class StarRating extends StatelessWidget {
  final double rating;       // 0.0 – 5.0
  final double starSize;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.starSize = 20,
    this.interactive = false,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        final filled = rating >= starValue;
        final halfFilled = !filled && rating >= starValue - 0.5;

        IconData icon = filled
            ? Icons.star_rounded
            : halfFilled
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;

        Color color = filled || halfFilled
            ? AppTheme.accentGold
            : AppTheme.textMuted;

        if (interactive) {
          return GestureDetector(
            onTap: () => onRatingChanged?.call(starValue),
            onHorizontalDragUpdate: (details) {
              // Allow half-star tap by checking drag position
            },
            child: Icon(icon, size: starSize, color: color),
          );
        }

        return Icon(icon, size: starSize, color: color);
      }),
    );
  }
}

/// Interactive half-star rating row used in review screens.
class InteractiveStarRating extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final double starSize;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.starSize = 36,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  void _setRating(double value) {
    setState(() => _rating = value);
    widget.onRatingChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox;
            final localPos = box.globalToLocal(details.globalPosition);
            final starWidth = box.size.width / 5;
            final starIndex = (localPos.dx / starWidth).floor();
            final withinStar = (localPos.dx % starWidth) / starWidth;
            final newRating = withinStar < 0.5
                ? starIndex + 0.5
                : starIndex + 1.0;
            _setRating(newRating.clamp(0.5, 5.0));
          },
          child: _StarIcon(
            value: index + 1.0,
            rating: _rating,
            size: widget.starSize,
          ),
        );
      }),
    );
  }
}

class _StarIcon extends StatelessWidget {
  final double value;
  final double rating;
  final double size;

  const _StarIcon({required this.value, required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    final filled = rating >= value;
    final half = !filled && rating >= value - 0.5;
    return Icon(
      filled ? Icons.star_rounded : half ? Icons.star_half_rounded : Icons.star_outline_rounded,
      size: size,
      color: filled || half ? AppTheme.accentGold : AppTheme.textMuted,
    );
  }
}
