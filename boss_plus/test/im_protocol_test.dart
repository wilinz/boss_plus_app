import 'dart:convert';
import 'dart:typed_data';
import 'package:boss_plus/boss_plus.dart';
import 'package:test/test.dart';

void main() {
  test('encode text send round-trips', () {
    final bytes = ChatProtocol.encodeTextSend(
      fromUid: 756381816, fromName: '韦立赞', toUid: 576061964,
      text: '你好', clientMsgId: 1783235803643);
    final dec = ChatProtocol.decode(bytes);
    expect(dec.type, ImType.chat);
    expect(dec.messages.length, 1);
    final m = dec.messages.first;
    expect(m.fromUid, 756381816);
    expect(m.toUid, 576061964);
    expect(m.contentType, ContentType.text);
    expect(m.text, '你好');
  });

  test('decode REAL captured send/push envelope extracts 你好', () {
    const b64 = 'CAESAzEuNBpSChMI+PDV6AISCemfpueri+i1njgAEggIjITYkgI4ABgBIPvzi4nzMyj784uJ8zMyDAgBEAEaBuS9oOWlvTgAUABY+/OLifMzYAJoAJABAKABAA==';
    final dec = ChatProtocol.decode(Uint8List.fromList(base64.decode(b64)));
    expect(dec.type, ImType.chat);
    expect(dec.messages.where((m) => m.isText).map((m) => m.text), contains('你好'));
  });
}
