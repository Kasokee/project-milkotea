import 'package:flutter/material.dart';

class AnimatedCartBadge extends StatelessWidget {
  const AnimatedCartBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
      child: count == 0
          ? const SizedBox.shrink(key: ValueKey('empty'))
          : Container(
              key: ValueKey(count),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}
