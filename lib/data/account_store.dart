import 'package:boss_plus/boss_plus.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart'
    show getApplicationDocumentsDirectory;
import 'package:path/path.dart' as p;

/// 一个已登录过的账号(以登录手机号为主键 + 缓存的昵称/头像,用于账号列表展示)。
class Account {
  const Account({required this.mobile, this.name = '', this.avatar = ''});

  final String mobile;
  final String name;
  final String avatar;

  Account copyWith({String? name, String? avatar}) => Account(
        mobile: mobile,
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
      );

  Map<String, dynamic> toJson() =>
      {'mobile': mobile, 'name': name, 'avatar': avatar};

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        mobile: j['mobile'] as String,
        name: j['name'] as String? ?? '',
        avatar: j['avatar'] as String? ?? '',
      );
}

/// 账号注册表:记录用过的手机号 + 昵称/头像,供多账号列表页展示与切换。
///
/// 登录成功时 [add],个人资料拉到后 [updateProfile] 补昵称/头像。存盘
/// `boss_accounts.json`。实际的设备指纹/会话仍分桶在 [DeviceConfigStore] /
/// [BossProvider](均以手机号为 key)。
class AccountStore {
  AccountStore._();
  static final AccountStore instance = AccountStore._();

  static const _file = 'boss_accounts.json';

  /// 响应式账号列表(供 Obx 直接绑定)。
  final accounts = <Account>[].obs;
  bool _loaded = false;
  String? _dirPath;

  Future<String> get _dir async =>
      _dirPath ??= (await getApplicationDocumentsDirectory()).path;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final saved = await FileSessionJar(p.join(await _dir, _file)).load();
    final list = (saved?['accounts'] as List?) ?? const [];
    accounts.assignAll(list
        .map((e) => Account.fromJson((e as Map).cast<String, dynamic>())));
  }

  Future<void> _flush() async => FileSessionJar(p.join(await _dir, _file))
      .save({'accounts': accounts.map((a) => a.toJson()).toList()});

  /// 注册一个手机号(已存在则忽略)。
  Future<void> add(String mobile) async {
    await load();
    if (mobile.isEmpty || accounts.any((a) => a.mobile == mobile)) return;
    accounts.add(Account(mobile: mobile));
    await _flush();
  }

  /// 补/更新某手机号的昵称、头像(个人资料加载后调用)。
  Future<void> updateProfile(String? mobile, {String? name, String? avatar}) async {
    if (mobile == null || mobile.isEmpty) return;
    await load();
    final i = accounts.indexWhere((a) => a.mobile == mobile);
    if (i < 0) {
      accounts.add(Account(mobile: mobile, name: name ?? '', avatar: avatar ?? ''));
    } else {
      final cur = accounts[i];
      final next = cur.copyWith(name: name, avatar: avatar);
      if (next.name == cur.name && next.avatar == cur.avatar) return;
      accounts[i] = next;
    }
    await _flush();
  }

  Future<void> remove(String mobile) async {
    await load();
    final before = accounts.length;
    accounts.removeWhere((a) => a.mobile == mobile);
    if (accounts.length != before) await _flush();
  }
}
