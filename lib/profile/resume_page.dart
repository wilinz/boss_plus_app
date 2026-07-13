import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/boss_provider.dart';
import 'online_resume_page.dart';
import 'resume_pdf_page.dart';

/// 我的简历:列表(查看/预览)+ 附件上传。数据来自 `Boss.resumeList()`(每条自带 previewUrl)。
class ResumeController extends GetxController {
  final loading = true.obs;
  final error = ''.obs;
  final uploading = false.obs;
  final resumes = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = '';
    try {
      final b = await BossProvider.instance.get();
      resumes.assignAll(await b.resumeList());
    } catch (e) {
      error.value = '$e';
    } finally {
      loading.value = false;
    }
  }

  /// 选文件并上传附件简历。返回提示文案。
  Future<String> pickAndUpload() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      withData: false,
    );
    final path = res?.files.single.path;
    if (path == null) return '已取消';
    uploading.value = true;
    try {
      final b = await BossProvider.instance.get();
      final resp = await b.uploadResumeFile(path);
      final code = resp['code'];
      if (code == 0) {
        await load();
        return '上传成功';
      }
      return (resp['message'] as String?) ?? '上传失败';
    } catch (e) {
      return '上传失败: $e';
    } finally {
      uploading.value = false;
    }
  }
}

class ResumePage extends StatelessWidget {
  const ResumePage({super.key});

  static const _teal = Color(0xFF12B7A0);
  static const _bg = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ResumeController());
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('我的简历'), actions: [
        IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: c.load),
      ]),
      floatingActionButton: Obx(() => FloatingActionButton.extended(
            backgroundColor: _teal,
            icon: c.uploading.value
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.upload_file, color: Colors.white),
            label: Text(c.uploading.value ? '上传中…' : '上传附件简历',
                style: const TextStyle(color: Colors.white)),
            onPressed: c.uploading.value
                ? null
                : () async {
                    final msg = await c.pickAndUpload();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                    }
                  },
          )),
      body: Obx(() {
        if (c.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.error.value.isNotEmpty && c.resumes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('加载失败: ${c.error.value}',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: c.load, child: const Text('重试')),
              ],
            ),
          );
        }
        if (c.resumes.isEmpty) {
          return const Center(
            child: Text('还没有简历,点右下角上传附件简历',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return RefreshIndicator(
          onRefresh: c.load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: c.resumes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _tile(context, c.resumes[i]),
          ),
        );
      }),
    );
  }

  /// previewUrl 实为 bosszp:// 深链(WebView 加载不了),真实 http 地址在其 `url` 参数里。
  /// 例:`bosszp://bosszhipin.app/openwith?type=selectResumePreviewUrl&url=<真实地址>&...`
  /// 内层地址常是裸 PDF 下载(preview4geek,application/pdf)—— Android WebView 不能内联
  /// 渲染,需包进官方 H5 查看器 `pdf-viewer-h5?url=<PDF>`(HAR 实测)。
  /// 供附件页复用:解析 previewUrl 深链为内层 http 地址。
  static String resolvePreviewUrl(String raw) => _resolvePreviewUrl(raw);

  static String _resolvePreviewUrl(String raw) {
    var url = raw;
    if (!url.startsWith('http')) {
      if (url.startsWith('bosszp://') || url.contains('openwith?')) {
        try {
          final inner = Uri.parse(url).queryParameters['url'];
          if (inner != null && inner.startsWith('http')) url = inner;
        } catch (_) {}
      }
    }
    return url.startsWith('http') ? url : '';
  }

  Widget _tile(BuildContext context, Map<String, dynamic> r) {
    // annexType==0 = 在线简历(原生结构化预览);!=0 = 附件简历(PDF 原生预览)。两个独立功能。
    final isOnline = (r['annexType'] as num?)?.toInt() == 0;
    final name = (r['customName'] as String?)?.trim();
    final suffix = (r['suffixName'] as String?) ?? '';
    final desc = (r['resumeDesc'] as String?) ??
        [r['resumeSizeDesc'], r['uploadTime']]
            .where((s) => s is String && s.isNotEmpty)
            .join(' · ');
    final previewUrl = _resolvePreviewUrl((r['previewUrl'] as String?) ?? '');
    final canPreview =
        isOnline || (r['canPreview'] == true && previewUrl.isNotEmpty);
    final title = (name != null && name.isNotEmpty)
        ? name
        : (isOnline ? '在线简历' : '附件简历.$suffix');
    void open() {
      if (isOnline) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const OnlineResumePage()));
      } else {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ResumePdfPage(title: title, url: previewUrl)));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(
            isOnline ? Icons.article_outlined : Icons.picture_as_pdf_outlined,
            color: _teal,
            size: 30),
        title: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: desc.isEmpty
            ? null
            : Text(desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
        trailing: canPreview
            ? const Icon(Icons.chevron_right, color: Colors.black26)
            : const Text('不可预览',
                style: TextStyle(fontSize: 12, color: Colors.black38)),
        onTap: canPreview ? open : null,
      ),
    );
  }
}

/// 附件简历(只读):列出 `resumeList` 里的 PDF 附件并原生预览(pdfx)。
/// 与「在线简历」并行的独立入口;不含上传(上传是官方 H5/web 流程)。
class AttachmentResumePage extends StatefulWidget {
  const AttachmentResumePage({super.key});

  @override
  State<AttachmentResumePage> createState() => _AttachmentResumePageState();
}

class _AttachmentResumePageState extends State<AttachmentResumePage> {
  static const _tag = 'attachment_resume';
  late final ResumeController c;

  static const _teal = Color(0xFF12B7A0);
  static const _bg = Color(0xFFF2F3F5);

  @override
  void initState() {
    super.initState();
    Get.delete<ResumeController>(tag: _tag);
    c = Get.put(ResumeController(), tag: _tag);
  }

  @override
  void dispose() {
    Get.delete<ResumeController>(tag: _tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: const Text('附件简历'), actions: [
        IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: c.load),
      ]),
      body: Obx(() {
        if (c.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.error.value.isNotEmpty && c.resumes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('加载失败: ${c.error.value}',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: c.load, child: const Text('重试')),
              ],
            ),
          );
        }
        if (c.resumes.isEmpty) {
          return const Center(
            child: Text('还没有附件简历',
                style: TextStyle(color: Colors.grey)),
          );
        }
        return RefreshIndicator(
          onRefresh: c.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: c.resumes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _tile(context, c.resumes[i]),
          ),
        );
      }),
    );
  }

  Widget _tile(BuildContext context, Map<String, dynamic> r) {
    final name = (r['customName'] as String?)?.trim();
    final suffix = (r['suffixName'] as String?) ?? 'pdf';
    final desc = (r['resumeDesc'] as String?) ??
        [r['resumeSizeDesc'], r['uploadTime']]
            .where((s) => s is String && s.isNotEmpty)
            .join(' · ');
    final url = ResumePage.resolvePreviewUrl((r['previewUrl'] as String?) ?? '');
    final canPreview = r['canPreview'] == true && url.isNotEmpty;
    final title = (name != null && name.isNotEmpty) ? name : '附件简历.$suffix';
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: const Icon(Icons.picture_as_pdf_outlined,
            color: _teal, size: 30),
        title: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: desc.isEmpty
            ? null
            : Text(desc,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
        trailing: canPreview
            ? const Icon(Icons.chevron_right, color: Colors.black26)
            : const Text('不可预览',
                style: TextStyle(fontSize: 12, color: Colors.black38)),
        onTap: canPreview
            ? () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ResumePdfPage(title: title, url: url)))
            : null,
      ),
    );
  }
}
