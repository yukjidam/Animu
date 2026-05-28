// lib/widgets/common/status_badge.dart

import 'package:flutter/material.dart';
import '../../models/anime_model.dart';
import '../../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final WatchStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  Color get _color {
    switch (status) {
      case WatchStatus.ongoing:
        return AppTheme.statusOngoing;
      case WatchStatus.finished:
        return AppTheme.statusFinished;
      case WatchStatus.planToWatch:
        return AppTheme.statusPlanToWatch;
      case WatchStatus.dropped:
        return AppTheme.statusDropped;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: _color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}
