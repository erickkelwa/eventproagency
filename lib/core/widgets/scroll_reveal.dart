import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// ── ScrollReveal ───────────────────────────────────────────────────────────
/// Partiful-style pop-in animation that triggers when a widget scrolls into
/// view. Supports fade, slide, and scale — all configurable.
///
/// Usage (single item):
/// ```dart
/// ScrollReveal(child: MyCard())
/// ```
///
/// Usage (staggered list — pass [index]):
/// ```dart
/// ScrollReveal(index: i, child: MyCard())
/// ```
class ScrollReveal extends StatefulWidget {
  final Widget child;

  /// Position in a list — adds a stagger delay so items cascade in.
  final int index;

  /// How far (in pixels) the widget slides up from its resting position.
  final double slideDistance;

  /// Base delay before the animation starts (ms).
  final int baseDelayMs;

  /// Stagger delay added per [index] item (ms).
  final int staggerMs;

  /// Animation duration (ms).
  final int durationMs;

  /// Animate only once (true) or every time it re-enters the viewport (false).
  final bool once;

  /// Which direction the slide comes from.
  final RevealDirection direction;

  const ScrollReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.slideDistance = 40,
    this.baseDelayMs = 0,
    this.staggerMs = 80,
    this.durationMs = 500,
    this.once = true,
    this.direction = RevealDirection.up,
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

enum RevealDirection { up, down, left, right }

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  bool _hasAnimated = false;

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    final isVisible = info.visibleFraction > 0.1;
    if (isVisible && (!widget.once || !_hasAnimated)) {
      setState(() {
        _visible = true;
        _hasAnimated = true;
      });
    } else if (!isVisible && !widget.once) {
      setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDelay = widget.baseDelayMs + (widget.index * widget.staggerMs);
    final slideY = widget.direction == RevealDirection.up ? 0.08 :
                   widget.direction == RevealDirection.down ? -0.08 : 0.0;
    final slideX = widget.direction == RevealDirection.left ? 0.08 :
                   widget.direction == RevealDirection.right ? -0.08 : 0.0;

    return VisibilityDetector(
      key: widget.key ?? ValueKey('scroll_reveal_${widget.hashCode}_${widget.index}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: _visible
          ? widget.child
              .animate(delay: Duration(milliseconds: totalDelay))
              .fadeIn(
                duration: Duration(milliseconds: widget.durationMs),
                curve: Curves.easeOut,
              )
              .slideY(
                begin: slideY,
                end: 0,
                duration: Duration(milliseconds: widget.durationMs),
                curve: Curves.easeOutCubic,
              )
              .slideX(
                begin: slideX,
                end: 0,
                duration: Duration(milliseconds: widget.durationMs),
                curve: Curves.easeOutCubic,
              )
              .scale(
                begin: const Offset(0.94, 0.94),
                end: const Offset(1, 1),
                duration: Duration(milliseconds: widget.durationMs),
                curve: Curves.easeOutBack,
              )
          : Opacity(opacity: 0, child: widget.child),
    );
  }
}

/// ── ScrollRevealList ───────────────────────────────────────────────────────
/// Convenience wrapper that adds staggered [ScrollReveal] to every child
/// in a list — like Partiful's cascading card pop-ins.
///
/// ```dart
/// ScrollRevealList(
///   children: events.map((e) => ProEventCard(event: e)).toList(),
/// )
/// ```
class ScrollRevealList extends StatelessWidget {
  final List<Widget> children;
  final int staggerMs;
  final int baseDelayMs;
  final RevealDirection direction;
  final double slideDistance;

  const ScrollRevealList({
    super.key,
    required this.children,
    this.staggerMs = 70,
    this.baseDelayMs = 0,
    this.direction = RevealDirection.up,
    this.slideDistance = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < children.length; i++)
          ScrollReveal(
            key: ValueKey('reveal_list_$i'),
            index: i,
            staggerMs: staggerMs,
            baseDelayMs: baseDelayMs,
            direction: direction,
            slideDistance: slideDistance,
            child: children[i],
          ),
      ],
    );
  }
}

/// ── RevealOnce ─────────────────────────────────────────────────────────────
/// Ultra-lightweight one-shot version using only flutter_animate.
/// Best for hero sections, headers, or single big elements that are
/// immediately visible when the screen loads.
///
/// ```dart
/// RevealOnce(child: HeroCard())
/// RevealOnce.fromLeft(child: Title())
/// RevealOnce.pop(child: StatBadge())   // Partiful-style pop
/// ```
class RevealOnce extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideY;
  final double slideX;
  final bool doScale;
  final double scaleBegin;
  final Curve curve;

  const RevealOnce({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.slideY = 0.08,
    this.slideX = 0,
    this.doScale = false,
    this.scaleBegin = 0.95,
    this.curve = Curves.easeOutCubic,
  });

  /// Slide up + fade (Eventbrite card style)
  const RevealOnce.up({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.curve = Curves.easeOutCubic,
  })  : slideY = 0.12,
        slideX = 0,
        doScale = false,
        scaleBegin = 0.95;

  /// Slide in from left
  const RevealOnce.fromLeft({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.curve = Curves.easeOutCubic,
  })  : slideY = 0,
        slideX = -0.15,
        doScale = false,
        scaleBegin = 1.0;

  /// Partiful-style pop (scale + fade)
  const RevealOnce.pop({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.curve = Curves.easeOutBack,
  })  : slideY = 0,
        slideX = 0,
        doScale = true,
        scaleBegin = 0.82;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: curve)
        .slideY(begin: slideY, end: 0, duration: duration, curve: curve)
        .slideX(begin: slideX, end: 0, duration: duration, curve: curve)
        .then()
        .custom(
          duration: Duration.zero,
          builder: (context, value, child) => child,
        );
  }
}
