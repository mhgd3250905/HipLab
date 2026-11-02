// Assessment stills retain their two theme variants. Public transparent posters
// replace the old theme-specific action clips and are checked against catalog.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hiplab/hip/data/hip_action_scope.dart';
import 'package:hiplab/hip/domain/hip_action_media.dart';
import 'package:hiplab/hip/ui/hip_theme.dart';

void main() {
  final manifest =
      jsonDecode(File(HipActionMedia.assetPath).readAsStringSync())
          as Map<String, dynamic>;
  final variants = HipActionMedia.fromJson(manifest);

  test('assessment still variants retain exact bytes and hashes', () {
    final listed = <String>{};
    var count = 0;
    for (final set in (manifest['stills'] as Map).values) {
      for (final item in (set['items'] as Map).values) {
        final dark = item['dark'] as Map;
        final light = item['light'] as Map;
        expect(light['width'], dark['width']);
        expect(variants.lightOf(dark['asset'] as String), light['asset']);
        for (final entry in [dark, light]) {
          final path = entry['asset'] as String;
          listed.add(path);
          final bytes = File(path).readAsBytesSync();
          expect(bytes.length, entry['bytes'], reason: path);
          expect(_sha256Hex(bytes), entry['sha256'], reason: path);
        }
        count++;
      }
    }
    expect(count, 20);
    for (final file in Directory(
      'assets/hip/assessment/light',
    ).listSync().whereType<File>()) {
      expect(listed, contains(file.path.replaceAll(r'\', '/')));
    }
  });

  test('public transparent posters match the pinned SDK frame-zero index', () {
    final config = File('.dart_tool/package_config.json');
    final packages = jsonDecode(config.readAsStringSync())['packages'] as List;
    final sdk = packages.firstWhere((p) => p['name'] == 'ugk_coach') as Map;
    final sdkRoot = config.uri.resolve(sdk['rootUri'] as String);
    final catalog =
        jsonDecode(
              File.fromUri(
                sdkRoot.resolve(
                  'packages/ugk_trainer/assets/pose_hub/app-test-pack-r1/standing/index.json',
                ),
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final wanted = {...hiplabCoachAuthorizedActionIds, 'n-thomas-test'};
    final covers = {
      for (final action in catalog['actions'] as List)
        if (wanted.contains(action['id']))
          action['id'] as String: action as Map,
    };
    expect(covers.keys.toSet(), wanted);
    for (final entry in covers.entries) {
      final path = 'assets/public_posters/${entry.key}.webp';
      final bytes = File(path).readAsBytesSync();
      expect(bytes.length, entry.value['bytes'], reason: path);
      expect(_sha256Hex(bytes), entry.value['sha256'], reason: path);
      expect(entry.value['alpha'], isTrue, reason: path);
      expect(entry.value['sourceVideo']['frameIndex'], 0, reason: path);
    }
  });

  test('retained assessment stage matches the App palette', () {
    final stage = (manifest['stage'] as Map)['light'] as String;
    final color = HipPalette.light.mediaBackdrop.toARGB32() & 0xffffff;
    expect(
      stage.toUpperCase(),
      '#${color.toRadixString(16).padLeft(6, '0').toUpperCase()}',
    );
    expect((color >> 16) & 0xff, color & 0xff);
    expect((color >> 8) & 0xff, color & 0xff);
  });

  test('sha256 helper matches the FIPS 180-2 vector', () {
    expect(
      _sha256Hex(Uint8List.fromList(utf8.encode('abc'))),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });
}

// Minimal SHA-256 (FIPS 180-4) so the manifest check needs no new package.
String _sha256Hex(Uint8List data) {
  const k = <int>[
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, //
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];
  final h = <int>[
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, //
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];
  int rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & 0xffffffff;
  final bitLen = data.length * 8;
  final padLen = ((data.length + 9 + 63) ~/ 64) * 64;
  final msg = Uint8List(padLen)..setRange(0, data.length, data);
  msg[data.length] = 0x80;
  final bd = ByteData.sublistView(msg);
  bd.setUint32(padLen - 8, (bitLen ~/ 0x100000000) & 0xffffffff);
  bd.setUint32(padLen - 4, bitLen & 0xffffffff);
  final w = List<int>.filled(64, 0);
  for (var off = 0; off < padLen; off += 64) {
    for (var i = 0; i < 16; i++) {
      w[i] = bd.getUint32(off + i * 4);
    }
    for (var i = 16; i < 64; i++) {
      final s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & 0xffffffff;
    }
    var a = h[0], b = h[1], c = h[2], d = h[3];
    var e = h[4], f = h[5], g = h[6], hh = h[7];
    for (var i = 0; i < 64; i++) {
      final s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
      final ch = (e & f) ^ (~e & 0xffffffff & g);
      final t1 = (hh + s1 + ch + k[i] + w[i]) & 0xffffffff;
      final s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + maj) & 0xffffffff;
      hh = g;
      g = f;
      f = e;
      e = (d + t1) & 0xffffffff;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & 0xffffffff;
    }
    h[0] = (h[0] + a) & 0xffffffff;
    h[1] = (h[1] + b) & 0xffffffff;
    h[2] = (h[2] + c) & 0xffffffff;
    h[3] = (h[3] + d) & 0xffffffff;
    h[4] = (h[4] + e) & 0xffffffff;
    h[5] = (h[5] + f) & 0xffffffff;
    h[6] = (h[6] + g) & 0xffffffff;
    h[7] = (h[7] + hh) & 0xffffffff;
  }
  return h.map((x) => x.toRadixString(16).padLeft(8, '0')).join();
}
