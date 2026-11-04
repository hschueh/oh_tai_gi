import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A card that flips around its vertical axis between [front] and [back].
///
/// Replaces the `flip_card` package, whose last release does not support
/// Dart 3. Flip it programmatically through a `GlobalKey<FlipCardState>`.
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.flipOnTouch = true,
    this.duration = const Duration(milliseconds: 500),
    this.onFlipDone,
  });

  final Widget front;
  final Widget back;
  final bool flipOnTouch;
  final Duration duration;

  /// Called when a flip animation finishes, with whether the front is shown.
  final ValueChanged<bool>? onFlipDone;

  @override
  FlipCardState createState() => FlipCardState();
}

class FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) {
            widget.onFlipDone?.call(isFront);
          }
        });

  bool _isFront = true;

  bool get isFront => _isFront;

  void toggleCard() {
    if (!mounted) return;
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle =
            Curves.easeInOut.transform(_controller.value) * math.pi;
        final showFront = angle <= math.pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(showFront ? angle : angle - math.pi),
          child: showFront ? widget.front : widget.back,
        );
      },
    );
    if (!widget.flipOnTouch) return card;
    return GestureDetector(onTap: toggleCard, child: card);
  }
}
