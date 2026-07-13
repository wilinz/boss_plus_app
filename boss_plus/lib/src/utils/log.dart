/// 轻量日志(可通过 [bossLogEnabled] 关闭)。
bool bossLogEnabled = true;

void bossLog(String msg, {String tag = 'boss'}) {
  if (bossLogEnabled) print('[$tag] $msg');
}

/// 截断长内容,便于日志。
String bossClip(Object? o, {int max = 300}) {
  final s = o?.toString() ?? '';
  return s.length <= max ? s : '${s.substring(0, max)}…(${s.length})';
}
