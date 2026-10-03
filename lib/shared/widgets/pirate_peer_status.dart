import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';

int connectedPeerCount(Object? response) {
  if (response is! Map || response['result'] is! Map) {
    throw const FormatException('Invalid connected peer response');
  }
  // KDF maps each distinct peer ID to its addresses. Count IDs, not addresses.
  return (response['result'] as Map).length;
}

class PiratePeerStatus extends StatefulWidget {
  const PiratePeerStatus({super.key});
  @override
  State<PiratePeerStatus> createState() => _PiratePeerStatusState();
}

class _PiratePeerStatusState extends State<PiratePeerStatus> {
  Timer? _timer;
  StreamSubscription<AuthBlocState>? _authSubscription;
  AuthBloc? _auth;
  HttpClient? _client;
  int? _count;
  String? _wallet;
  bool _reading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer != null) return;
    try {
      _auth = context.read<AuthBloc>();
    } catch (_) {
      return;
    }
    _authSubscription = _auth!.stream.listen((_) {
      if (mounted) {
        setState(() {
          _count = null;
          _wallet = null;
        });
      }
      _poll();
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
    _poll();
  }

  Future<void> _poll() async {
    if (_reading || !mounted) return;
    final user = _auth?.state.currentUser;
    if (user == null) return;
    final wallet = user.walletId.compoundId;
    _reading = true;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 2)
      ..findProxy = (_) =>
          'DIRECT'; // Local KDF IPC; remote traffic stays on Tor.
    _client = client;
    try {
      final password = await context.read<KomodoDefiSdk>().getRpcPassword();
      if (password == null || password.isEmpty) return;
      const port = int.fromEnvironment(
        'P2PIRATE_LOCAL_RPC_PORT',
        defaultValue: 7783,
      );
      final request = await client
          .postUrl(Uri.parse('http://127.0.0.1:$port'))
          .timeout(const Duration(seconds: 3));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'method': 'get_directly_connected_peers',
          'userpass': password,
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 3),
      );
      final body = await utf8.decoder
          .bind(response)
          .join()
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 200) {
        throw const FormatException('Peer query unavailable');
      }
      final count = connectedPeerCount(jsonDecode(body));
      if (mounted && _auth?.state.currentUser?.walletId.compoundId == wallet) {
        setState(() {
          _count = count;
          _wallet = wallet;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _count = null;
          _wallet = null;
        });
      }
    } finally {
      client.close(force: true);
      _client = null;
      _reading = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _authSubscription?.cancel();
    _client?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_auth?.state.currentUser == null) return const SizedBox.shrink();
    final valid = _wallet == _auth?.state.currentUser?.walletId.compoundId;
    return Tooltip(
      message: 'Directly connected KDF peers. Updated every 15 seconds.',
      child: Text(
        valid && _count != null
            ? '$_count ${_count == 1 ? 'Peer' : 'Peers'}'
            : 'Peers: unavailable',
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}
