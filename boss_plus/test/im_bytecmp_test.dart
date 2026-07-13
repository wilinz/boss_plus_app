import 'dart:convert';
import 'package:boss_plus/boss_plus.dart';
import 'package:test/test.dart';
void main() {
  test('encodeTextSend BYTE-EXACT vs real captured envelope', () {
    final mine = ChatProtocol.encodeTextSend(
      fromUid: 756381816, fromName: '韦立赞', toUid: 576061964,
      text: '你好', clientMsgId: 1783235803643);
    const real = 'CAESAzEuNBpSChMI+PDV6AISCemfpueri+i1njgAEggIjITYkgI4ABgBIPvzi4nzMyj784uJ8zMyDAgBEAEaBuS9oOWlvTgAUABY+/OLifMzYAJoAJABAKABAA==';
    expect(base64.encode(mine), equals(real));
  });
}
