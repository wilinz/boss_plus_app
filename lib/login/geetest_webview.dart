import 'dart:convert';

import 'package:boss_plus/boss_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 极验(Geetest gt3)滑块验证 —— 用**官方 JS** 在 WebView 内拉起,用户**手动**拖动。
///
/// 不做打码/自动破解:仅把 BOSS `man/machine` 返回的 gt/challenge 交给极验官方
/// `gt.js`,用户滑动通过后,官方 JS 的 `getValidate()` 产出 {challenge,validate,seccode},
/// 通过 JS bridge 回传 Flutter。
///
/// 用法:`final r = await showGeetestSlider(context, register);`
Future<GeetestResult?> showGeetestSlider(
  BuildContext context,
  GeetestRegister register,
) {
  return showDialog<GeetestResult>(
    context: context,
    barrierDismissible: true,
    builder: (_) => GeetestSliderDialog(register: register),
  );
}

class GeetestSliderDialog extends StatefulWidget {
  const GeetestSliderDialog({super.key, required this.register});

  final GeetestRegister register;

  @override
  State<GeetestSliderDialog> createState() => _GeetestSliderDialogState();
}

class _GeetestSliderDialogState extends State<GeetestSliderDialog> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('GeetestChannel',
          onMessageReceived: _onMessage)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loading = false),
      ));
    // macOS 的 WKWebView 未实现 setOpaque,setBackgroundColor 会抛
    // UnimplementedError;白底已由 HTML 的 body{background:#fff} 保证,故跳过。
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      _controller.setBackgroundColor(Colors.white);
    }
    _controller.loadHtmlString(_html(widget.register));
  }

  void _onMessage(JavaScriptMessage msg) {
    try {
      final data = jsonDecode(msg.message) as Map<String, dynamic>;
      if (data['error'] != null) {
        Navigator.of(context).pop(null);
        return;
      }
      Navigator.of(context).pop(GeetestResult.fromJson(data));
    } catch (_) {
      Navigator.of(context).pop(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text('请拖动滑块完成验证',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(null),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                // EagerGestureRecognizer:让 WebView 抢到拖动手势,
                // 否则外层(Dialog 的滚动/点击)可能把滑块拖动吃掉。
                WebViewWidget(
                  controller: _controller,
                  gestureRecognizers: {
                    Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer()),
                  },
                ),
                if (_loading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// 极验官方 gt3 embed 页面。`product:'bind'` = 无按钮,ready 后直接 verify() 弹滑块。
  static String _html(GeetestRegister r) {
    final gt = jsonEncode(r.gt);
    final challenge = jsonEncode(r.challenge);
    final newCaptcha = r.newCaptcha ? 'true' : 'false';
    return '''
<!DOCTYPE html><html><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<style>html,body{margin:0;padding:0;background:#fff}#cap{padding:8px}</style>
</head><body>
<div id="cap"></div>
<script src="https://static.geetest.com/static/tools/gt.js"></script>
<script>
function post(o){ try{ GeetestChannel.postMessage(JSON.stringify(o)); }catch(e){} }
initGeetest({
  gt: $gt,
  challenge: $challenge,
  offline: false,
  new_captcha: $newCaptcha,
  product: 'bind',
  width: '100%',
  https: true
}, function(cap){
  cap.appendTo('#cap');
  cap.onReady(function(){ cap.verify(); });
  cap.onSuccess(function(){ post(cap.getValidate()); });
  cap.onClose(function(){ post({error:'closed'}); });
  cap.onError(function(e){ post({error: e && e.msg ? e.msg : 'error'}); });
});
</script>
</body></html>
''';
  }
}
