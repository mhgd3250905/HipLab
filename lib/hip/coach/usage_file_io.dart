import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:ugk_coach/ugk_coach.dart' as uc;
import 'package:ugk_coach/ugk_coach_io.dart' as uc_io;

/// 原生端：`<应用支持目录>/coach/usage.jsonl`，一行一次模型调用。
class UsageFile implements uc.UsageSink {
  Future<uc_io.JsonlUsageSink>? _sink;

  Future<uc_io.JsonlUsageSink> _open() => _sink ??= () async {
    final dir = await getApplicationSupportDirectory();
    return uc_io.JsonlUsageSink(File('${dir.path}/coach/usage.jsonl'));
  }();

  @override
  Future<void> record(uc.UsageRecord r) async => (await _open()).record(r);

  Future<List<uc.UsageRecord>> readAll() async => (await _open()).readAll();
}
