import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import 'tour_step.dart';

/// Drives a Flutter-Intro-style coach-mark tour over the *existing* app UI:
/// a dark scrim with a spotlight cutout is inserted above the current
/// screen via [Overlay], following the real on-screen position of each
/// step's target widget. Nothing about the underlying screen is rebuilt or
/// replaced.
///
/// [onGoToTab] lets the tour switch the Home bottom-nav tab before
/// measuring a step's target, since Contacts/Calls/Profile are siblings of
/// Home inside the same [IndexedStack] rather than separate pushed routes.
class TourOverlayController {
  TourOverlayController({
    required this.steps,
    required this.onGoToTab,
    required this.onFinish,
    required this.onSkip,
  });

  final List<TourStep> steps;
  final ValueChanged<int> onGoToTab;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  OverlayEntry? _entry;
  int _index = 0;

  void start(BuildContext context) {
    _index = 0;
    _entry = OverlayEntry(builder: (_) => _buildStep(context));
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  void _refresh() => _entry?.markNeedsBuild();

  void _next() {
    if (_index >= steps.length - 1) {
      _close();
      onFinish();
      return;
    }
    _index++;
    _goToCurrentTab();
    _refresh();
  }

  void _back() {
    if (_index == 0) return;
    _index--;
    _goToCurrentTab();
    _refresh();
  }

  void _skip() {
    _close();
    onSkip();
  }

  void _goToCurrentTab() => onGoToTab(steps[_index].tabIndex);

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  Widget _buildStep(BuildContext context) {
    // Give the frame a chance to lay out the (possibly just-switched-to)
    // tab before measuring the target's RenderBox.
    return _TourStepView(
      key: ValueKey(_index),
      step: steps[_index],
      stepNumber: _index + 1,
      totalSteps: steps.length,
      isFirst: _index == 0,
      isLast: _index == steps.length - 1,
      onNext: _next,
      onBack: _back,
      onSkip: _skip,
    );
  }
}

class _TourStepView extends StatefulWidget {
  const _TourStepView({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.isFirst,
    required this.isLast,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final TourStep step;
  final int stepNumber;
  final int totalSteps;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  State<_TourStepView> createState() => _TourStepViewState();
}

class _TourStepViewState extends State<_TourStepView>
    with TickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    if (!mounted) return;
    final renderObject = widget.step.key.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) {
      // Target not mounted yet (e.g. tab still settling, or a
      // conditionally-rendered section like Recent Contacts is empty for
      // this user) -- skip straight past this step rather than showing an
      // orphaned overlay.
      widget.onNext();
      return;
    }
    final topLeft = renderObject.localToGlobal(Offset.zero);
    final rect = (topLeft & renderObject.size).inflate(widget.step.padding);
    setState(() => _targetRect = rect);
  }

  @override
  void dispose() {
    _fade.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rect = _targetRect;
    final screen = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fade,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: ClipPath(
                  clipper: _ScrimClipper(rect: rect),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: rect == null,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) => CustomPaint(
                    painter: _SpotlightPainter(
                      rect: rect,
                      pulse: _pulse.value,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                    ),
                  ),
                ),
              ),
            ),
            // Tap-through blocker for everything except the spotlighted
            // widget itself, so the underlying screen stays inert while the
            // tour is active.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
              ),
            ),
            if (rect != null)
              _Tooltip(
                targetRect: rect,
                screenSize: screen,
                step: widget.step,
                stepNumber: widget.stepNumber,
                totalSteps: widget.totalSteps,
                isFirst: widget.isFirst,
                isLast: widget.isLast,
                isDark: Theme.of(context).brightness == Brightness.dark,
                onNext: widget.onNext,
                onBack: widget.onBack,
                onSkip: widget.onSkip,
              ),
          ],
        ),
      ),
    );
  }
}

/// Clips the blurred backdrop to everything *except* the spotlighted
/// widget's bounds, so the highlighted target stays perfectly crisp while
/// the rest of the screen gets a frosted-glass dimming treatment.
class _ScrimClipper extends CustomClipper<Path> {
  _ScrimClipper({required this.rect});

  final Rect? rect;

  @override
  Path getClip(Size size) {
    final screenPath = Path()..addRect(Offset.zero & size);
    if (rect == null) return screenPath;
    final holePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(rect!, const Radius.circular(AppRadius.md)),
      );
    return Path.combine(PathOperation.difference, screenPath, holePath);
  }

  @override
  bool shouldReclip(covariant _ScrimClipper oldClipper) =>
      oldClipper.rect != rect;
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.rect,
    required this.pulse,
    required this.isDark,
  });

  final Rect? rect;
  final double pulse;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.78)
          : AppColors.nearBlack.withValues(alpha: 0.55);
    final screenPath = Path()..addRect(Offset.zero & size);

    if (rect == null) {
      canvas.drawPath(screenPath, scrim);
      return;
    }

    final baseRRect = RRect.fromRectAndRadius(
      rect!,
      const Radius.circular(AppRadius.md),
    );
    final holePath = Path()..addRRect(baseRRect);
    final overlayPath = Path.combine(
      PathOperation.difference,
      screenPath,
      holePath,
    );
    canvas.drawPath(overlayPath, scrim);

    // Soft outward glow behind the ring, breathing with [pulse].
    final glowRRect = RRect.fromRectAndRadius(
      rect!.inflate(2 + pulse * 4),
      Radius.circular(AppRadius.md + pulse * 4),
    );
    canvas.drawRRect(
      glowRRect,
      Paint()
        ..color = AppColors.redBright.withValues(alpha: 0.35 * (1 - pulse))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Crisp accent ring hugging the actual spotlight cutout.
    canvas.drawRRect(
      baseRRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppColors.redBright, AppColors.red],
        ).createShader(rect!.inflate(1))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.rect != rect ||
      oldDelegate.pulse != pulse ||
      oldDelegate.isDark != isDark;
}

class _Tooltip extends StatelessWidget {
  const _Tooltip({
    required this.targetRect,
    required this.screenSize,
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final Rect targetRect;
  final Size screenSize;
  final TourStep step;
  final int stepNumber;
  final int totalSteps;
  final bool isFirst;
  final bool isLast;
  final bool isDark;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  static const _cardWidth = 300.0;
  static const _margin = 16.0;

  @override
  Widget build(BuildContext context) {
    final spaceBelow = screenSize.height - targetRect.bottom;
    final placeBelow = spaceBelow > 180 || targetRect.top < 180;

    final left = (targetRect.left)
        .clamp(_margin, screenSize.width - _cardWidth - _margin)
        .toDouble();

    // Horizontal offset of the pointer arrow within the card, so it lines
    // up with the target's center even when the card itself is clamped to
    // stay on-screen.
    final targetCenterX = targetRect.left + targetRect.width / 2;
    final arrowLeft = (targetCenterX - left).clamp(24.0, _cardWidth - 24.0);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      left: left,
      top: placeBelow ? targetRect.bottom + 14 : null,
      bottom: placeBelow ? null : screenSize.height - targetRect.top + 14,
      width: _cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (placeBelow)
            _PointerArrow(left: arrowLeft, pointUp: true, isDark: isDark),
          _TooltipCard(
            step: step,
            stepNumber: stepNumber,
            totalSteps: totalSteps,
            isFirst: isFirst,
            isLast: isLast,
            isDark: isDark,
            onNext: onNext,
            onBack: onBack,
            onSkip: onSkip,
          ),
          if (!placeBelow)
            _PointerArrow(left: arrowLeft, pointUp: false, isDark: isDark),
        ],
      ),
    );
  }
}

class _PointerArrow extends StatelessWidget {
  const _PointerArrow({
    required this.left,
    required this.pointUp,
    required this.isDark,
  });

  final double left;
  final bool pointUp;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: left - 8),
      child: CustomPaint(
        size: const Size(16, 8),
        painter: _ArrowPainter(pointUp: pointUp, isDark: isDark),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.pointUp, required this.isDark});

  final bool pointUp;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointUp) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close();
    }
    canvas.drawPath(
      path,
      Paint()..color = isDark ? AppColorsDark.card : AppColors.surface,
    );
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter oldDelegate) =>
      oldDelegate.pointUp != pointUp || oldDelegate.isDark != isDark;
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.step,
    required this.stepNumber,
    required this.totalSteps,
    required this.isFirst,
    required this.isLast,
    required this.isDark,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final TourStep step;
  final int stepNumber;
  final int totalSteps;
  final bool isFirst;
  final bool isLast;
  final bool isDark;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final titleStyle = isDark
        ? AppTextStyles.heading3OnDark
        : AppTextStyles.heading3;
    final descriptionStyle = isDark
        ? AppTextStyles.bodyMutedOnDark
        : AppTextStyles.bodyMuted;
    final captionColor = isDark
        ? AppColorsDark.textTertiary
        : AppColors.textTertiary;
    final backColor = isDark
        ? AppColorsDark.textSecondary
        : AppColors.textSecondary;
    final skipColor = captionColor;
    final trackColor = isDark
        ? AppColorsDark.textTertiary.withValues(alpha: 0.25)
        : AppColors.textTertiary.withValues(alpha: 0.2);
    final borderColor = AppColors.redBright.withValues(
      alpha: isDark ? 0.18 : 0.28,
    );
    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.55 : 0.18);
    final cardGradientColors = isDark
        ? [
            AppColorsDark.elevated.withValues(alpha: 0.92),
            AppColorsDark.card.withValues(alpha: 0.92),
            AppColorsDark.background.withValues(alpha: 0.92),
          ]
        : [
            Colors.white.withValues(alpha: 0.94),
            AppColors.softCard.withValues(alpha: 0.94),
            AppColors.surfaceMuted.withValues(alpha: 0.9),
          ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 8),
          child: child,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.lgAll,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: cardGradientColors,
              ),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.redBright, AppColors.redDeep],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.redBright.withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(step.icon, color: Colors.white, size: 19),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.title, style: titleStyle),
                            const SizedBox(height: 2),
                            Text(
                              'Step $stepNumber of $totalSteps',
                              style: AppTextStyles.caption.copyWith(
                                color: captionColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(step.description, style: descriptionStyle),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: AppRadius.pillAll,
                    child: SizedBox(
                      height: 4,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Container(color: trackColor),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                                width:
                                    constraints.maxWidth *
                                    stepNumber /
                                    totalSteps,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.redBright,
                                      AppColors.red,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!isFirst)
                        TextButton(
                          onPressed: onBack,
                          style: TextButton.styleFrom(
                            foregroundColor: backColor,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      if (!isLast)
                        TextButton(
                          onPressed: onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: skipColor,
                          ),
                          child: const Text('Skip'),
                        ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: onNext,
                        style:
                            FilledButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              elevation: 0,
                            ).copyWith(
                              overlayColor: WidgetStatePropertyAll(
                                Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(isLast ? 'Finish' : 'Next'),
                            if (!isLast) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
