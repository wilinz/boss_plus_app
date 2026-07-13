import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:boss_plus/boss_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/boss_provider.dart';
import 'chat_page.dart';
import 'chat_store.dart';
import 'im_service.dart';

/// 一个会话联系人(boss)的展示信息,来自 `getBaseInfo` 的 ServerAddFriendBean。
class Contact {
  Contact({
    required this.friendId,
    required this.name,
    required this.avatar,
    required this.company,
    required this.jobName,
    required this.salaryDesc,
    required this.securityId,
    required this.friendSource,
    required this.datetime,
    this.lastMessage = '',
  });

  final int friendId;
  final String name;

  /// 联系人来源(chatHistory 必传,三类联系人值不同)。
  final int friendSource;

  /// 头像 URL。自定义照片走 tinyUrl,否则用 headImg 编号拼默认头像。
  final String avatar;
  final String company;
  final String jobName;
  final String salaryDesc;
  final String securityId;

  /// 最近互动时间(ms)。收到新消息时更新。
  int datetime;

  /// 最近一条消息预览(getBaseInfo 不含,由 chatHistory 补)。
  String lastMessage;

  /// 最近一条是不是我发的(→ 显示 [送达] 前缀)。
  bool lastMine = false;

  factory Contact.fromMap(Map<String, dynamic> m) {
    String s(dynamic v) => (v ?? '').toString();
    final tiny = s(m['tinyUrl']);
    final headImg = (m['headImg'] as num?)?.toInt() ?? 0;
    final avatar = tiny.isNotEmpty
        ? tiny
        : 'https://img.bosszhipin.com/boss/avatar/avatar_$headImg.png';
    return Contact(
      friendId: (m['friendId'] as num?)?.toInt() ?? 0,
      name: s(m['name']),
      avatar: avatar,
      company: s(m['company'] ?? m['brandName']),
      jobName: s(m['jobName'] ?? m['positionName']),
      salaryDesc: s(m['salaryDesc']),
      securityId: s(m['securityId']),
      friendSource: (m['friendSource'] as num?)?.toInt() ?? 0,
      datetime: (m['datetime'] as num?)?.toInt() ??
          (m['addTime'] as num?)?.toInt() ??
          0,
    );
  }

  /// 第一行右侧:公司 | 岗位。
  String get orgLine =>
      [if (company.isNotEmpty) company, if (jobName.isNotEmpty) jobName]
          .join(' | ');

  /// 时间简显(今天 HH:mm / 月-日)。
  String get timeText {
    if (datetime <= 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(datetime);
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.month}月${d.day}日';
  }

  /// 本地缓存序列化(已解析好的展示字段,与 getBaseInfo 原始 Map 不同)。
  Map<String, dynamic> toStore() => {
        'friendId': friendId,
        'name': name,
        'avatar': avatar,
        'company': company,
        'jobName': jobName,
        'salaryDesc': salaryDesc,
        'securityId': securityId,
        'friendSource': friendSource,
        'datetime': datetime,
        'lastMessage': lastMessage,
        'lastMine': lastMine,
      };

  factory Contact.fromStore(Map m) {
    String s(dynamic v) => (v ?? '').toString();
    final c = Contact(
      friendId: (m['friendId'] as num?)?.toInt() ?? 0,
      name: s(m['name']),
      avatar: s(m['avatar']),
      company: s(m['company']),
      jobName: s(m['jobName']),
      salaryDesc: s(m['salaryDesc']),
      securityId: s(m['securityId']),
      friendSource: (m['friendSource'] as num?)?.toInt() ?? 0,
      datetime: (m['datetime'] as num?)?.toInt() ?? 0,
      lastMessage: s(m['lastMessage']),
    );
    c.lastMine = m['lastMine'] == true;
    return c;
  }
}

/// 消息列表(会话列表)tab。两段式:getFriendIdListV1(id) → getBaseInfo(详情)。
class ContactListController extends GetxController {
  final loading = true.obs;
  final error = ''.obs;
  final contacts = <Contact>[].obs;

  // 分页:id 列表一次拿全,详情按页(每页 [_pageSize])懒加载,滚到底再拉。
  final hasMore = false.obs;
  final loadingMore = false.obs;
  static const _pageSize = 20;
  List<int> _zp = const [], _dz = const [], _peer = const [];
  int _zi = 0, _di = 0, _pi = 0; // 各桶已消费游标
  final _loadedIds = <int>{};
  dynamic _boss;

  StreamSubscription<ImMessage>? _sub;

  @override
  void onInit() {
    super.onInit();
    // 先上屏本地缓存的会话列表(秒开、离线可见),再 HTTP 刷新。
    final cached = ChatStore.instance.conversations;
    if (cached.isNotEmpty) {
      contacts.assignAll(cached.map(Contact.fromStore));
      loading.value = false;
    }
    load();
    // 实时:收到新消息就更新对应会话的预览+时间并置顶;新联系人则整体刷新。
    if (Get.isRegistered<ImService>()) {
      _sub = ImService.to.incoming.listen(_onMessage);
    }
  }

  /// 会话列表持久化到本地。
  void _persist() =>
      ChatStore.instance.saveConversations(contacts.map((c) => c.toStore()).toList());

  void _onMessage(ImMessage m) {
    if (m.text == null) return;
    final myUid = ImService.to.myUid;
    // 对方 = 消息里非我方的一端。
    final peer = m.fromUid == myUid ? m.toUid : m.fromUid;
    final idx = contacts.indexWhere((c) => c.friendId == peer);
    if (idx < 0) {
      // 新会话(如刚发起沟通),整体刷新。
      load();
      return;
    }
    final c = contacts[idx];
    c.lastMessage = m.text!;
    c.lastMine = m.fromUid == myUid;
    if (m.time > 0) c.datetime = m.time;
    // 置顶。
    contacts
      ..removeAt(idx)
      ..insert(0, c);
    contacts.refresh();
    _persist();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  /// 刷新:重取 id 列表并加载第一页。
  Future<void> load() async {
    loading.value = true;
    error.value = '';
    try {
      _boss = await BossProvider.instance.get();
      // 1) id 列表(三类,已按最近互动排序)。
      final ids = await _boss.contactFriendIds();
      _zp = ids.zp;
      _dz = ids.dz;
      _peer = ids.peer;
      _zi = _di = _pi = 0;
      _loadedIds.clear();
      contacts.clear();
      final any = _zp.isNotEmpty || _dz.isNotEmpty || _peer.isNotEmpty;
      hasMore.value = any;
      // 2) 第一页详情。
      if (any) await _fetchNextPage();
      loading.value = false;
      if (!any) _persist();
    } catch (e) {
      error.value = '加载会话失败: $e';
      loading.value = false;
    }
  }

  /// 滚到底触发:加载下一页。
  Future<void> loadMore() async {
    if (loadingMore.value || !hasMore.value || loading.value) return;
    loadingMore.value = true;
    try {
      await _fetchNextPage();
    } catch (_) {
    } finally {
      loadingMore.value = false;
    }
  }

  /// 取下一页 id(zp→dz→peer 顺序,每页 [_pageSize]),拉详情并追加。
  Future<void> _fetchNextPage() async {
    List<int> slice = const [];
    var bucket = -1;
    if (_zi < _zp.length) {
      final end = min(_zi + _pageSize, _zp.length);
      slice = _zp.sublist(_zi, end);
      _zi = end;
      bucket = 0;
    } else if (_di < _dz.length) {
      final end = min(_di + _pageSize, _dz.length);
      slice = _dz.sublist(_di, end);
      _di = end;
      bucket = 1;
    } else if (_pi < _peer.length) {
      final end = min(_pi + _pageSize, _peer.length);
      slice = _peer.sublist(_pi, end);
      _pi = end;
      bucket = 2;
    }
    if (slice.isEmpty) {
      hasMore.value = false;
      return;
    }
    final list = await _boss.contactBaseInfo(
      friendIds: bucket == 0 ? slice : const <int>[],
      dzFriendIds: bucket == 1 ? slice : const <int>[],
      peerFriendIds: bucket == 2 ? slice : const <int>[],
    );
    // 按请求的 id 顺序还原(getBaseInfo 返回未必有序),并去重。
    final byId = <int, Map<String, dynamic>>{};
    for (final m in list) {
      final id = (m['friendId'] as num?)?.toInt();
      if (id != null) byId[id] = m;
    }
    final cs = <Contact>[];
    for (final id in slice) {
      final m = byId[id];
      if (m != null && _loadedIds.add(id)) cs.add(Contact.fromMap(m));
    }
    contacts.addAll(cs);
    hasMore.value = _zi < _zp.length || _di < _dz.length || _pi < _peer.length;
    _persist();
    // 后台补最近消息预览(不阻塞)。
    _fillLastMessages(_boss, cs);
  }

  /// 每个联系人拉最新几条消息,取真正最新一条(任意类型)生成预览,填好后刷新列表。
  Future<void> _fillLastMessages(dynamic boss, List<Contact> cs) async {
    await Future.wait(cs.map((ct) async {
      try {
        final page = await boss.chatHistory(
          friendId: ct.friendId,
          friendSource: ct.friendSource,
          securityId: ct.securityId,
          count: 10,
        );
        final all = <ImMessage>[];
        for (final b64 in page.messages) {
          all.addAll(ChatProtocol.decode(base64.decode(b64)).messages);
        }
        if (all.isEmpty) return;
        all.sort((a, b) => a.time.compareTo(b.time));
        // 优先取最后一条有文本的(官方列表显示的是文字消息,非系统卡片);
        // 完全没文本才退回最新一条的类型摘要。
        ImMessage? lastText;
        for (final m in all) {
          if (m.text != null && m.text!.isNotEmpty) lastText = m;
        }
        final pick = lastText ?? all.last;
        ct.lastMessage = _preview(pick);
        ct.lastMine = pick.fromUid != ct.friendId;
        // 用这段历史算未读(比已读水位新的对方消息)。
        if (Get.isRegistered<ImService>()) {
          ImService.to.applyHistory(ct.friendId, all);
        }
      } catch (_) {}
    }));
    contacts.refresh();
    _persist();
  }

  /// 任意消息类型 → 预览文字。文本直接显示,其它给类型摘要。
  static String _preview(ImMessage m) {
    if (m.text != null && m.text!.isNotEmpty) return m.text!;
    return switch (m.contentType) {
      ContentType.image => '[图片]',
      ContentType.sound => '[语音]',
      ContentType.jobCard => '[职位]',
      ContentType.resume => '[简历]',
      _ => '[消息]',
    };
  }
}

class ContactListPage extends StatelessWidget {
  const ContactListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ContactListController());
    return Obx(() {
      if (c.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (c.error.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.error.value, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              FilledButton(onPressed: c.load, child: const Text('重试')),
            ],
          ),
        );
      }
      if (c.contacts.isEmpty) {
        return const Center(
            child: Text('暂无会话', style: TextStyle(color: Colors.grey)));
      }
      return RefreshIndicator(
        onRefresh: c.load,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            // 距底 300px 内触发下一页。
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
              c.loadMore();
            }
            return false;
          },
          child: ListView.separated(
            itemCount: c.contacts.length + (c.hasMore.value ? 1 : 0),
            separatorBuilder: (_, i) => const Divider(height: 1, indent: 76),
            itemBuilder: (_, i) {
              if (i >= c.contacts.length) {
                // 底部加载指示。
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              return _tile(context, c.contacts[i]);
            },
          ),
        ),
      );
    });
  }

  Widget _tile(BuildContext context, Contact ct) {
    final display = ct.name.isEmpty ? 'Boss #${ct.friendId}' : ct.name;
    const grey = TextStyle(fontSize: 13, color: Colors.grey);
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatPage(
          peerUid: ct.friendId,
          peerName: display,
          peerAvatar: ct.avatar,
          peerSubtitle: ct.company.isEmpty ? '招聘者' : '${ct.company} · 招聘者',
          friendSource: ct.friendSource,
          securityId: ct.securityId,
          jobCard: (ct.jobName.isEmpty && ct.company.isEmpty)
              ? null
              : ChatJobCard(
                  jobTitle: ct.jobName,
                  salary: ct.salaryDesc,
                  company: ct.company,
                  bossName: ct.name,
                ),
        ),
      )),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final n = Get.isRegistered<ImService>()
                  ? (ImService.to.unread[ct.friendId] ?? 0)
                  : 0;
              return Badge(
                isLabelVisible: n > 0,
                label: Text(n > 99 ? '99+' : '$n'),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage:
                      ct.avatar.isNotEmpty ? NetworkImage(ct.avatar) : null,
                  child: ct.avatar.isEmpty
                      ? Text(display.characters.take(1).join())
                      : null,
                ),
              );
            }),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 第一行:名字 + 公司|岗位 ... 薪资
                  Row(
                    children: [
                      Text(display,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(ct.orgLine,
                            style: grey,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (ct.salaryDesc.isNotEmpty)
                        Text(ct.salaryDesc,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF12B7A0))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 第二行:[送达] 消息预览 ... 时间
                  Row(
                    children: [
                      if (ct.lastMine && ct.lastMessage.isNotEmpty)
                        const Text('[送达] ', style: grey),
                      Expanded(
                        child: Text(
                          ct.lastMessage.isEmpty ? '点击进入会话' : ct.lastMessage,
                          style: grey,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ct.timeText.isNotEmpty)
                        Text(ct.timeText,
                            style:
                                const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
