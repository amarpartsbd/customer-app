import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/store_state.dart';

/// A money amount that rolls from the number on screen to the new one when [value] changes
/// (ease-out, 0.55 s) — the same counter as the website. Instant when the phone has animations
/// turned off. The first build shows the value straight away.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney(this.value, {super.key, required this.style, this.format});

  final num value;
  final TextStyle style;
  final String Function(num)? format;

  @override
  Widget build(BuildContext context) {
    final fmt = format ?? context.read<StoreState>().fmt;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(fmt(v), style: style, maxLines: 1, softWrap: false),
    );
  }
}
