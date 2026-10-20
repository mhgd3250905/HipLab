import 'package:ugk_coach/ugk_coach.dart' as uc;

/// Web：没有文件系统，记录只留在内存。
class UsageFile implements uc.UsageSink {
  @override
  Future<void> record(uc.UsageRecord r) async {}
  Future<List<uc.UsageRecord>> readAll() async => const [];
}
