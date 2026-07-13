import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../data/boss_provider.dart';

/// 简历 PDF 原生预览:用我们的 dio(带 t2 认证)下载 PDF 字节 → pdfx 原生渲染。
/// 不经 WebView —— 官方也是原生。previewUrl 已在上层从 bosszp 深链解出内层 http 地址。
class ResumePdfPage extends StatefulWidget {
  const ResumePdfPage({super.key, required this.title, required this.url});

  final String title;
  final String url;

  @override
  State<ResumePdfPage> createState() => _ResumePdfPageState();
}

class _ResumePdfPageState extends State<ResumePdfPage> {
  PdfControllerPinch? _controller;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final boss = await BossProvider.instance.get();
      final bytes = await boss.downloadBytes(widget.url);
      if (bytes.isEmpty) throw '空文件';
      if (!mounted) return;
      setState(() {
        _controller = PdfControllerPinch(
          document: PdfDocument.openData(Uint8List.fromList(bytes)),
        );
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _error.isNotEmpty
          ? Center(
              child: Text('打开失败: $_error',
                  style: const TextStyle(color: Colors.grey)))
          : _controller == null
              ? const Center(child: CircularProgressIndicator())
              : PdfViewPinch(controller: _controller!),
    );
  }
}
