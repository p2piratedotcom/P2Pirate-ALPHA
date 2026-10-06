import 'package:flutter/material.dart';

/// Always-visible horizontal affordance; controller belongs to this table.
class MmEngineScrollableTable extends StatefulWidget {
  const MmEngineScrollableTable({super.key, required this.child});
  final Widget child;
  @override
  State<MmEngineScrollableTable> createState() =>
      _MmEngineScrollableTableState();
}

class _MmEngineScrollableTableState extends State<MmEngineScrollableTable> {
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
    controller: _scroll,
    thumbVisibility: true,
    scrollbarOrientation: ScrollbarOrientation.bottom,
    child: SingleChildScrollView(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 12),
      child: widget.child,
    ),
  );
}
