import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class AuthScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  const AuthScreen({super.key, this.onSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isLogin = true;

  late final AnimationController _bgCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  void _switchMode() => setState(() => _isLogin = !_isLogin);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Stack(
        children: [
          // ── Animated mesh background ───────────────────────────────
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) =>
                CustomPaint(size: size, painter: _MeshPainter(_bgCtrl.value)),
          ),

          // ── Floating sakura particles ──────────────────────────────
          ...List.generate(10, (i) => _SakuraPetal(index: i, size: size)),

          // ── Content ────────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                children: [
                  _HeroBanner(),
                  const SizedBox(height: 28),
                  _TabSwitcher(isLogin: _isLogin, onSwitch: _switchMode),
                  const SizedBox(height: 24),
                  _ExpandingFormCard(
                    isLogin: _isLogin,
                    onSuccess: widget.onSuccess,
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mesh background painter
// ─────────────────────────────────────────────────────────────────────────────

class _MeshPainter extends CustomPainter {
  final double t;
  _MeshPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    void orb(double cx, double cy, double r, Color color) {
      paint.shader = RadialGradient(
        colors: [color.withOpacity(0.22), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }

    final s = math.sin(t * math.pi * 2);
    final c = math.cos(t * math.pi * 2);

    orb(
      size.width * 0.15 + 40 * c,
      size.height * 0.12 + 30 * s,
      200,
      AppTheme.primaryViolet,
    );
    orb(
      size.width * 0.85 - 30 * s,
      size.height * 0.08 + 40 * c,
      160,
      AppTheme.accentSakura,
    );
    orb(
      size.width * 0.5 + 50 * c,
      size.height * 0.85 - 20 * s,
      180,
      AppTheme.primaryViolet,
    );
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sakura particle
// ─────────────────────────────────────────────────────────────────────────────

class _SakuraPetal extends StatefulWidget {
  final int index;
  final Size size;
  const _SakuraPetal({required this.index, required this.size});

  @override
  State<_SakuraPetal> createState() => _SakuraPetalState();
}

class _SakuraPetalState extends State<_SakuraPetal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final double _startX;
  late final double _duration;
  late final double _petalSize;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(widget.index * 137);
    _startX = rng.nextDouble();
    _duration = 6.0 + rng.nextDouble() * 8.0;
    _petalSize = 6.0 + rng.nextDouble() * 8.0;

    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_duration * 1000).toInt()),
    )..repeat();

    Future.delayed(
      Duration(milliseconds: (rng.nextDouble() * 5000).toInt()),
      () {
        if (mounted) _ctrl.forward();
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final y = _ctrl.value * (widget.size.height + 40) - 20;
        final x =
            _startX * widget.size.width +
            math.sin(_ctrl.value * math.pi * 4) * 24;
        return Positioned(
          left: x,
          top: y,
          child: Transform.rotate(
            angle: _ctrl.value * math.pi * 6,
            child: Opacity(
              opacity: 0.18 + 0.15 * math.sin(_ctrl.value * math.pi),
              child: Text('🌸', style: TextStyle(fontSize: _petalSize)),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero banner
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryViolet.withOpacity(0.55),
            AppTheme.accentSakura.withOpacity(0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.primaryViolet.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryViolet.withOpacity(0.3),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✦  Animu  アニム',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your World.\nYour Watchlist.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track, rate & discover\nthousands of titles.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.70),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SvgPicture.asset(
              'assets/icons/animu_icon.svg',
              width: 80,
              height: 80,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab switcher
// ─────────────────────────────────────────────────────────────────────────────

class _TabSwitcher extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onSwitch;
  const _TabSwitcher({required this.isLogin, required this.onSwitch});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          _Tab(
            label: 'Login',
            active: isLogin,
            onTap: isLogin ? null : onSwitch,
          ),
          _Tab(
            label: 'Sign Up',
            active: !isLogin,
            onTap: !isLogin ? null : onSwitch,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _Tab({required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [AppTheme.primaryViolet, AppTheme.accentSakura],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppTheme.primaryViolet.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: active ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expanding form card
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandingFormCard extends StatefulWidget {
  final bool isLogin;
  final VoidCallback? onSuccess;
  const _ExpandingFormCard({required this.isLogin, this.onSuccess});

  @override
  State<_ExpandingFormCard> createState() => _ExpandingFormCardState();
}

class _ExpandingFormCardState extends State<_ExpandingFormCard> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _agree = false;
  bool _loading = false;

  final _auth = AuthService();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Nunito')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _friendlyError(String code) => switch (code) {
    'user-not-found' => 'No account found with that email.',
    'wrong-password' => 'Incorrect password.',
    'email-already-in-use' => 'An account already exists with that email.',
    'weak-password' => 'Password must be at least 6 characters.',
    'invalid-email' => 'Please enter a valid email address.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    _ => 'Authentication failed. Please try again.',
  };

  // ── Submit (email / password) ──────────────────────────────────────────────
  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    setState(() => _loading = true);

    try {
      if (widget.isLogin) {
        // ── LOGIN ─────────────────────────────────────
        await _auth.login(email: email, password: password);

        await FirebaseAuth.instance.currentUser?.reload();
      } else {
        // ── SIGN UP ──────────────────────────────────
        final username = _username.text.trim();

        if (username.isEmpty) {
          _showError('Please enter a username.');
          return;
        }

        // Create account directly from Firebase
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Save username as display name
        await credential.user?.updateDisplayName(username);

        // Refresh Firebase user
        await credential.user?.reload();
      }

      widget.onSuccess?.call();
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e.code));
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ── Google sign-in ─────────────────────────────────────────────────────────

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    try {
      await _auth.signInWithGoogle();
      widget.onSuccess?.call();
    } catch (e) {
      _showError(e.toString()); // ← show exact error temporarily
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppTheme.divider.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Username (Sign Up only) ───────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SizeTransition(
                      sizeFactor: anim,
                      axisAlignment: -1,
                      child: child,
                    ),
                  ),
                  child: widget.isLogin
                      ? const SizedBox.shrink(key: ValueKey('username-hidden'))
                      : Column(
                          key: const ValueKey('username-shown'),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _FieldLabel('Username'),
                            const SizedBox(height: 8),
                            _Field(
                              controller: _username,
                              hint: 'your_anime_name',
                              icon: Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                ),

                // ── Email ─────────────────────────────────────────
                _FieldLabel('Email'),
                const SizedBox(height: 8),
                _Field(
                  controller: _email,
                  hint: 'you@example.com',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 18),

                // ── Password ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _FieldLabel('Password'),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: widget.isLogin
                          ? GestureDetector(
                              key: const ValueKey('forgot'),
                              onTap: () {},
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 12,
                                  color: AppTheme.primaryVioletLight,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey('no-forgot')),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _Field(
                  controller: _password,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ),
                ),

                // ── Terms checkbox (Sign Up only) ─────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SizeTransition(
                      sizeFactor: anim,
                      axisAlignment: -1,
                      child: child,
                    ),
                  ),
                  child: widget.isLogin
                      ? const SizedBox.shrink(key: ValueKey('terms-hidden'))
                      : Padding(
                          key: const ValueKey('terms-shown'),
                          padding: const EdgeInsets.only(top: 18),
                          child: GestureDetector(
                            onTap: () => setState(() => _agree = !_agree),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    gradient: _agree
                                        ? const LinearGradient(
                                            colors: [
                                              AppTheme.primaryViolet,
                                              AppTheme.accentSakura,
                                            ],
                                          )
                                        : null,
                                    border: _agree
                                        ? null
                                        : Border.all(
                                            color: AppTheme.divider,
                                            width: 1.5,
                                          ),
                                  ),
                                  child: _agree
                                      ? const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      style: const TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                      children: [
                                        const TextSpan(text: 'I agree to the '),
                                        TextSpan(
                                          text: 'Terms of Service',
                                          style: TextStyle(
                                            color: AppTheme.primaryVioletLight,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: TextStyle(
                                            color: AppTheme.primaryVioletLight,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // ── CTA button ────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _GradientButton(
                    key: ValueKey(widget.isLogin),
                    label: _loading
                        ? 'Please wait…'
                        : (widget.isLogin ? 'Login' : 'Create Account'),
                    onTap: _loading
                        ? null
                        : (widget.isLogin || _agree ? _submit : null),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Social row ─────────────────────────────────────────────
        _SocialRow(
          isLogin: widget.isLogin,
          onGoogleTap: _loading ? () {} : _googleSignIn,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field label
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: AppTheme.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input field
// ─────────────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontFamily: 'Nunito',
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppTheme.textMuted,
          fontFamily: 'Nunito',
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 20),
        suffixIcon: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
            : null,
        suffixIconConstraints: const BoxConstraints(),
        filled: true,
        fillColor: AppTheme.backgroundDark.withOpacity(0.55),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.divider.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppTheme.primaryViolet,
            width: 1.8,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient CTA button
// ─────────────────────────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GradientButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? [AppTheme.primaryViolet, AppTheme.accentSakura]
                : [AppTheme.divider, AppTheme.divider],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppTheme.primaryViolet.withOpacity(0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social login row
// ─────────────────────────────────────────────────────────────────────────────

class _SocialRow extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onGoogleTap;
  const _SocialRow({
    super.key,
    required this.isLogin,
    required this.onGoogleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: AppTheme.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'OR CONTINUE WITH',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Expanded(child: Container(height: 1, color: AppTheme.divider)),
          ],
        ),
        const SizedBox(height: 16),
        Center(child: _GoogleButton(onTap: onGoogleTap)),
      ],
    );
  }
}

class _GoogleButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GoogleButton({required this.onTap});

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.divider, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Image.asset('assets/icons/google.png'),
        ),
      ),
    );
  }
}
