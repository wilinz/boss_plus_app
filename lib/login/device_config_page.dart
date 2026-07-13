import 'package:boss_plus/boss_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/boss_provider.dart';
import '../data/device_config_store.dart';

/// 设备指纹编辑页:查看/修改并持久化 [BossAppConfig]。
///
/// 这些值会进 `User-Agent` 与加密的 `client_info`,决定服务端看到的「设备」。
/// 保存后 [BossProvider.reset] 使客户端用新指纹重建。返回 `true` 表示已改动。
class DeviceConfigPage extends StatefulWidget {
  const DeviceConfigPage({super.key, this.username});

  /// 编辑哪个用户名(登录手机号)的设备指纹;null = 默认桶(登录前未填手机号)。
  final String? username;

  @override
  State<DeviceConfigPage> createState() => _DeviceConfigPageState();
}

class _DeviceConfigPageState extends State<DeviceConfigPage> {
  final _form = GlobalKey<FormState>();

  final _uniqid = TextEditingController();
  final _manufacturer = TextEditingController();
  final _model = TextEditingController();
  final _osVersion = TextEditingController();
  final _screenW = TextEditingController();
  final _screenH = TextEditingController();
  final _channel = TextEditingController();
  final _oaid = TextEditingController();
  final _did = TextEditingController();
  final _versionName = TextEditingController();
  final _versionCode = TextEditingController();
  String _netType = 'WIFI';

  BossAppConfig? _base;
  bool _loading = true;

  static const _netTypes = ['WIFI', '5G', '4G', '3G'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cfg = await DeviceConfigStore.instance.get(username: widget.username);
    _fill(cfg);
    setState(() => _loading = false);
  }

  void _fill(BossAppConfig cfg) {
    _base = cfg;
    _uniqid.text = cfg.uniqid;
    _manufacturer.text = cfg.manufacturer;
    _model.text = cfg.model;
    _osVersion.text = cfg.osVersion;
    _screenW.text = cfg.screenWidth.toString();
    _screenH.text = cfg.screenHeight.toString();
    _channel.text = cfg.channel;
    _oaid.text = cfg.oaid;
    _did.text = cfg.did;
    _versionName.text = cfg.versionName;
    _versionCode.text = cfg.versionCode;
    _netType = _netTypes.contains(cfg.netType) ? cfg.netType : 'WIFI';
  }

  /// 随机换一台真实机型(uniqid/厂商/机型/系统/网络/屏幕全变,其余保留)。
  void _randomize() {
    final r = DeviceConfigStore.randomDevice();
    setState(() {
      _uniqid.text = r.uniqid;
      _manufacturer.text = r.manufacturer;
      _model.text = r.model;
      _osVersion.text = r.osVersion;
      _screenW.text = r.screenWidth.toString();
      _screenH.text = r.screenHeight.toString();
      _netType = _netTypes.contains(r.netType) ? r.netType : 'WIFI';
    });
  }

  BossAppConfig _build() => (_base ?? DeviceConfigStore.randomDevice()).copyWith(
        uniqid: _uniqid.text.trim(),
        manufacturer: _manufacturer.text.trim(),
        model: _model.text.trim(),
        osVersion: _osVersion.text.trim(),
        screenWidth: int.tryParse(_screenW.text.trim()),
        screenHeight: int.tryParse(_screenH.text.trim()),
        channel: _channel.text.trim(),
        netType: _netType,
        oaid: _oaid.text.trim(),
        did: _did.text.trim(),
        versionName: _versionName.text.trim(),
        versionCode: _versionCode.text.trim(),
      );

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await DeviceConfigStore.instance.save(_build(), username: widget.username);
    BossProvider.instance.reset(); // 下次请求用新指纹重建客户端
    if (mounted) Get.back(result: true);
  }

  @override
  void dispose() {
    for (final c in [
      _uniqid,
      _manufacturer,
      _model,
      _osVersion,
      _screenW,
      _screenH,
      _channel,
      _oaid,
      _did,
      _versionName,
      _versionCode,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username == null || widget.username!.isEmpty
            ? '设备指纹 · 默认'
            : '设备指纹 · ${widget.username}'),
        actions: [
          IconButton(
            tooltip: '随机换一台设备',
            onPressed: _loading ? null : _randomize,
            icon: const Icon(Icons.casino_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _hint('这些值会写入 User-Agent 与加密的 client_info,'
                      '决定服务端看到的「设备」。修改后保存即用新指纹重建连接。'),
                  const SizedBox(height: 16),
                  _section('标识'),
                  _field(_uniqid, '设备唯一 ID (uniqid)', required: true),
                  const SizedBox(height: 12),
                  _section('机型'),
                  _field(_manufacturer, '厂商 (manufacturer)', required: true),
                  _field(_model, '机型代号 (model)', required: true),
                  _field(_osVersion, 'Android 版本', required: true),
                  Row(children: [
                    Expanded(child: _field(_screenW, '屏幕宽', number: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_screenH, '屏幕高', number: true)),
                  ]),
                  const SizedBox(height: 12),
                  _section('网络 / 渠道'),
                  DropdownButtonFormField<String>(
                    initialValue: _netType,
                    decoration: const InputDecoration(
                      labelText: '网络类型 (netType)',
                      border: OutlineInputBorder(),
                    ),
                    items: _netTypes
                        .map((n) =>
                            DropdownMenuItem(value: n, child: Text(n)))
                        .toList(),
                    onChanged: (v) => setState(() => _netType = v ?? 'WIFI'),
                  ),
                  const SizedBox(height: 12),
                  _field(_channel, '渠道号 (channel)'),
                  _field(_oaid, 'OAID(可空)'),
                  _field(_did, '数盟 did(可空)'),
                  const SizedBox(height: 12),
                  _section('版本'),
                  _hint('⚠️ 版本号与签名密钥绑定,改错会导致请求签名失败,'
                      '非必要勿动。'),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _field(_versionName, '版本名 (versionName)')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _field(_versionCode, '版本号 (versionCode)')),
                  ]),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    child: const Text('保存'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(t,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary)),
      );

  Widget _hint(String t) => Text(t,
      style: const TextStyle(color: Colors.grey, fontSize: 12, height: 1.4));

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    bool number = false,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: number ? TextInputType.number : null,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          validator: (v) {
            final s = (v ?? '').trim();
            if (required && s.isEmpty) return '不能为空';
            if (number && s.isNotEmpty && int.tryParse(s) == null) {
              return '请输入数字';
            }
            return null;
          },
        ),
      );
}
