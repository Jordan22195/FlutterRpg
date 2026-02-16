import 'package:flutter/material.dart';

class FadingNumber extends StatefulWidget {
  const FadingNumber({
    super.key,
    required this.number,
    this.color,
    this.style,
    this.duration = const Duration(milliseconds: 650),
    this.hold = const Duration(milliseconds: 150),
    this.curve = Curves.easeOut,
    this.onFinished,
    this.autoplay = true,
  });

  final int number;
  final Color? color;
  final TextStyle? style;

  /// Total fade duration.
  final Duration duration;

  /// How long to stay fully visible before fading.
  final Duration hold;

  final Curve curve;
  final VoidCallback? onFinished;

  /// If true, starts the fade when first built.
  final bool autoplay;

  @override
  State<FadingNumber> createState() => FadingNumberState();
}

class FadingNumberState extends State<FadingNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ).drive(Tween(begin: 1.0, end: 0.0));

    if (widget.autoplay) {
      // Start after first frame so layout is done.
      WidgetsBinding.instance.addPostFrameCallback((_) => replay());
    }
  }

  /// Call this to show the number again and fade it away.
  Future<void> replay() async {
    if (!mounted) return;

    _controller.stop();
    _controller.value = 0.0; // 0 => fully visible (begin)

    if (widget.hold > Duration.zero) {
      await Future.delayed(widget.hold);
      if (!mounted) return;
    }

    await _controller.forward();
    widget.onFinished?.call();
  }

  @override
  void didUpdateWidget(covariant FadingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Optional: auto-replay if the number *changes*.
    if (oldWidget.number != widget.number) {
      // If you want this behavior, keep it.
      // If you only want manual triggers, remove this block.
      WidgetsBinding.instance.addPostFrameCallback((_) => replay());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = widget.style ?? DefaultTextStyle.of(context).style;
    final effectiveStyle = baseStyle.copyWith(color: widget.color);

    return FadeTransition(
      opacity: _opacity,
      child: Text('${widget.number}', style: effectiveStyle),
    );
  }
}
