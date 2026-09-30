import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komodo_defi_framework/komodo_defi_framework.dart';
import 'package:komodo_defi_framework/src/services/tor_seed_resolver.dart';
import 'package:web_dex/model/stored_settings.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/services/storage/base_storage.dart';

void main() {
  tearDown(KdfTorConfig.disable);

  test('Tor is enabled by default on Linux and persists across settings', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final initial = StoredSettings.initial();
    expect(initial.torEnabled, Platform.isLinux);
    expect(
      StoredSettings.fromJson(initial.toJson()).torEnabled,
      initial.torEnabled,
    );
    expect(initial.copyWith(torEnabled: false).torEnabled, isFalse);
  });

  test('seed hostname is resolved by SOCKS and not by local DNS', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((client) {
      var phase = 0;
      client.listen((data) {
        if (phase == 0) {
          expect(data, [5, 1, 0]);
          client.add([5, 0]);
          phase = 1;
        } else {
          expect(data[0], 5);
          expect(data[1], 0xF0);
          expect(data[3], 3);
          client.add([5, 0, 0, 1, 10, 20, 30, 40, 0, 0]);
          client.destroy();
        }
      });
    });
    KdfTorConfig.configure(
      port: server.port,
      libraryPath: '/unused/libtorsocks.so',
      configPath: '/unused/torsocks.conf',
    );

    expect(await TorSeedResolver.resolve('seed.example'), '10.20.30.40');
    expect(await TorSeedResolver.resolve('127.0.0.1'), '127.0.0.1');
  });

  test('disabling Tor is saved and restored', () async {
    final repository = SettingsRepository(storage: _MemorySettingsStorage());
    await repository.updateSettings(
      StoredSettings.initial().copyWith(torEnabled: false),
    );

    expect((await repository.loadSettings()).torEnabled, isFalse);
  });
}

class _MemorySettingsStorage implements BaseStorage {
  final _values = <String, dynamic>{};

  @override
  Future<bool> write(String key, dynamic data) async {
    _values[key] = data;
    return true;
  }

  @override
  Future<dynamic> read(String key) async {
    final value = _values[key];
    return value is String ? jsonDecode(value) : value;
  }

  @override
  Future<bool> delete(String key) async => _values.remove(key) != null;
}
