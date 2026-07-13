import 'dart:convert';

import 'package:dio/dio.dart';

/// 传给 AI 判定的单个职位(仅列表卡信息,省 token、免拉详情)。
typedef AiJobBrief = ({
  String title,
  String company,
  String salary,
  String labels,
});

/// 批量让 OpenAI 兼容接口判断每个职位是否匹配简历,返回 index→是否值得投递。
///
/// - [baseUrl] 形如 `https://api.openai.com/v1`(末尾 /chat/completions 自动补)
/// - 一次请求判定整批,只回紧凑 JSON,省 token。
/// - 缺失/解析失败的项默认按「匹配」处理(不因 AI 抖动误杀)。
Future<Map<int, bool>> aiJudgeJobs({
  required String baseUrl,
  required String apiKey,
  required String model,
  required String resume,
  required List<AiJobBrief> jobs,
}) async {
  if (jobs.isEmpty) return {};
  final jobsText = [
    for (var i = 0; i < jobs.length; i++)
      '$i. ${jobs[i].title} | ${jobs[i].company} | ${jobs[i].salary} | ${jobs[i].labels}',
  ].join('\n');

  const sys = '你是求职助手。依据求职者简历,判断每个职位是否值得该求职者投递'
      '(看职位方向/技能/经验/薪资是否硬性匹配,不匹配就排除)。';
  final user = '【简历】\n$resume\n\n【职位列表(序号. 职位|公司|薪资|标签)】\n$jobsText\n\n'
      '对每个职位判断是否匹配。只输出紧凑 JSON,不要任何解释或代码块:\n'
      '{"r":[{"i":序号,"m":true或false}]}  (m=是否值得投递)';

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
  ));
  final url = '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions';
  // 不带 temperature:推理模型(gpt-5-nano 等)只接受默认值,发 0 会 400;
  // 普通 chat 模型用默认温度对该分类任务也够稳。
  final resp = await dio.post(url, data: {
    'model': model,
    'messages': [
      {'role': 'system', 'content': sys},
      {'role': 'user', 'content': user},
    ],
  });

  final data = resp.data is String ? jsonDecode(resp.data as String) : resp.data;
  final content =
      (((data['choices'] as List).first)['message']['content'] ?? '').toString();
  final parsed = jsonDecode(_extractJson(content)) as Map<String, dynamic>;
  final out = <int, bool>{};
  for (final e in (parsed['r'] as List)) {
    final m = e as Map;
    out[(m['i'] as num).toInt()] = m['m'] == true;
  }
  return out;
}

/// 用 AI 把完整简历浓缩成一段用于岗位匹配的简洁求职画像。
Future<String> aiSummarizeResume({
  required String baseUrl,
  required String apiKey,
  required String model,
  required String fullResume,
}) async {
  const sys = '你是求职助手。把求职者的完整简历浓缩成一段用于岗位匹配的简洁画像:'
      '突出技能栈、经验年限、擅长方向、目标岗位与薪资期望,去掉客套与冗余,200 字内,'
      '直接输出画像文本,不要标题或解释。';
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
  ));
  final url = '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/chat/completions';
  final resp = await dio.post(url, data: {
    'model': model,
    'messages': [
      {'role': 'system', 'content': sys},
      {'role': 'user', 'content': fullResume},
    ],
  });
  final data = resp.data is String ? jsonDecode(resp.data as String) : resp.data;
  return (((data['choices'] as List).first)['message']['content'] ?? '')
      .toString()
      .trim();
}

/// 从可能含代码块/前后缀的文本里抠出第一个 JSON 对象。
String _extractJson(String s) {
  final start = s.indexOf('{');
  final end = s.lastIndexOf('}');
  return (start >= 0 && end > start) ? s.substring(start, end + 1) : s;
}
