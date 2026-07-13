/// 真实安卓机型样本 (厂商, 机型代号, 基准系统版本)。
///
/// 供 [BossAppConfig.forDevice] 由 deviceId 确定性派生机型指纹用,避免所有设备
/// 指纹一致而被特征化。可按需扩充。
const List<(String, String, String)> kRealDeviceProfiles = [
  ('Redmi', '22021211RC', '13'),
  ('Xiaomi', '2211133C', '14'),
  ('Xiaomi', '23049RAD8C', '14'),
  ('HUAWEI', 'ALN-AL00', '12'),
  ('HONOR', 'FNE-AN00', '13'),
  ('OPPO', 'PHK110', '14'),
  ('vivo', 'V2309A', '14'),
  ('OnePlus', 'PJZ110', '14'),
  ('samsung', 'SM-S9180', '14'),
  ('realme', 'RMX3820', '13'),
];
