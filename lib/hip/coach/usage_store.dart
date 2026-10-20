import 'package:ugk_coach/ugk_coach.dart' as uc;

import 'usage_file_stub.dart'
    if (dart.library.io) 'usage_file_io.dart'
    as device;

/// 累计调用次数与 token（进度 → 设置 →「AI 定制用量」）。
class CoachUsageTotals {
  const CoachUsageTotals({
    this.calls = 0,
    this.turns = 0,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.cachedTokens = 0,
  });
  final int calls;
  final int turns;
  final int promptTokens;
  final int completionTokens;
  final int cachedTokens;
  int get totalTokens => promptTokens + completionTokens;

  factory CoachUsageTotals.of(Iterable<uc.UsageRecord> records) {
    final s = uc.UsageSummary.of(records);
    return CoachUsageTotals(
      calls: s.calls,
      turns: s.turns,
      promptTokens: s.usage.promptTokens,
      completionTokens: s.usage.completionTokens,
      cachedTokens: s.usage.cachedTokens,
    );
  }
}

/// 一次模型调用一条记录：内存里汇总，同时追加到本地 JSONL
/// （应用支持目录下 `coach/usage.jsonl`；Web 只记内存）。
class CoachUsageStore implements uc.UsageSink {
  CoachUsageStore({
    uc.UsageSink? persist,
    Future<List<uc.UsageRecord>> Function()? readAll,
  }) : _persist = persist, // ignore: prefer_initializing_formals
       _readAll = readAll; // ignore: prefer_initializing_formals

  /// 设备上的 JSONL 记账（拿不到目录时退回只记内存）。
  factory CoachUsageStore.device() {
    final file = device.UsageFile();
    return CoachUsageStore(persist: file, readAll: file.readAll);
  }

  final uc.UsageSink? _persist;
  final Future<List<uc.UsageRecord>> Function()? _readAll;
  final List<uc.UsageRecord> _records = [];
  Future<void>? _loading;

  List<uc.UsageRecord> get records => List.unmodifiable(_records);
  CoachUsageTotals get totals => CoachUsageTotals.of(_records);

  /// 读入以前的记录（只读一次，失败当作没有）。
  Future<void> load() => _loading ??= () async {
    try {
      final old = await _readAll?.call() ?? const <uc.UsageRecord>[];
      _records.insertAll(0, old);
    } on Object {
      // 记账文件读不了不影响对话。
    }
  }();

  @override
  Future<void> record(uc.UsageRecord r) async {
    _records.add(r);
    try {
      await _persist?.record(r);
    } on Object {
      // 同上。
    }
  }
}
