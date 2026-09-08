import 'dart:async';

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

  // 会话列表现在由消息流(ImService.conversations)派生,不再分页拉 chatHistory。
  // 保留 hasMore/loadMore 仅为兼容视图(始终 false)。
  final hasMore = false.obs;
  final loadingMore = false.obs;
  static const _pageSize = 20;

  dynamic _boss;
  // peer -> 名片(getBaseInfo 展示字段),缓存并持久化。
  final _cards = <int, Map<String, dynamic>>{};
  // peer -> friendSource 桶(0=zp,1=dz,2=peer),getBaseInfo 分桶用。
  final _bucket = <int, int>{};
  final _worker = <int>{}; // 正在拉名片的 peer,去重

  Worker? _convWorker;
  Worker? _unreadWorker;

  ImService? get _im =>
      Get.isRegistered<ImService>() ? ImService.to : null;

  @override
  void onInit() {
    super.onInit();
    // 载入名片缓存,先用「缓存名片 + 会话流」上屏(秒开)。
    for (final e in ChatStore.instance.cards.entries) {
      _cards[e.key] = e.value;
      final fs = (e.value['friendSource'] as num?)?.toInt();
      if (fs != null) _bucket[e.key] = fs;
    }
    _rebuild();
    loading.value = contacts.isEmpty;
    // 会话表/未读变化即重建列表(实时刷新的正解:数据在 ImService,UI 只投影)。
    final im = _im;
    if (im != null) {
      _convWorker = ever(im.conversations, (_) => _rebuild());
      _unreadWorker = ever(im.unread, (_) => contacts.refresh());
    }
    load();
  }

  @override
  void onClose() {
    _convWorker?.dispose();
    _unreadWorker?.dispose();
    super.onClose();
  }

  /// 刷新:拉 friendId 分桶(确定会话全集 + 桶),补名片,重建列表。
  /// 会话的最后一条/时间/未读来自消息流(ImService),同步在后台进行。
  Future<void> load() async {
    error.value = '';
    try {
      _boss = await BossProvider.instance.get();
      final ids = await _boss.contactFriendIds();
      _bucket.clear();
      for (final id in ids.zp) {
        _bucket[id] = 0;
      }
      for (final id in ids.dz) {
        _bucket[id] = 1;
      }
      for (final id in ids.peer) {
        _bucket[id] = 2;
      }
      _rebuild();
      loading.value = false;
      // 后台补名片(仅缺失的),完成后重建。
      final need = _bucket.keys.where((p) => !_cards.containsKey(p)).toList();
      unawaited(_fetchCards(need));
      // 后台兜底最后一条:MQTT 存量补推(/message/pull)冷启常不来,用 HTTP 单聊历史补。
      unawaited(_im?.backfillLastMessages(Map.of(_bucket)) ?? Future.value());
    } catch (e) {
      error.value = contacts.isEmpty ? '加载会话失败: $e' : '';
      loading.value = false;
    }
  }

  Future<void> loadMore() async {}

  /// 会话全集 = friendId 分桶 ∪ 消息流里出现过的 peer。据此 + 名片 + 会话元数据组装并排序。
  void _rebuild() {
    final im = _im;
    final convs = im?.conversations ?? <int, ImConversation>{}.obs;
    final peers = <int>{..._bucket.keys, ...convs.keys};
    final list = <Contact>[];
    for (final peer in peers) {
      if (peer <= 0) continue;
      final card = _cards[peer];
      final conv = convs[peer];
      final c = Contact(
        friendId: peer,
        name: (card?['name'] as String?)?.isNotEmpty == true
            ? card!['name'] as String
            : (conv?.peerName.isNotEmpty == true ? conv!.peerName : '对方'),
        avatar: (card?['avatar'] as String?) ?? '',
        company: (card?['company'] as String?) ?? '',
        jobName: (card?['jobName'] as String?) ?? '',
        salaryDesc: (card?['salaryDesc'] as String?) ?? '',
        securityId: (card?['securityId'] as String?) ?? '',
        friendSource: _bucket[peer] ?? 0,
        datetime: conv?.lastTime ??
            (card?['datetime'] as num?)?.toInt() ??
            0,
      );
      c.lastMessage = conv?.lastText ?? '';
      c.lastMine = conv?.lastMine ?? false;
      list.add(c);
    }
    list.sort((a, b) => b.datetime.compareTo(a.datetime));
    contacts.assignAll(list);
  }

  /// 批量拉名片(按桶分组,每批 [_pageSize]),写缓存并持久化,完成后重建。
  Future<void> _fetchCards(List<int> peers) async {
    final todo = peers.where((p) => _worker.add(p)).toList();
    if (todo.isEmpty || _boss == null) return;
    try {
      // 按桶分组。
      final byBucket = <int, List<int>>{0: [], 1: [], 2: []};
      for (final p in todo) {
        (byBucket[_bucket[p] ?? 2] ??= []).add(p);
      }
      for (final entry in byBucket.entries) {
        final bucket = entry.key;
        final slice = entry.value;
        for (var i = 0; i < slice.length; i += _pageSize) {
          final part = slice.sublist(
              i, (i + _pageSize).clamp(0, slice.length));
          final infos = await _boss.contactBaseInfo(
            friendIds: bucket == 0 ? part : const <int>[],
            dzFriendIds: bucket == 1 ? part : const <int>[],
            peerFriendIds: bucket == 2 ? part : const <int>[],
          );
          for (final m in infos) {
            final id = (m['friendId'] as num?)?.toInt();
            if (id == null) continue;
            _cards[id] = _cardOf(m, bucket);
          }
          _rebuild();
        }
      }
      await ChatStore.instance.saveCards(_cards);
    } catch (_) {
    } finally {
      _worker.removeAll(todo);
    }
  }

  /// getBaseInfo 原始 Map → 精简名片(展示字段)。
  static Map<String, dynamic> _cardOf(Map<String, dynamic> m, int bucket) {
    String s(dynamic v) => (v ?? '').toString();
    final tiny = s(m['tinyUrl']);
    final headImg = (m['headImg'] as num?)?.toInt() ?? 0;
    return {
      'name': s(m['name']),
      'avatar': tiny.isNotEmpty
          ? tiny
          : 'https://img.bosszhipin.com/boss/avatar/avatar_$headImg.png',
      'company': s(m['company'] ?? m['brandName']),
      'jobName': s(m['jobName'] ?? m['positionName']),
      'salaryDesc': s(m['salaryDesc']),
      'securityId': s(m['securityId']),
      'friendSource': bucket,
      'datetime': (m['datetime'] as num?)?.toInt() ??
          (m['addTime'] as num?)?.toInt() ??
          0,
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
