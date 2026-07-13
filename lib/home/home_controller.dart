import 'package:boss_plus/boss_plus.dart';
import 'package:get/get.dart';

import '../data/boss_provider.dart';

/// 首页:个人信息 + 推荐职位列表。
class HomeController extends GetxController {
  final loading = true.obs;
  final error = ''.obs;
  final geek = Rxn<GeekInfo>();
  final jobs = <JobCard>[].obs;
  final hasMore = false.obs;
  final loadingMore = false.obs;
  final lid = ''.obs;

  final filter = const JobFilter().obs;

  int _page = 1;
  Boss? _boss;

  Future<Boss> _client() async => _boss ??= await BossProvider.instance.get();

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  /// 应用新的筛选条件并重新拉取第一页。
  Future<void> applyFilter(JobFilter f) async {
    filter.value = f;
    await _reloadJobs();
  }

  Future<void> refreshAll() async {
    loading.value = true;
    error.value = '';
    try {
      final b = await _client();
      geek.value = await b.queryGeekBaseInfo();
      await _reloadJobs();
    } catch (e) {
      error.value = '加载失败: $e';
    } finally {
      loading.value = false;
    }
  }

  Future<void> _reloadJobs() async {
    error.value = '';
    _page = 1;
    jobs.clear();
    final expect = geek.value?.expect;
    if (expect == null || expect.encryptExpectId.isEmpty) {
      hasMore.value = false;
      error.value = '未设置求职期望,暂无推荐职位';
      return;
    }
    final b = await _client();
    // 「全国」等场景首页可能返回 0 条但 hasMore=true;向后翻页直到有数据(上限 5 页),
    // 避免首屏空白、只能靠滚动才拉到。
    final acc = <JobCard>[];
    var page = 0;
    var more = true;
    while (acc.isEmpty && more && page < 5) {
      page += 1;
      final pd =
          await b.fetchRecommendJobs(expect: expect, page: page, filter: filter.value);
      acc.addAll(pd.jobs);
      more = pd.hasMore;
      lid.value = pd.lid;
    }
    _page = page;
    jobs.assignAll(acc);
    hasMore.value = more;
  }

  Future<void> loadMore() async {
    if (loadingMore.value || !hasMore.value) return;
    final expect = geek.value?.expect;
    if (expect == null) return;
    loadingMore.value = true;
    try {
      final b = await _client();
      // 跳过空页:某页 0 条但仍 hasMore 时继续翻,直到有数据或到上限。
      var page = _page;
      var added = false;
      var more = hasMore.value;
      var tries = 0;
      while (!added && more && tries < 5) {
        page += 1;
        tries += 1;
        final pd = await b.fetchRecommendJobs(
            expect: expect, page: page, filter: filter.value);
        if (pd.jobs.isNotEmpty) {
          jobs.addAll(pd.jobs);
          added = true;
        }
        more = pd.hasMore;
      }
      _page = page;
      hasMore.value = more;
    } catch (_) {
      // 保持 _page 不变
    } finally {
      loadingMore.value = false;
    }
  }
}
