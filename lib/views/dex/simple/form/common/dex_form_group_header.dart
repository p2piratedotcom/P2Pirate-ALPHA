import 'package:flutter/material.dart';
import 'package:web_dex/views/dex/simple/form/common/dex_form_title.dart';

class DexFormGroupHeader extends StatelessWidget {
  const DexFormGroupHeader({
    this.title,
    this.actions,
    this.background,
    this.readableTitle = false,
    Key? key,
  }) : super(key: key);

  final String? title;
  final bool readableTitle;
  final List<Widget>? actions;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (background != null)
          Positioned(left: 0, right: 0, top: 0, bottom: 0, child: background!),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final headerTitle = title == null
                    ? null
                    : DexFormTitle(title!, readable: readableTitle);
                if (actions == null)
                  return headerTitle ?? const SizedBox.shrink();
                if (readableTitle && constraints.maxWidth < 480) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (headerTitle != null) headerTitle,
                      if (headerTitle != null) const SizedBox(height: 8),
                      Row(children: actions!),
                    ],
                  );
                }
                return Row(
                  children: [
                    if (headerTitle != null) headerTitle,
                    if (headerTitle != null) const SizedBox(width: 12),
                    Expanded(child: Row(children: actions!)),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
