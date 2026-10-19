// 练习库 UI strings, Chinese and English (docs/training-library-2026-10-19.md
// §双语). The app runs with the zh locale today; the English table is
// complete so the library follows the app once it ships English UI. Drill
// names and key points come from the action kits' display.{zh,en}.
import 'package:flutter/widgets.dart';

import '../../domain/hip_models.dart';

class LibText {
  const LibText(this.lang);
  final String lang;

  static const zh = LibText('zh');
  static const en = LibText('en');

  static LibText of(BuildContext context) =>
      Localizations.maybeLocaleOf(context)?.languageCode == 'en' ? en : zh;

  bool get isEn => lang == 'en';
  String _(String z, String e) => isEn ? e : z;

  // ── practice page ──
  String get practice => _('练习', 'Practice');
  String get segActions => _('动作', 'Moves');
  String get segRoutines => _('套路', 'Routines');
  String get segMine => _('我的', 'Mine');
  String get myHip => _('我的髋部', 'My hips');
  String get checkTitle => _('3 分半自测', '3½-min check-up');
  String get checkUntested =>
      _('6 个动作，找出髋部哪个方向最紧', '6 moves to find your tightest direction');
  String get checkStart => _('开始自测', 'Start');
  String get checkRetest => _('重测', 'Retest');
  String lastChecked(DateTime d) =>
      _('上次 ${d.month} 月 ${d.day} 日', 'Last ${d.month}/${d.day}');
  String levelName(int level) => switch (level) {
    3 => _('进阶', 'Advanced'),
    2 => _('基础', 'Basic'),
    _ => _('入门', 'Starter'),
  };
  String get checkBlocked => _('先问问医生再来', 'Ask a doctor first');

  // ── 动作大全 ──
  String get searchHint => _('搜动作，中文或英文都行', 'Search moves (中文 / English)');
  String get all => _('全部', 'All');
  String get filter => _('筛选', 'Filter');
  String filterN(int n) => n == 0 ? filter : '$filter $n';
  String actionsCount(int n) => _(
    '$n 个动作 · 点开看要点，单独练或加进训练组',
    '$n moves · open one to practise it or add it to a group',
  );
  String get noMatch => _('没有符合的动作', 'No moves match');
  String get clearFilters => _('清除筛选', 'Clear filters');
  String get advanced => _('进阶', 'Adv.');
  String get chair => _('椅子', 'Chair');
  String inGroup(String dose) => _('已在组里 · $dose', 'In group · $dose');

  String area(HipDirection d) => switch (d) {
    HipDirection.flexion => _('大腿后侧', 'Hamstrings'),
    HipDirection.extension => _('髋前侧', 'Hip front'),
    HipDirection.abduction => _('大腿内侧', 'Inner thigh'),
    HipDirection.adduction => _('髋外侧', 'Outer hip'),
    HipDirection.internalRotation => _('髋内旋', 'Internal rot.'),
    HipDirection.externalRotation => _('髋外旋', 'External rot.'),
  };
  String areaChip(HipDirection d) => switch (d) {
    HipDirection.internalRotation => _('内旋', 'Int. rot.'),
    HipDirection.externalRotation => _('外旋', 'Ext. rot.'),
    _ => area(d),
  };
  String method(HipMethod m) => switch (m) {
    HipMethod.relax => _('放松', 'Relax'),
    HipMethod.flexibility => _('柔韧', 'Mobility'),
    HipMethod.control => _('主动控制', 'Control'),
    HipMethod.strength => _('力量', 'Strength'),
  };
  String scene(HipScene s) => switch (s) {
    HipScene.chair => _('椅子可做', 'Chair OK'),
    HipScene.home => _('居家', 'At home'),
  };
  String get sceneTitle => _('在哪做', 'Where');
  String get methodTitle => _('怎么练', 'How');
  String get levelTitle => _('难度', 'Level');
  String get starter => _('入门', 'Starter');
  String get advancedLevel => _('进阶', 'Advanced');
  String get reset => _('重置', 'Reset');
  String showN(int n) => _('显示 $n 个动作', 'Show $n moves');

  // ── detail ──
  String get back => _('返回', 'Back');
  String get loopPlaying => _('循环播放', 'Looping');
  String get dose => _('剂量', 'Dose');
  String get bothSides => _('左右各做', 'Both sides');
  String about(String t) => _('约 $t', 'about $t');
  String repsLabel(bool sided) =>
      sided ? _('每侧次数', 'Reps each side') : _('次数', 'Reps');
  String secondsLabel(bool sided) =>
      sided ? _('每侧时长', 'Time each side') : _('时长', 'Time');
  String get setsLabel => _('组数', 'Sets');
  String repsValue(int v) => _('$v 次', '$v');
  String secondsValue(int v) => _('$v 秒', '${v}s');
  String setsValue(int v) => _('$v 组', '$v');
  String rangeHint(int base, int min, int max, {required bool seconds}) => _(
    '默认 $base · $min–$max${seconds ? ' 秒' : ''}',
    'default $base · $min–$max${seconds ? ' s' : ''}',
  );
  String get setsHint => _('1–3 组', '1–3 sets');
  String get less => _('减少', 'Less');
  String get more => _('增加', 'More');
  String get addToGroup => _('加入训练组', 'Add to group');
  String get startPractice => _('开始练', 'Start');
  String get askDoctorFirst => _('先问问医生再来', 'Ask a doctor first');
  String get relaxOnlyThisWeek => _('这周先只做放松', 'Relax-only this week');
  String get noticePain => _(
    '这个方向最近疼过，先做放松类更稳',
    'This area hurt recently – relax moves are safer first',
  );
  String get seeRelax => _('看放松', 'See relax moves');
  String get noticeAdvanced => _(
    '进阶动作。按你的自测等级，建议先做入门版',
    'Advanced move. For your check-up level, the easier version comes first',
  );
  String get noticeAdvancedNoAlt => _(
    '进阶动作。按你的自测等级，建议慢慢来、幅度小一点',
    'Advanced move. For your check-up level, go easy and keep the range small',
  );
  String seeDrill(String name) => _('看「$name」', 'See "$name"');
  String get noticeBlocked => _(
    '你在安全提示里选了「有」。动作可以先看，开始练之前请先问问医生或专业人士。',
    'You answered "yes" to a safety question. Browse freely, but ask a doctor or professional before you practise.',
  );
  String noticeLocked(String area) => _(
    '$area这周只做放松（最近两次跳过）。先做同方向的放松动作。',
    '$area is relax-only this week (skipped twice). Try a relax move there.',
  );
  String get singleNoStreak => _(
    '单练记入练习记录，不计连续天数',
    'Single practice is logged, not counted for your streak',
  );
  String get cautions => _('留意', 'Mind');

  // ── add to group ──
  String get addToWhich => _('加到哪个训练组', 'Add to which group');
  String get newGroup => _('新建训练组', 'New group');
  String addedTo(String name) => _('已加入「$name」', 'Added to "$name"');
  String get groupFull => _('已满 20 个', 'Full (20)');

  // ── routines ──
  String routinesCount(int n) => _(
    '$n 套编排好的套路，不受首页推荐限制，随便挑',
    '$n ready-made routines – pick any, not just the recommended one',
  );
  String get recommended => _('为你推荐', 'For you');
  String minutes(int m) => _('$m 分钟', '$m min');
  String movesCount(int n) => _('$n 个动作', '$n moves');
  String get dancerNote => _(
    '面向舞者，动作偏难；没解锁的进阶动作会自动换成入门版',
    'For dancers, harder; locked advanced moves become their easier versions',
  );
  String get routine => _('套路', 'Routine');
  String get statMinutes => _('分钟', 'min');
  String get statMoves => _('个动作', 'moves');
  String get statRest => _('秒休息', 's rest');
  String levelAdapted(int swapped, int dropped) => _(
    '按你的自测等级：$swapped 个进阶动作换成了入门版${dropped > 0 ? '，$dropped 个没有入门版的先不做' : ''}',
    'For your level: $swapped advanced moves became easier ones${dropped > 0 ? ', $dropped without one are left out' : ''}',
  );
  String lockedSkipped(String area, int n) =>
      _('$area这周只做放松，跳过 $n 个', '$area is relax-only this week – $n skipped');
  String easierFor(String name) =>
      _('入门版 · 代替「$name」', 'Easier · instead of "$name"');
  String get copyAsGroup => _('复制成我的训练组', 'Copy to my groups');
  String get start => _('开始', 'Start');
  String copiedName(String routine) => _('$routine（我的）', '$routine (mine)');

  // ── mine ──
  String get newGroupHint =>
      _('从动作大全挑动作，最多 20 个', 'Pick from the moves, up to 20');
  String myGroups(int n) => _('我的训练组 · $n', 'My groups · $n');
  String fromRoutine(String name) => _('改自套路「$name」', 'From routine "$name"');
  String delisted(int n) => _('$n 个动作已下架', '$n moves were removed');
  String get emptyTitle => _('还没有训练组', 'No groups yet');
  String get emptyBody => _(
    '挑几个喜欢的动作排成一组，或者从套路复制一份再改',
    'Line up moves you like, or copy a routine and adjust it',
  );
  String get copyFromRoutine => _('从套路复制', 'Copy a routine');
  String get allRelaxOnly => _(
    '这组动作这周都只能做放松，先换几个放松动作吧',
    'Every move here is relax-only this week – add some relax moves',
  );
  String get startAnyway => _('照样开始', 'Start anyway');
  String get cancel => _('取消', 'Cancel');

  // ── editor ──
  String get editGroup => _('编辑训练组', 'Edit group');
  String get name => _('名称', 'Name');
  String get restBetween => _('动作间休息', 'Rest between');
  String restValue(int v) => _('$v 秒', '${v}s');
  String stepsCount(int n) => _('动作 · $n/20', 'Moves · $n/20');
  String get reorderHint =>
      _('按住左侧拖动排序 · 左滑删除', 'Drag the handle to reorder · swipe left to delete');
  String get rowHint => _(
    '点一行改剂量；休息时会播报下一个动作和要点',
    'Tap a row to change its dose; rests announce the next move',
  );
  String get adjusted => _('已调整', 'adjusted');
  String get delete => _('删除', 'Delete');
  String get total => _('总时长', 'Total');
  String summary(int n, int rest) =>
      _('$n 个动作 · 休息 $rest 秒', '$n moves · ${rest}s rest');
  String get addMoves => _('＋ 添加动作', '+ Add moves');
  String get save => _('保存', 'Save');
  String get discardTitle => _('放弃修改？', 'Discard changes?');
  String get discard => _('放弃', 'Discard');
  String get keepEditing => _('继续编辑', 'Keep editing');
  String get deleteGroup => _('删除训练组', 'Delete group');
  String deleteGroupBody(String name) =>
      _('「$name」会被删除，不能恢复。', '"$name" will be deleted for good.');
  String get emptySteps => _('先添加动作', 'Add some moves first');
  String get relaxDot => _('这周只做放松，开始时会跳过', 'Relax-only this week, skipped');
  String get resetDose => _('恢复默认', 'Reset');
  String get done => _('完成', 'Done');

  // ── picker ──
  String get addMovesTitle => _('添加动作', 'Add moves');
  String addTo(String name) => _('加到「$name」', 'Add to "$name"');
  String picked(int n) => _('已选 $n 个', '$n picked');
  String willHave(int n) => _('组里会有 $n/20 个', 'Group: $n/20');
  String get clear => _('清空', 'Clear');
  String addN(int n) => _('加入 $n 个', 'Add $n');
  String get max20 => _('最多 20 个', 'Up to 20');

  // ── player / history ──
  String get oneMoreSet => _('再来一组', 'One more set');
  String get singleDone => _('练完了', 'Done');
  String get finish => _('完成', 'Finish');

  // ── home ──
  String get myGroupsHome => _('我的训练组', 'My groups');

  // ── durations ──
  String duration(int s) {
    final m = s ~/ 60, r = s % 60;
    if (isEn) {
      if (m == 0) return '$r s';
      return r == 0 ? '$m min' : '$m min $r s';
    }
    if (m == 0) return '$r 秒';
    return r == 0 ? '$m 分钟' : '$m 分 $r 秒';
  }
}

/// m:ss for step rows.
String clockText(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
