import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// gt3 背景图是**列错切乱序**的:52 片(10×80),需按固定位置表重排成 260×160。
/// 源:crowod/GeetestV3 img_locate.location_list。
const _upperXs = [
  157, 145, 265, 277, 181, 169, 241, 253, 109, 97, 289, 301, 85,
  73, 25, 37, 13, 1, 121, 133, 61, 49, 217, 229, 205, 193,
];
const _lowerXs = [
  145, 157, 277, 265, 169, 181, 253, 241, 97, 109, 301, 289, 73,
  85, 37, 25, 1, 13, 133, 121, 49, 61, 229, 217, 193, 205,
];

/// 把乱序 bg 字节还原成 260×160 的 PNG 字节。失败(尺寸不符等)返回原图。
Uint8List deshuffleGt3Bg(Uint8List scrambledBytes) {
  final src = img.decodeImage(scrambledBytes);
  if (src == null || src.width < 311 || src.height < 160) return scrambledBytes;
  final out = img.Image(width: 260, height: 160);
  for (var i = 0; i < 26; i++) {
    // 上半:源 (x,80,10,80) → 目标 (i*10, 0)
    img.compositeImage(
        out, img.copyCrop(src, x: _upperXs[i], y: 80, width: 10, height: 80),
        dstX: i * 10, dstY: 0);
    // 下半:源 (x,0,10,80) → 目标 (i*10, 80)
    img.compositeImage(
        out, img.copyCrop(src, x: _lowerXs[i], y: 0, width: 10, height: 80),
        dstX: i * 10, dstY: 80);
  }
  return img.encodePng(out);
}
