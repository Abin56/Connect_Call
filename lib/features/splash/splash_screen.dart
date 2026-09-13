import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// Brand-intro animation that plays while Firebase resolves auth state,
/// then routes to Home or Login.
///
/// The animation and navigation are decoupled: [_controller] always plays
/// once through, and navigation waits for the intro to settle
/// ([_introSettled]) so a fast auth response can't cut it short.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _introDuration = Duration(milliseconds: 1900);
  static const _minSettleDuration = Duration(milliseconds: 1500);

  bool _hasNavigated = false;
  bool _introSettled = false;
  String? _pendingRoute;

  late final AnimationController _controller;

  // Phase 1 (0-350ms): ambient glow rises behind the center.
  late final Animation<double> _ambientGlow = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.18, curve: Curves.easeOut),
  );

  // Phase 2 (~210-610ms): a single red light sweep crosses the screen.
  late final Animation<double> _sweep1 = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.11, 0.32, curve: Curves.easeInOut),
  );

  // Phase 3 (~475-950ms): Sankar Group logo fades + scales in.
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 0.5, curve: Curves.easeOut),
  );
  late final Animation<double> _logoScale = Tween<double>(begin: 0.92, end: 1.0)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
        ),
      );

  // Phase 4 (~625-1180ms): the logo's glow breathes once (rise then settle).
  late final Animation<double> _glowBreatheUp = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.33, 0.5, curve: Curves.easeOut),
  );
  late final Animation<double> _glowBreatheDown = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.5, 0.62, curve: Curves.easeIn),
  );

  // Phase 5 (~760-1100ms): a second, lower sweep introduces the wordmark.
  late final Animation<double> _sweep2 = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 0.58, curve: Curves.easeInOut),
  );

  // Phase 6 (~890-1350ms): ConnectCall wordmark + tagline settle in.
  late final Animation<double> _wordmarkFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.47, 0.71, curve: Curves.easeOut),
  );
  late final Animation<Offset> _wordmarkSlide =
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.47, 0.71, curve: Curves.easeOutCubic),
        ),
      );
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.62, 0.85, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;

    _controller = AnimationController(
      vsync: this,
      duration: reduceMotion ? const Duration(milliseconds: 1) : _introDuration,
    );

    _controller.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _introSettled = true);
      _navigateIfReady();
    });

    // Even with a fast auth response, hold the branding on screen for a
    // minimum settle time so the intro never feels cut off.
    Future.delayed(reduceMotion ? Duration.zero : _minSettleDuration, () {
      if (!mounted) return;
      setState(() => _introSettled = true);
      _navigateIfReady();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateIfReady() {
    if (_hasNavigated || !_introSettled || _pendingRoute == null) return;
    _hasNavigated = true;
    Navigator.of(context).pushNamedAndRemoveUntil(_pendingRoute!, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (_hasNavigated) return;
        _pendingRoute = user != null ? AppRoutes.home : AppRoutes.login;
        _navigateIfReady();
      });
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF050505)
          : const Color(0xFFF7F7F7),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _AmbientBackground(isDark: isDark, glow: _ambientGlow.value),
              _LightSweep(
                progress: _sweep1.value,
                alignment: const Alignment(0, -0.15),
              ),
              _LightSweep(
                progress: _sweep2.value,
                alignment: const Alignment(0, 0.55),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LogoWithGlow(
                      fade: _logoFade.value,
                      scale: _logoScale.value,
                      glow: _glowBreatheUp.value - _glowBreatheDown.value,
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _wordmarkFade,
                      child: SlideTransition(
                        position: _wordmarkSlide,
                        child: Column(
                          children: [
                            _Wordmark(isDark: isDark),
                            const SizedBox(height: 6),
                            Text(
                              'CONNECTCALL',
                              style:
                                  (isDark
                                          ? AppTextStyles.caption.copyWith(
                                              color:
                                                  AppColorsDark.textTertiary,
                                            )
                                          : AppTextStyles.caption.copyWith(
                                              color: AppColors.textTertiary,
                                            ))
                                      .copyWith(letterSpacing: 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _taglineFade,
                      child: Text(
                        'Stay connected. Simply.',
                        style:
                            (isDark
                                    ? AppTextStyles.bodyMutedOnDark
                                    : AppTextStyles.bodyMuted)
                                .copyWith(letterSpacing: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Near-black (or near-white) base with a faint red atmospheric glow rising
/// behind the center -- Phase 1.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.isDark, required this.glow});

  final bool isDark;
  final double glow;

  @override
  Widget build(BuildContext context) {
    if (isDark) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color.lerp(
                const Color(0xFF0B0B0B),
                const Color(0xFF3A050B),
                glow,
              )!,
              const Color(0xFF0B0B0B),
              const Color(0xFF050505),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Color.lerp(Colors.white, AppColors.softRed, glow * 0.6)!,
            const Color(0xFFF7F7F7),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

/// A single diagonal red light reflection that sweeps across the screen
/// once, driven by [progress] (0..1). Implemented as a positioned gradient
/// band rather than a shader/CustomPainter, since a plain transform is
/// cheap enough to redraw every frame.
class _LightSweep extends StatelessWidget {
  const _LightSweep({required this.progress, required this.alignment});

  final double progress;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();

    // Sweep travels from off-screen left to off-screen right.
    final dx = (progress * 2.6) - 1.3;

    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: 1.0,
        heightFactor: 0.5,
        child: Transform.translate(
          offset: Offset(dx * MediaQuery.sizeOf(context).width, 0),
          child: Transform.rotate(
            angle: -0.35,
            child: Container(
              width: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    AppColors.redBright.withValues(
                      alpha: 0.16 * _edgeFade(progress),
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Fades the sweep in/out at the start and end of its travel so it never
  /// pops in with a hard edge.
  double _edgeFade(double t) {
    if (t < 0.15) return t / 0.15;
    if (t > 0.85) return (1 - t) / 0.15;
    return 1.0;
  }
}

/// The Sankar Group logo with a soft red glow behind it -- Phases 3 & 4.
class _LogoWithGlow extends StatelessWidget {
  const _LogoWithGlow({
    required this.fade,
    required this.scale,
    required this.glow,
  });

  final double fade;
  final double scale;
  final double glow;

  @override
  Widget build(BuildContext context) {
    final glowOpacity = (0.08 + glow * 0.1).clamp(0.0, 0.18);

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: fade * glowOpacity,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.redBright, Colors.transparent],
                ),
              ),
            ),
          ),
          Opacity(
            opacity: fade,
            child: Transform.scale(
              scale: scale,
              child: Image.asset(
                'assets/sankar_mark.png',
                width: 152,
                height: 152,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The Sankar Group wordmark, with "Group" as a small brand-red accent.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final baseStyle = AppTextStyles.heading1.copyWith(
      color: isDark ? Colors.white : AppColors.textPrimary,
      fontSize: 34,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      shadows: [
        Shadow(
          color: AppColors.red.withValues(alpha: isDark ? 0.35 : 0.18),
          blurRadius: 18,
        ),
      ],
    );

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: 'SANKAR '),
          TextSpan(
            text: 'GROUP',
            style: baseStyle.copyWith(
              color: AppColors.red,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
