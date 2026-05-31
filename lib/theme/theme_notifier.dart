// lib/theme/theme_notifier.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';

class ThemeNotifier extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.cosmicDark;
  AppThemeMode get mode => _mode;
  ThemeData get themeData => AppTheme.themeDataFor(_mode);
  AppThemeTokens get tokens => AppTheme.tokensFor(_mode);

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  ThemeNotifier() {
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final id = doc.data()?['appTheme'] as String?;
      final saved = AppThemeModeX.fromId(id);
      if (saved != _mode) {
        _mode = saved;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setTheme(AppThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('users').doc(uid).set({
        'appTheme': mode.id,
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}

extension ThemeContextX on BuildContext {
  AppThemeTokens get tokens => watch<ThemeNotifier>().tokens;
}
