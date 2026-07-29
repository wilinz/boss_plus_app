import 'package:boss_plus_app/data/city_repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads embedded city list with correct codes + search', () async {
    final repo = CityRepo.instance;
    await repo.load();

    expect(repo.isLoaded, isTrue);
    expect(repo.all.length, greaterThan(300)); // 373 城
    expect(repo.hot.length, 14);

    City byName(String n) => repo.all.firstWhere((c) => c.name == n);
    // 城市码与官方一致(此前真机验证过的几个)。
    expect(byName('广州').code, 101280100);
    expect(byName('深圳').code, 101280600);
    expect(byName('北京').code, 101010100);
    expect(byName('上海').code, 101020100);

    // 搜索:中文 / 拼音 / 首字母。
    expect(repo.search('广州').any((c) => c.name == '广州'), isTrue);
    expect(repo.search('shenzhen').any((c) => c.name == '深圳'), isTrue);
    expect(repo.search('hangzhou').any((c) => c.name == '杭州'), isTrue);
    // 无匹配
    expect(repo.search('不存在的城市xyz'), isEmpty);
  });
}
