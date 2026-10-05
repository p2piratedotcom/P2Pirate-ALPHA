import 'package:flutter/material.dart';

/// Installation is unknown until both local checks and the connection finish.
/// Keep download progress and genuine installation prompts behind that check.
class MmEngineLoadingGate extends StatelessWidget {
  const MmEngineLoadingGate({
    required this.loading,
    required this.child,
    super.key,
  });

  final bool loading;
  final Widget child;

  @override
  Widget build(BuildContext context) => loading
      ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        )
      : child;
}
