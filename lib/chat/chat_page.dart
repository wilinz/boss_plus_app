import 'dart:async';

import 'package:boss_plus/boss_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/boss_provider.dart';
import '../home/job_detail_page.dart';
import 'chat_controller.dart';
import 'im_service.dart';

/// 会话页顶部「职位卡片」数据(官方那张「由你发起的沟通」白卡)。
/// 打招呼入口用 JobDetail 填满,消息列表入口用 Contact 填部分。
class ChatJobCard {
  const ChatJobCard({
    this.jobTitle = '',
    this.salary = '',
    this.company = '',
    this.stage = '',
    this.location = '',
    this.experience = '',
    this.degree = '',
    this.bossName = '',
    this.bossTitle = '',
    this.bossAvatar = '',
  });

  final String jobTitle;
  final String salary;
  final String company;
  final String stage;
  final String location;
  final String experience;
  final String degree;
  final String bossName;
  final String bossTitle;
  final String bossAvatar;

  bool get isEmpty => jobTitle.isEmpty && company.isEmpty && salary.isEmpty;
}

/// 单会话聊天页:对齐官方 BOSS 聊天页样式(灰底 + 职位卡 + 头像气泡 + 送达 + 时间分隔 + 快捷输入栏)。
/// 两个入口(职位详情「发起沟通」、消息列表)共用。
class ChatPage extends StatelessWidget {
  const ChatPage({
    super.key,
    required this.peerUid,
    required this.peerName,
    this.peerSubtitle = '招聘者',
    this.peerAvatar = '',
    this.jobCard,
    this.friendSource = 0,
    this.securityId = '',
  });

  final int peerUid;
  final String peerName;

  /// 顶栏副标题(官方 = 公司·招聘者)。暂无公司时退化为「招聘者」。
  final String peerSubtitle;

  /// 对方头像 URL(消息列表 Contact.avatar / 打招呼 relation)。空则名字首字占位。
  final String peerAvatar;

  /// 顶部职位卡片(可空;无则不显示)。
  final ChatJobCard? jobCard;
  final int friendSource;
  final String securityId;

  static const _teal = Color(0xFF12B7A0);
  static const _bg = Color(0xFFF2F3F5);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(
      ChatController(
        peerUid: peerUid,
        peerName: peerName,
        friendSource: friendSource,
        securityId: securityId,
      ),
      tag: 'chat_$peerUid',
    );
    final input = TextEditingController();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(peerName,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
            if (peerSubtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(peerSubtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black45)),
              ),
          ],
        ),
        centerTitle: true,
        actions: const [
          Icon(Icons.more_horiz, color: Colors.black54),
          SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Obx(() => c.connecting.value
              ? const LinearProgressIndicator(minHeight: 2)
              : const SizedBox(height: 2)),
        ),
      ),
      body: Column(
        children: [
          _quickActions(context, c),
          Obx(() {
            if (c.error.value.isEmpty) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(8),
              child: Text(c.error.value,
                  style: TextStyle(color: Colors.orange.shade900)),
            );
          }),
          Expanded(
            child: Obx(() {
              final msgs = c.messages;
              if (msgs.isEmpty) {
                return Center(
                  child: Text(
                    c.connecting.value ? '加载中…' : '暂无消息',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }
              // 职位卡优先用消息自带的(官方同源);历史里没有这条卡消息时,
              // 才退化用外部穿进来的 jobCard(JobDetail/Contact)。
              final hasCardMsg = msgs.any((m) => m.jobCard != null);
              final lead = <Widget>[_timeHeader(msgs.first.time)];
              if (!hasCardMsg && jobCard != null && !jobCard!.isEmpty) {
                lead.add(_jobCard(jobCard!, msgs.first.time));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                itemCount: lead.length + msgs.length,
                itemBuilder: (ctx, i) {
                  if (i < lead.length) return lead[i];
                  final m = msgs[i - lead.length];
                  return _row(ctx, m, c.isMine(m));
                },
              );
            }),
          ),
          _inputBar(context, c, input),
        ],
      ),
    );
  }

  // 顶栏下的快捷操作行(对齐官方:换电话/换微信/发简历/不感兴趣)。
  // 换电话/换微信/发简历 = 同一端点 POST /api/zpchat/exchange/blueCollarRequest,
  // exchangeType 1/2/3(逆向 chat.e.requestExchangeWxPhone + MockMessageBean)。会向招聘方
  // 发起交换请求 → 先弹确认框再发。不感兴趣走 userMark/add(参数复杂,暂留提示)。
  Widget _quickActions(BuildContext ctx, ChatController c) {
    Widget item(IconData icon, String label, VoidCallback onTap,
            {Color? color}) =>
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Icon(icon, size: 24, color: color ?? Colors.black45),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, color: color ?? Colors.black54)),
                ],
              ),
            ),
          ),
        );
    return Container(
      color: _bg,
      child: Row(
        children: [
          item(Icons.phone_outlined, '换电话',
              () => _exchange(ctx, c, Boss.exchangePhone, '换电话')),
          item(Icons.wechat_outlined, '换微信',
              () => _exchange(ctx, c, Boss.exchangeWechat, '换微信')),
          item(Icons.description_outlined, '发简历',
              () => _exchange(ctx, c, Boss.exchangeResume, '发简历')),
          item(Icons.cancel_outlined, '不感兴趣', () {
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                content: Text('「不感兴趣」功能开发中'),
                duration: Duration(seconds: 1)));
          }),
        ],
      ),
    );
  }

  // 交换动作:确认 → 调真实接口 → 提示结果。
  Future<void> _exchange(BuildContext ctx, ChatController c, String type,
      String label) async {
    if (securityId.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('缺少会话凭证,无法发起')));
      return;
    }
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: Text('$label申请'),
        content: Text('确定向对方发起「$label」请求吗?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: const Text('确定')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final boss = await BossProvider.instance.get();
      final resp = await boss.exchangeContact(
        securityId: securityId,
        type: type,
        mid: c.latestMsgId,
      );
      final code = resp['code'];
      final msg = (resp['message'] as String?) ??
          (code == 0 ? '已发起$label请求' : '发起失败');
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
      // 成功后刷新会话(交换/发简历消息不经 MQTT 推,靠重拉历史同步 —— 对齐官方 r2())。
      if (code == 0) unawaited(c.reloadHistory());
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx)
            .showSnackBar(SnackBar(content: Text('$label失败: $e')));
      }
    }
  }

  // 系统/交换类提示(居中灰字,如「你已发起换电话请求,等待对方回复」)。
  Widget _systemNotice(String text) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ),
      );

  // 顶部时间分隔:「以下是聊天记录」+ 时间。
  Widget _timeHeader(int firstMs) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          children: [
            const Text('以下是聊天记录',
                style: TextStyle(fontSize: 12, color: Colors.black38)),
            const SizedBox(height: 6),
            Text(_fmtTime(firstMs),
                style: const TextStyle(fontSize: 12, color: Colors.black38)),
          ],
        ),
      );

  // 顶部职位卡片(对齐官方「由你发起的沟通」白卡)。
  Widget _jobCard(ChatJobCard j, int startedMs) {
    final tags = [j.location, j.experience, j.degree]
        .where((s) => s.isNotEmpty)
        .toList();
    final compLine = [j.company, j.stage].where((s) => s.isNotEmpty).join(' ');
    final bossLine =
        [j.bossName, j.bossTitle].where((s) => s.isNotEmpty).join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  j.jobTitle.isEmpty ? '职位' : j.jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
              ),
              if (j.salary.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(j.salary,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _teal)),
              ],
            ],
          ),
          if (compLine.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(compLine,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map(_tag).toList(),
            ),
          ],
          if (bossLine.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _avatar(j.bossName.isEmpty ? peerName : j.bossName,
                    url: j.bossAvatar),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(bossLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black54)),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Text('${_fmtTime(startedMs)} 由你发起的沟通',
              style: const TextStyle(fontSize: 12, color: Colors.black38)),
        ],
      ),
    );
  }

  Widget _tag(String s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(s,
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
      );

  // 职位卡片(数据来自消息 protobuf body.f10,与官方同源)。
  Widget _jobCardFromMsg(MsgJobCard j, int ms) {
    final tags = [j.location, j.experience, j.degree]
        .where((s) => s.isNotEmpty)
        .toList();
    final bossLine =
        [j.bossName, j.bossTitle].where((s) => s.isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(j.title.isEmpty ? '职位' : j.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87)),
                    ),
                    if (j.tag.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F3F5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(j.tag,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black45)),
                      ),
                    ],
                  ],
                ),
              ),
              if (j.salary.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(j.salary,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _teal)),
              ],
            ],
          ),
          if (j.position.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(j.position,
                style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: tags.map(_tag).toList()),
          ],
          if (bossLine.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _avatar(j.bossName.isEmpty ? peerName : j.bossName,
                    url: j.bossAvatar),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(bossLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, color: Colors.black54)),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Text(j.footer.isNotEmpty ? j.footer : '${_fmtTime(ms)} 由你发起的沟通',
              style: const TextStyle(fontSize: 12, color: Colors.black38)),
        ],
      ),
    );
  }

  // 一条消息行:头像 + 气泡(+ 送达)。对方在左、我在右。
  Widget _row(BuildContext ctx, ImMessage m, bool mine) {
    // 职位卡消息 → 渲染官方那张卡(数据来自消息本身);点击进职位详情。
    if (m.jobCard != null) {
      final card = m.jobCard!;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: card.securityId.isEmpty
              ? null
              : () => Navigator.of(ctx).push(MaterialPageRoute(
                    builder: (_) => JobDetailPage(
                      securityId: card.securityId,
                      lid: '',
                      title: card.title.isEmpty ? '职位详情' : card.title,
                    ),
                  )),
          child: _jobCardFromMsg(card, m.time),
        ),
      );
    }
    final isText = m.isText;

    // 非文本消息(交换/系统类):有 pushText 就居中显示那段文案(官方交换提示样式);
    // 否则退化为类型标签占位。
    if (!isText) {
      final notice = m.pushText;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: (notice != null && notice.isNotEmpty)
            ? _systemNotice(notice)
            : _systemCard(_typeLabel(m.contentType)),
      );
    }

    final bubble = _textBubble(m.text ?? '', mine);

    final avatar = mine
        ? _avatar(ImService.to.myName, url: ImService.to.myAvatar)
        : _avatar(peerName, url: peerAvatar);
    final children = mine
        ? [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('送达',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ),
            const SizedBox(width: 6),
            Flexible(child: bubble),
            const SizedBox(width: 8),
            avatar,
          ]
        : [
            avatar,
            const SizedBox(width: 8),
            Flexible(child: bubble),
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _avatar(String name, {String url = ''}) {
    final ch = name.isEmpty ? '?' : name.characters.first;
    final fallback = Text(ch,
        style: const TextStyle(
            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500));
    if (url.isEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFFCED4DA),
        child: fallback,
      );
    }
    // 有 URL:加载网络头像;加载中/失败退化为名字首字。
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFCED4DA),
      child: ClipOval(
        child: Image.network(
          url,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => Center(child: fallback),
          loadingBuilder: (_, child, prog) =>
              prog == null ? child : Center(child: fallback),
        ),
      ),
    );
  }

  Widget _textBubble(String text, bool mine) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: mine ? _teal : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: TextStyle(
                color: mine ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.35)),
      );

  // 非文本消息(职位卡片 / 竞争 PK 等)暂以简卡占位(字段未解码,后续可补真卡)。
  Widget _systemCard(String label) => Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      );

  String _typeLabel(int t) => switch (t) {
        ContentType.image => '[图片]',
        ContentType.sound => '[语音]',
        ContentType.jobCard => '职位卡片',
        ContentType.resume => '[简历]',
        _ => '系统消息',
      };

  static String _fmtTime(int ms) {
    if (ms <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}';
  }

  Widget _inputBar(
      BuildContext context, ChatController c, TextEditingController input) {
    void submit() {
      c.send(input.text);
      input.clear();
    }

    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 官方左侧「常」用语按钮
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                    color: _teal, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Text('常',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    hintText: '介绍自己回复率更高哦~',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF2F3F5),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.sentiment_satisfied_alt_outlined,
                  color: Colors.grey.shade500, size: 26),
              const SizedBox(width: 8),
              // 有文字时显示发送、否则显示 +(简化:始终可发送)
              GestureDetector(
                onTap: submit,
                child: Icon(Icons.add_circle_outline,
                    color: Colors.grey.shade500, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
