import 'dart:typed_data';

import 'package:boss_plus/boss_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'geetest_bg.dart';

/// 纯原生(无 WebView)极验 gt3 滑块。跨平台可用(含 Windows)。
///
/// 显示带缺口的背景图 + 拼图块,用户手动把拼图块拖到缺口处;记录真实拖动
/// 距离与轨迹时间戳,用 [GeetestGt3Solver] 直连极验接口换取 validate。
Future<GeetestResult?> showGeetestSliderNative(
  BuildContext context,
  GeetestRegister register,
) {
  return showDialog<GeetestResult>(
    context: context,
    barrierDismissible: true,
    builder: (_) => GeetestSliderNativeDialog(register: register),
  );
}

class GeetestSliderNativeDialog extends StatefulWidget {
  const GeetestSliderNativeDialog({super.key, required this.register});

  final GeetestRegister register;

  @override
  State<GeetestSliderNativeDialog> createState() =>
      _GeetestSliderNativeDialogState();
}

class _GeetestSliderNativeDialogState extends State<GeetestSliderNativeDialog> {
  late GeetestGt3Solver _solver;
  GeetestGt3Challenge? _ch;
  Uint8List? _bgPng; // 还原后的 260×160 背景图
  String? _error;
  bool _submitting = false;

  // 拖动状态
  double _dx = 0; // 拼图块相对起点的水平位移(显示 px == 图 px)
  final List<List<num>> _trace = [];
  DateTime? _dragStart;

  static const _imgW = 260.0; // 还原后背景图宽度(gt3 重组固定 260×160)

  @override
  void initState() {
    super.initState();
    _solver = GeetestGt3Solver(
        gt: widget.register.gt, challenge: widget.register.challenge);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _ch = null;
      _bgPng = null;
      _dx = 0;
      _trace.clear();
    });
    try {
      final ch = await _solver.load();
      // 下载乱序 bg 并还原成 260×160。
      final resp = await Dio().get<List<int>>(ch.bgUrl,
          options: Options(responseType: ResponseType.bytes));
      final png = deshuffleGt3Bg(Uint8List.fromList(resp.data!));
      if (mounted) {
        setState(() {
          _ch = ch;
          _bgPng = png;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = '加载失败: $e');
    }
  }

  void _onPanStart(DragStartDetails d) {
    _dragStart = DateTime.now();
    _trace
      ..clear()
      ..add([0, 0, 0]);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    final ch = _ch;
    if (ch == null) return;
    final maxX = _imgW - 40; // 拼图块宽约 40,别拖出边界
    setState(() => _dx = (_dx + d.delta.dx).clamp(0.0, maxX));
    final t = DateTime.now().difference(_dragStart!).inMilliseconds;
    _trace.add([_dx.round(), (d.delta.dy).round(), t]);
  }

  Future<void> _onPanEnd(DragEndDetails d) async {
    if (_ch == null || _submitting || _dx < 3) return;
    setState(() => _submitting = true);
    try {
      final validate = await _solver.submit(_dx, _trace);
      if (!mounted) return;
      if (validate != null) {
        Navigator.of(context).pop(GeetestResult(
          challenge: _solver.challenge,
          validate: validate,
          seccode: '$validate|jordan',
        ));
      } else {
        setState(() {
          _error = '验证未通过,请重试';
          _submitting = false;
        });
        _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '提交失败: $e';
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('拖动拼图完成验证',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: '换一张',
                  onPressed: _submitting ? null : _load,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildBody(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final ch = _ch;
    final bg = _bgPng;
    if (_error != null && ch == null) {
      return const SizedBox(height: 160);
    }
    if (ch == null || bg == null) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Column(
      children: [
        // 背景图(已还原) + 可拖动拼图块
        SizedBox(
          width: _imgW,
          height: 160,
          child: Stack(
            children: [
              Image.memory(bg, width: _imgW, height: 160, fit: BoxFit.fill),
              Positioned(
                left: ch.xpos + _dx,
                top: ch.ypos.toDouble(),
                child: Image.network(ch.sliceUrl),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 底部拖动条
        GestureDetector(
          onHorizontalDragStart: _submitting ? null : _onPanStart,
          onHorizontalDragUpdate: _submitting ? null : _onPanUpdate,
          onHorizontalDragEnd: _submitting ? null : _onPanEnd,
          child: Container(
            width: _imgW,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(_submitting ? '验证中…' : '按住滑块拖动',
                      style: const TextStyle(
                          color: Colors.black45, fontSize: 13)),
                ),
                Positioned(
                  left: _dx,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF12B7A0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
