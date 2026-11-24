// Regenerates every platform app icon from one 1024x1024 source.
//
//   flutter test tool/icons/generate_icons_test.dart
//
// Source: tool/icons/app_icon_source.png (the launcher icon from `main`,
// commit 8bfd476). To rebrand, replace that file and re-run.
//
// It runs as a test only so it can use Flutter's image engine (dart:ui) for
// decoding, resizing and PNG encoding — no extra packages needed.
//
// Outputs
//   Android  mipmap-*/ic_launcher_foreground.png,
//            ic_launcher_background.png, ic_launcher_monochrome.png,
//            mipmap-anydpi-v26/ic_launcher.xml (adaptive + themed icon)
//   iOS      (REGENERATE_ALL only) AppIcon.appiconset/*; Android legacy
//            mipmap-*/ic_launcher.png likewise
//   web      favicon.png, icons/Icon-192/512, Icon-maskable-192/512
//   macOS    AppIcon.appiconset/app_icon_{16..1024}.png (rounded square)
//   Windows  runner/resources/app_icon.ico (16–256, PNG-compressed)
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';

const _source = 'tool/icons/app_icon_source.png';

/// The legacy Android ic_launcher.png and the iOS AppIcon set were exported
/// by the design team (commit 8bfd476), so they are left alone by default.
/// Pass --dart-define=REGENERATE_ALL=true after replacing the source to
/// rebuild those too.
const _regenerateAll = bool.fromEnvironment('REGENERATE_ALL');

// Colours sampled from the source icon.
const _base = [14, 94, 74]; // #0E5E4A background green
const _white = [255, 255, 255];
const _gold = [242, 169, 0];

/// Adaptive icons show the middle 72dp of a 108dp layer; scaling the artwork
/// by 2/3 makes the visible result match the legacy square icon.
const _adaptiveScale = 72 / 108;

Future<ui.Image> _decode(Uint8List bytes) async => (await (await ui.instantiateImageCodec(bytes)).getNextFrame()).image;

Future<ui.Image> _fromRgba(Uint8List rgba, int w, int h) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(buffer, width: w, height: h, pixelFormat: ui.PixelFormat.rgba8888);
  return (await (await descriptor.instantiateCodec()).getNextFrame()).image;
}

Future<Uint8List> _png(ui.Image img) async => (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();

/// Draws [src] into a [size]x[size] canvas through [paint].
Future<ui.Image> _render(int size, void Function(ui.Canvas canvas, double s) paint) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  paint(canvas, size.toDouble());
  return recorder.endRecording().toImage(size, size);
}

final _hq = ui.Paint()
  ..filterQuality = ui.FilterQuality.high
  ..isAntiAlias = true;

void _drawScaled(ui.Canvas c, ui.Image img, double size, {double scale = 1}) {
  final d = size * scale;
  final o = (size - d) / 2;
  c.drawImageRect(img, ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()), ui.Rect.fromLTWH(o, o, d, d), _hq);
}

Future<void> _write(String path, Uint8List bytes) async {
  final f = File(path);
  await f.parent.create(recursive: true);
  await f.writeAsBytes(bytes);
  // ignore: avoid_print
  print('  wrote $path (${bytes.length} B)');
}

Future<void> _resized(ui.Image img, int size, String path, {double scale = 1, List<int>? fill}) async {
  final out = await _render(size, (c, s) {
    if (fill != null) c.drawRect(ui.Rect.fromLTWH(0, 0, s, s), ui.Paint()..color = ui.Color.fromARGB(255, fill[0], fill[1], fill[2]));
    _drawScaled(c, img, s, scale: scale);
  });
  await _write(path, await _png(out));
}

/// Splits the flat source into (mark-only with alpha, background-only).
/// Each pixel is treated as a blend of the green and either white or gold;
/// solving for the blend keeps the anti-aliased edges intact.
(Uint8List, Uint8List) _separate(ByteData src, int w, int h) {
  final mark = Uint8List(w * h * 4);
  final bg = Uint8List(w * h * 4);
  for (var i = 0; i < w * h; i++) {
    final p = [src.getUint8(i * 4), src.getUint8(i * 4 + 1), src.getUint8(i * 4 + 2)];
    var bestA = 0.0, bestErr = double.infinity;
    List<int> bestF = _white;
    for (final f in [_white, _gold]) {
      var num = 0.0, den = 0.0;
      for (var k = 0; k < 3; k++) {
        num += (p[k] - _base[k]) * (f[k] - _base[k]);
        den += (f[k] - _base[k]) * (f[k] - _base[k]);
      }
      final a = (num / den).clamp(0.0, 1.0);
      var err = 0.0;
      for (var k = 0; k < 3; k++) {
        final e = p[k] - (a * f[k] + (1 - a) * _base[k]);
        err += e * e;
      }
      if (err < bestErr) (bestErr, bestA, bestF) = (err, a, f);
    }
    // The lighter corner circles read as ~5% "white"; ignore anything that faint.
    final isMark = bestA > 0.06;
    final a = isMark ? bestA : 0.0;
    for (var k = 0; k < 3; k++) {
      mark[i * 4 + k] = bestF[k];
      bg[i * 4 + k] = isMark ? _base[k] : p[k];
    }
    mark[i * 4 + 3] = (a * 255).round();
    bg[i * 4 + 3] = 255;
  }
  return (mark, bg);
}

/// Windows .ico with PNG-compressed entries (supported since Vista).
Uint8List _ico(List<(int, Uint8List)> entries) {
  final header = BytesBuilder();
  final dir = ByteData(6 + 16 * entries.length);
  dir.setUint16(0, 0, Endian.little);
  dir.setUint16(2, 1, Endian.little); // icon
  dir.setUint16(4, entries.length, Endian.little);
  var offset = 6 + 16 * entries.length;
  for (var i = 0; i < entries.length; i++) {
    final (size, png) = entries[i];
    final o = 6 + 16 * i;
    dir.setUint8(o, size >= 256 ? 0 : size);
    dir.setUint8(o + 1, size >= 256 ? 0 : size);
    dir.setUint16(o + 4, 1, Endian.little); // planes
    dir.setUint16(o + 6, 32, Endian.little); // bpp
    dir.setUint32(o + 8, png.length, Endian.little);
    dir.setUint32(o + 12, offset, Endian.little);
    offset += png.length;
  }
  header.add(dir.buffer.asUint8List());
  for (final (_, png) in entries) {
    header.add(png);
  }
  return header.toBytes();
}

void main() {
  testWidgets('generate app icons', (tester) async {
    await tester.runAsync(() async {
      final source = await _decode(File(_source).readAsBytesSync());
      expect(source.width, 1024, reason: 'Source must be 1024x1024');
      expect(source.height, 1024);
      final raw = (await source.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;
      final (markRgba, bgRgba) = _separate(raw, source.width, source.height);
      final mark = await _fromRgba(markRgba, source.width, source.height);
      final background = await _fromRgba(bgRgba, source.width, source.height);
      // Monochrome (Android 13 themed icons): the mark's shape in white.
      final mono = Uint8List.fromList(markRgba);
      for (var i = 0; i < mono.length; i += 4) {
        mono[i] = mono[i + 1] = mono[i + 2] = 255;
      }
      final monochrome = await _fromRgba(mono, source.width, source.height);

      // ---------------------------------------------------------- Android
      const res = 'android/app/src/main/res';
      const legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
      for (final e in legacy.entries) {
        if (_regenerateAll) await _resized(source, e.value, '$res/mipmap-${e.key}/ic_launcher.png');
        final layer = (e.value * 108 / 48).round(); // 108dp adaptive layer
        await _resized(mark, layer, '$res/mipmap-${e.key}/ic_launcher_foreground.png', scale: _adaptiveScale);
        await _resized(background, layer, '$res/mipmap-${e.key}/ic_launcher_background.png', scale: _adaptiveScale, fill: _base);
        await _resized(monochrome, layer, '$res/mipmap-${e.key}/ic_launcher_monochrome.png', scale: _adaptiveScale);
      }
      await _write(
        '$res/mipmap-anydpi-v26/ic_launcher.xml',
        Uint8List.fromList('''<?xml version="1.0" encoding="utf-8"?>
<!-- Generated by tool/icons/generate_icons_test.dart -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
'''
            .codeUnits),
      );

      // ---------------------------------------------------------- iOS
      const ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
      if (_regenerateAll) {
      for (final f in Directory(ios).listSync().whereType<File>().where((f) => f.path.endsWith('.png'))) {
        final name = f.uri.pathSegments.last; // Icon-App-20x20@2x.png
        final m = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png').firstMatch(name);
        if (m == null) continue;
        final px = (double.parse(m.group(1)!) * int.parse(m.group(2)!)).round();
        if (px == 1024) continue; // the source itself
        await _resized(source, px, '$ios/$name', fill: _base); // iOS icons must be opaque
      }
      }

      // ---------------------------------------------------------- web
      await _resized(source, 32, 'web/favicon.png');
      await _resized(source, 192, 'web/icons/Icon-192.png');
      await _resized(source, 512, 'web/icons/Icon-512.png');
      // Maskable: full-bleed green, artwork inside the 80% safe zone.
      await _resized(background, 192, 'web/icons/Icon-maskable-192.png', scale: 0.8, fill: _base);
      await _resized(background, 512, 'web/icons/Icon-maskable-512.png', scale: 0.8, fill: _base);
      for (final s in [192, 512]) {
        final path = 'web/icons/Icon-maskable-$s.png';
        final bg = await _decode(File(path).readAsBytesSync());
        final out = await _render(s, (c, size) {
          _drawScaled(c, bg, size);
          _drawScaled(c, mark, size, scale: 0.8);
        });
        await _write(path, await _png(out));
      }

      // ---------------------------------------------------------- macOS
      // Big Sur style: 824pt rounded square centred in the 1024 canvas.
      final macMaster = await _render(1024, (c, s) {
        const inset = 100.0;
        final rect = ui.Rect.fromLTWH(inset, inset, s - inset * 2, s - inset * 2);
        final rrect = ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(185));
        c.drawRRect(rrect.shift(const ui.Offset(0, 10)), ui.Paint()
          ..color = const ui.Color(0x40000000)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 14));
        c.save();
        c.clipRRect(rrect);
        c.drawImageRect(source, ui.Rect.fromLTWH(0, 0, 1024, 1024), rect, _hq);
        c.restore();
      });
      for (final s in [16, 32, 64, 128, 256, 512, 1024]) {
        await _resized(macMaster, s, 'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_$s.png');
      }

      // ---------------------------------------------------------- Windows
      final entries = <(int, Uint8List)>[];
      for (final s in [16, 24, 32, 48, 64, 128, 256]) {
        final img = await _render(s, (c, size) => _drawScaled(c, source, size));
        entries.add((s, await _png(img)));
      }
      await _write('windows/runner/resources/app_icon.ico', _ico(entries));

      // Sanity: the separated mark really has transparent surroundings.
      expect(markRgba[3], 0, reason: 'top-left of foreground should be transparent');
      expect(math.max(markRgba[(528 * 1024 + 450) * 4 + 3], 0), greaterThan(200), reason: 'mark centre should be opaque');
    });
  });
}
