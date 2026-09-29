import 'package:flutter/material.dart';

const double swapDesktopScrollbarGutter = 24;

class SwapDesktopScrollArea extends StatelessWidget {
  const SwapDesktopScrollArea({
    required this.controller,
    required this.child,
    this.scrollViewKey,
    super.key,
  });

  final ScrollController controller;
  final Widget child;
  final Key? scrollViewKey;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      interactive: true,
      thickness: 5,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          key: scrollViewKey,
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.only(right: swapDesktopScrollbarGutter),
            child: child,
          ),
        ),
      ),
    );
  }
}
