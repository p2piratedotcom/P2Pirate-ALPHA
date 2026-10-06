import 'package:flutter/material.dart';
import 'package:web_dex/views/dex/simple/form/common/dex_form_group_header.dart';

class TargetProtocolHeader extends StatelessWidget {
  const TargetProtocolHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DexFormGroupHeader(title: 'To network');
  }
}
