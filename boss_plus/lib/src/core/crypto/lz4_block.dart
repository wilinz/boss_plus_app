import 'dart:typed_data';

/// LZ4 块格式(block format)的最小实现。
///
/// BOSS 的 `sp`/请求体在 native(`libyzwg.so`,导出 `LZ4_*`)里先把明文做 **LZ4 块压缩**,
/// 再套 [BZPBlock] 头、RC4、base64。逆向见 `docs/libyzwg-native-analysis.md`。
///
/// 我们**编码时只需产出「合法的 LZ4 块」**——服务端解压得到原文即可,不要求和官方
/// 压缩器逐字节一致。因此 [compressBlock] 直接产出「纯 literal(无回溯匹配)」的块:
/// 一个只含字面量、末尾不带 match 的序列本身就是合法完整的 LZ4 块。
/// [decompressBlock] 是完整解码(用于自测/解密响应)。
class Lz4Block {
  const Lz4Block._();

  /// 纯 literal 压缩:输出一个合法 LZ4 块,解压后 == [src]。
  static Uint8List compressBlock(Uint8List src) {
    final out = BytesBuilder();
    final n = src.length;
    // token 的高 4 位是 literal 长度,低 4 位是 match 长度(此处恒 0,末尾无 match)。
    final ll = n < 15 ? n : 15;
    out.addByte(ll << 4);
    if (n >= 15) {
      var remain = n - 15;
      while (remain >= 255) {
        out.addByte(255);
        remain -= 255;
      }
      out.addByte(remain);
    }
    out.add(src);
    return out.toBytes();
  }

  /// 标准 LZ4 块解码(literal + match 回溯拷贝)。[maxOutput] 可限制输出上限。
  static Uint8List decompressBlock(Uint8List src, {int? maxOutput}) {
    final out = BytesBuilder();
    var i = 0;
    final bytes = <int>[]; // 需要按索引回溯,用可增长列表
    void emit(int b) {
      bytes.add(b);
    }

    while (i < src.length) {
      final token = src[i++];
      var litLen = token >> 4;
      if (litLen == 15) {
        while (true) {
          final b = src[i++];
          litLen += b;
          if (b != 255) break;
        }
      }
      for (var k = 0; k < litLen; k++) {
        emit(src[i++]);
        if (maxOutput != null && bytes.length >= maxOutput) {
          out.add(bytes);
          return out.toBytes();
        }
      }
      if (i >= src.length) break; // 末尾 literal-only 序列,结束
      if (i + 2 > src.length) break; // 截断数据:offset 不完整,提前结束
      final offset = src[i] | (src[i + 1] << 8);
      i += 2;
      var matchLen = token & 0x0f;
      if (matchLen == 15) {
        while (true) {
          final b = src[i++];
          matchLen += b;
          if (b != 255) break;
        }
      }
      matchLen += 4;
      final start = bytes.length - offset;
      if (start < 0) break; // 截断数据:回溯越界,返回已解出的部分
      for (var k = 0; k < matchLen; k++) {
        if (start + k >= bytes.length) break;
        emit(bytes[start + k]);
        if (maxOutput != null && bytes.length >= maxOutput) {
          out.add(bytes);
          return out.toBytes();
        }
      }
    }
    out.add(bytes);
    return out.toBytes();
  }
}
