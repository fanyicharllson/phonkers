import 'package:flutter/material.dart';

//? =============================================================================
//? 1. SCALE ANIMATION WIDGET
//? =============================================================================
class ScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double beginScale;
  final double endScale;

  const ScaleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.curve = Curves.elasticOut,
    this.beginScale = 0.0,
    this.endScale = 1.0,
  });

  @override
  State<ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: widget.beginScale,
      end: widget.endScale,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(widget.delay);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        );
      },
    );
  }
}

//! =============================================================================
//! 2. SLIDE FADE ANIMATION WIDGET
//! =============================================================================
class SlideFadeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset beginOffset;
  final Offset endOffset;

  const SlideFadeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(0, 0.3),
    this.endOffset = Offset.zero,
  });

  @override
  State<SlideFadeAnimation> createState() => _SlideFadeAnimationState();
}

class _SlideFadeAnimationState extends State<SlideFadeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _slideAnimation = Tween<Offset>(
      begin: widget.beginOffset,
      end: widget.endOffset,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(widget.delay);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
    );
  }
}

//! =============================================================================
//! 3. STAGGER ANIMATION WIDGET (For Multiple Children)
//! =============================================================================
class StaggerAnimation extends StatefulWidget {
  final List<Widget> children;
  final Duration duration;
  final Duration staggerDelay;
  final Duration initialDelay;
  final AnimationType animationType;

  const StaggerAnimation({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 600),
    this.staggerDelay = const Duration(milliseconds: 200),
    this.initialDelay = Duration.zero,
    this.animationType = AnimationType.slideUp,
  });

  @override
  State<StaggerAnimation> createState() => _StaggerAnimationState();
}

class _StaggerAnimationState extends State<StaggerAnimation> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.children.asMap().entries.map((entry) {
        int index = entry.key;
        Widget child = entry.value;
        Duration delay = widget.initialDelay + (widget.staggerDelay * index);

        switch (widget.animationType) {
          case AnimationType.scale:
            return ScaleAnimation(
              delay: delay,
              duration: widget.duration,
              child: child,
            );
          case AnimationType.slideUp:
            return SlideFadeAnimation(
              delay: delay,
              duration: widget.duration,
              beginOffset: const Offset(0, 0.3),
              child: child,
            );
          case AnimationType.slideRight:
            return SlideFadeAnimation(
              delay: delay,
              duration: widget.duration,
              beginOffset: const Offset(-0.3, 0),
              child: child,
            );
        }
      }).toList(),
    );
  }
}

enum AnimationType { scale, slideUp, slideRight }

//* =============================================================================
//* 4. GLOW ANIMATION WIDGET
//* =============================================================================
class GlowAnimation extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final Duration duration;

  const GlowAnimation({
    super.key,
    required this.child,
    this.glowColor = Colors.purple,
    this.glowRadius = 20.0,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<GlowAnimation> createState() => _GlowAnimationState();
}

class _GlowAnimationState extends State<GlowAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(
                  alpha: _glowAnimation.value * 0.5,
                ),
                blurRadius: widget.glowRadius * _glowAnimation.value,
                spreadRadius: 5,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

//? =============================================================================
//? 5. ANIMATED BUTTON WIDGET
//? =============================================================================
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Duration delay;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const AnimatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.delay = Duration.zero,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  @override
  Widget build(BuildContext context) {
    return SlideFadeAnimation(
      delay: widget.delay,
      beginOffset: const Offset(0, 0.3),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: widget.backgroundColor != null
                ? [widget.backgroundColor!, widget.backgroundColor!]
                : [Colors.purple, Colors.deepPurple],
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.backgroundColor ?? Colors.purple).withValues(
                alpha: 0.4,
              ),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.textColor ?? Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.icon != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.textColor ?? Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
