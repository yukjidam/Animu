import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_notifier.dart';
import '../../widgets/common/ani_app_bar.dart';
import '../../widgets/common/theme_picker_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _firebaseAuth = FirebaseAuth.instance;

  bool _libraryPrivate = false;
  bool _reviewsPrivate = false;
  bool _loadingPrivacy = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();
      if (!mounted) return;
      setState(() {
        _libraryPrivate = data?['libraryPrivate'] as bool? ?? false;
        _reviewsPrivate = data?['reviewsPrivate'] as bool? ?? false;
        _loadingPrivacy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPrivacy = false);
    }
  }

  Future<void> _setLibraryPrivate(bool value) async {
    setState(() => _libraryPrivate = value);
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'libraryPrivate': value,
      }, SetOptions(merge: true));
    } catch (_) {
      if (!mounted) return;
      setState(() => _libraryPrivate = !value);
    }
  }

  Future<void> _setReviewsPrivate(bool value) async {
    setState(() => _reviewsPrivate = value);
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'reviewsPrivate': value,
      }, SetOptions(merge: true));
    } catch (_) {
      if (!mounted) return;
      setState(() => _reviewsPrivate = !value);
    }
  }

  Future<void> _confirmSignOut() async {
    final t = AppTheme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: t.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.statusDropped.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.statusDropped,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sign Out?',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to sign out of your Animu account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: t.backgroundDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: t.divider),
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.statusDropped.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.statusDropped.withOpacity(0.4),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Sign Out',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppTheme.statusDropped,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _auth.logout();
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final themeNotifier = context.watch<ThemeNotifier>();
    final activeTheme = themeNotifier.mode;

    return Scaffold(
      backgroundColor: t.backgroundDark,
      appBar: const AniAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // ── Privacy ──────────────────────────────────────────────────────
          const _SectionHeader(label: 'Privacy'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: t.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.divider),
            ),
            child: _loadingPrivacy
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: t.primaryViolet,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      _PrivacyToggleTile(
                        icon: Icons.video_library_outlined,
                        label: 'Private Library',
                        subtitle: 'Hide your anime library from other users',
                        value: _libraryPrivate,
                        onChanged: _setLibraryPrivate,
                        t: t,
                      ),
                      Divider(
                        height: 1,
                        indent: 56,
                        endIndent: 16,
                        color: t.divider,
                      ),
                      _PrivacyToggleTile(
                        icon: Icons.rate_review_outlined,
                        label: 'Private Reviews',
                        subtitle: 'Hide your reviews and ratings from others',
                        value: _reviewsPrivate,
                        onChanged: _setReviewsPrivate,
                        isLast: true,
                        t: t,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),

          // ── Appearance ────────────────────────────────────────────────────
          const _SectionHeader(label: 'Appearance'),
          const SizedBox(height: 8),
          _SettingsGroup(
            t: t,
            children: [
              _ThemeTile(
                activeMode: activeTheme,
                t: t,
                onTap: () => ThemePickerSheet.show(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── General ───────────────────────────────────────────────────────
          const _SectionHeader(label: 'General'),
          const SizedBox(height: 8),
          _SettingsGroup(
            t: t,
            children: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {},
                t: t,
              ),
              _SettingsTile(
                icon: Icons.sync_rounded,
                label: 'Sync Library',
                onTap: () {},
                isLast: true,
                t: t,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Support ───────────────────────────────────────────────────────
          const _SectionHeader(label: 'Support'),
          const SizedBox(height: 8),
          _SettingsGroup(
            t: t,
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Feedback',
                onTap: () {},
                isLast: true,
                t: t,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Account ───────────────────────────────────────────────────────
          const _SectionHeader(label: 'Account'),
          const SizedBox(height: 8),
          _SettingsGroup(
            t: t,
            children: [
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                onTap: _confirmSignOut,
                color: AppTheme.statusDropped,
                isLast: true,
                t: t,
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Center(
            child: Text(
              'Animu v1.0.0',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Theme tile ────────────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  final AppThemeMode activeMode;
  final AppThemeTokens t;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.activeMode,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: t.primaryViolet.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.palette_outlined, color: t.primaryViolet, size: 20),
      ),
      title: const Text(
        'App Theme',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: activeMode.previewGradient),
            ),
          ),
          Text(
            '${activeMode.emoji}  ${activeMode.label}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textMuted,
        size: 18,
      ),
      onTap: onTap,
    );
  }
}

// ── Privacy toggle tile ───────────────────────────────────────────────────────

class _PrivacyToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;
  final AppThemeTokens t;

  const _PrivacyToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.t,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (value ? t.primaryViolet : AppTheme.textSecondary)
                  .withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: value ? t.primaryViolet : AppTheme.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: t.primaryViolet,
            activeTrackColor: t.primaryViolet.withOpacity(0.3),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: t.divider,
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Settings group ────────────────────────────────────────────────────────────

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final AppThemeTokens t;
  const _SettingsGroup({required this.children, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: t.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.divider),
      ),
      child: Column(children: children),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool isLast;
  final AppThemeTokens t;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.t,
    this.color,
    this.isLast = false,
  });

  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? AppTheme.textSecondary;
    final t = widget.t;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: c.withOpacity(0.12),
            highlightColor: c.withOpacity(0.06),
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: AnimatedScale(
              scale: _pressed ? 0.985 : 1,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: _pressed
                      ? Colors.white.withOpacity(0.02)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  leading: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _pressed
                          ? c.withOpacity(0.18)
                          : c.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: c, size: 20),
                  ),
                  title: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: _pressed ? Colors.white : c,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    child: Text(widget.label),
                  ),
                  trailing: AnimatedSlide(
                    duration: const Duration(milliseconds: 180),
                    offset: _pressed ? const Offset(0.08, 0) : Offset.zero,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: c.withOpacity(0.5),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!widget.isLast)
          Divider(height: 1, indent: 56, endIndent: 16, color: t.divider),
      ],
    );
  }
}
