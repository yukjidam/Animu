// lib/widgets/profile/profile_theme_picker.dart

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/profile_card_themes.dart';

class ProfileThemePicker extends StatelessWidget {
  final ProfileCardTheme selected;
  final ValueChanged<ProfileCardTheme> onSelect;

  const ProfileThemePicker({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  static Future<ProfileCardTheme?> show(
    BuildContext context, {
    required ProfileCardTheme current,
  }) {
    return showModalBottomSheet<ProfileCardTheme>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProfileThemePicker(
        selected: current,
        onSelect: (t) => Navigator.pop(context, t),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF151320),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  color: AppTheme.primaryViolet,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Profile Card Theme',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Text(
              'Choose a Japan-inspired style for your profile card',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Theme grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.0,
            children: kProfileCardThemes
                .map(
                  (meta) => _ThemeCell(
                    meta: meta,
                    isSelected: meta.theme == selected,
                    onTap: () => onSelect(meta.theme),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ThemeCell extends StatelessWidget {
  final ProfileCardThemeMeta meta;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCell({
    required this.meta,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: meta.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryViolet
                : AppTheme.divider.withOpacity(0.5),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryViolet.withOpacity(0.35),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(meta.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(height: 6),
                Text(
                  meta.label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
