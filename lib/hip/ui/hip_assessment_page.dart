import 'dart:async';

import 'package:clock/clock.dart';
import '../../core/platform/screen_awake.dart';
import 'package:flutter/material.dart';

import '../control/hip_store.dart';
import '../domain/hip_assessment.dart';
import '../domain/hip_models.dart';
import '../domain/hip_session.dart';
import '../voice/hip_voice.dart';
import '../voice/session_script.dart';
import '../voice/voice_queue.dart';
import 'hip_icons.dart';
import 'hip_theme.dart';
import 'hip_widgets.dart';

/// Subject framing of each item's comparison stills (fractions of the
/// 540×540 renders, measured from the middle "一般" still) so thumbnails and
/// option cards show every pose at the same size (#2).
const hipAssessmentFocus = <String, Rect>{
  'butterfly': Rect.fromLTRB(.30, .24, .70, .82),
  'ninety_ninety': Rect.fromLTRB(.18, .18, .78, .88),
  'thomas': Rect.fromLTRB(.11, .39, .89, .75),
  'supine_cross': Rect.fromLTRB(.26, .16, .74, .90),
  'seated_fold': Rect.fromLTRB(.24, .38, .76, .80),
  'deep_squat': Rect.fromLTRB(.23, .17, .76, .86),
};

Rect _focusOf(AssessmentItem item) =>
    hipAssessmentFocus[item.id] ?? const Rect.fromLTRB(.15, .15, .85, .85);

String _measureLine(AssessmentItem item) {
  final parts = <String>[
    if (item.area.isNotEmpty) '看${item.area}',
    '${item.seconds} 秒',
    if (item.sided) '左右各一次',
  ];
  return parts.join(' · ');
}

/// The 自测 tab: what the check is, the six moves, one button (#2).
class HipAssessmentIntro extends StatelessWidget {
  const HipAssessmentIntro({
    super.key,
    required this.store,
    required this.onStart,
  });
  final HipStore store;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final items = store.content.rules.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: [
              const Text(
                '开胯体检',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '6 个动作 · 约 3 分 30 秒 · 找出髋部哪个方向最紧',
                style: TextStyle(color: HipColors.muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              for (final (i, item) in items.indexed) ...[
                if (i > 0) const SizedBox(height: 8),
                _row(item),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  HipIcon(HipGlyph.radar, size: 18, color: HipColors.jade),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '做完得到：六方向雷达图 + 为你推荐的训练路线',
                      style: TextStyle(fontSize: 13, color: HipColors.muted),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: HipPrimaryButton(
            key: const ValueKey('assessment-start'),
            label: store.blocked ? '先问问医生再来' : '开始自测',
            icon: HipGlyph.play,
            onPressed: store.blocked ? null : onStart,
          ),
        ),
      ],
    );
  }

  Widget _row(AssessmentItem item) {
    final still = item.options.length > 1 ? item.options[1].image : null;
    // One card edge only; the thumbnail is a clean rounded crop concentric
    // with the card (20 − 7 = 13), no frame of its own (round 2 #3).
    return HipPanel(
      key: ValueKey('intro-item-${item.id}'),
      padding: const EdgeInsets.all(7),
      radius: 20,
      child: Row(
        children: [
          HipThumb(
            size: 58,
            radius: 13,
            child: still == null
                ? const HipPendingArt()
                : HipFocusImage(asset: still, focus: _focusOf(item)),
          ),
          const SizedBox(width: 12),
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: HipColors.jade.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${item.order}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: HipColors.jade,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _measureLine(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: HipColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class HipAssessmentPage extends StatefulWidget {
  const HipAssessmentPage({
    super.key,
    required this.store,
    required this.onStartPlan,
  });
  final HipStore store;
  final Future<void> Function(TrainingPlan plan) onStartPlan;
  @override
  State<HipAssessmentPage> createState() => _HipAssessmentPageState();
}

class _HipAssessmentPageState extends State<HipAssessmentPage>
    with SingleTickerProviderStateMixin {
  final _answers = <String, ItemAnswer>{};
  int _index = 0;
  HipSide? _side;
  SideAnswer? _leftAnswer;
  int? _choice;
  String? _follow;
  AssessmentResult? _result;
  late final AnimationController _timer = AnimationController(vsync: this);

  /// Guards against a double tap on 下一项 recording twice (#5).
  bool _advancing = false;

  /// "左边记好了 → 现在测右边" banner shown after the left side (#5).
  bool _switchBanner = false;
  Timer? _bannerTimer;

  // voice
  HipVoice? _voice;
  VoiceQueue? _queue;
  List<VoiceCue> _cues = const [];
  final Set<int> _fired = {};
  DateTime _itemStart = clock.now();
  Timer? _voiceTicker;
  double _lead = 0;

  List<AssessmentItem> get _items => widget.store.content.rules.items;
  AssessmentItem get _item => _items[_index];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_voice == null) {
      _voice = HipVoice.of(context);
      _queue = _voice!.queue();
      if (_voice!.settings.voice || _voice!.settings.chimes) {
        unawaited(_voice!.output.begin());
      }
      ScreenAwake.acquire();
      _beginItem();
    }
  }

  void _beginItem() {
    _side = _item.sided ? HipSide.left : null;
    _leftAnswer = null;
    _restartTimer();
    _precacheNext();
  }

  void _precacheNext() {
    if (_index + 1 >= _items.length) return;
    final next = _items[_index + 1];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      hipPrecache(context, [
        next.demoArt(widget.store.content.drills)?.poster,
        for (final o in next.options) o.image,
      ]);
    });
  }

  void _restartTimer() {
    _choice = null;
    _follow = null;
    final voice = _voice!;
    final speaking = voice.settings.voice && voice.lib.has('a.hold');
    final script = voice.script();
    _lead = speaking
        ? script.assessmentLeadSeconds(_item, first: _index == 0, side: _side)
        : 0;
    final secs = _item.seconds.toDouble();
    _cues = speaking
        ? script.assessmentCues(_item, first: _index == 0, side: _side)
        : voice.settings.chimes
        ? [
            const VoiceCue(0, ['chime.start'], CuePriority.call),
            for (var k = 3; k >= 1; k--)
              VoiceCue(secs - k, const ['chime.tick'], CuePriority.count),
            VoiceCue(secs, const ['chime.end'], CuePriority.call),
          ]
        : const <VoiceCue>[];
    _fired.clear();
    _queue?.cancelAll(0);
    _itemStart = clock.now();
    _voiceTicker?.cancel();
    if (_cues.isNotEmpty) {
      _voiceTicker = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _voiceTick(),
      );
      _voiceTick();
    }
    _timer
      ..duration = Duration(
        milliseconds: ((_lead + _item.seconds) * 1000).round(),
      )
      ..forward(from: 0);
  }

  double get _t => clock.now().difference(_itemStart).inMicroseconds / 1e6;

  void _voiceTick() {
    final q = _queue;
    if (q == null || !mounted) return;
    final t = _t;
    for (var i = 0; i < _cues.length; i++) {
      if (_fired.contains(i) || _cues[i].at > t) continue;
      _fired.add(i);
      if (t - _cues[i].at < 1.5) q.submit(_cues[i], t);
    }
    q.tick(t);
    if (_fired.length == _cues.length) _voiceTicker?.cancel();
  }

  @override
  void dispose() {
    if (_voice != null) ScreenAwake.release();
    _timer.dispose();
    _bannerTimer?.cancel();
    _voiceTicker?.cancel();
    _queue?.cancelAll(_t);
    unawaited(_voice?.output.end());
    super.dispose();
  }

  bool get _needsFollow => _item.followUp.isNotEmpty && _choice == 0;
  bool get _canNext => _choice != null && (!_needsFollow || _follow != null);

  Future<void> _next() async {
    if (_advancing || !_canNext) return;
    await _record(SideAnswer.choice(_choice!, followUp: _follow));
  }

  Future<void> _record(SideAnswer answer) async {
    if (_advancing) return;
    _advancing = true;
    try {
      if (_side == HipSide.left) {
        _leftAnswer = answer;
        setState(() {
          _side = HipSide.right;
          _switchBanner = true;
          _restartTimer();
        });
        _bannerTimer?.cancel();
        _bannerTimer = Timer(const Duration(milliseconds: 1600), () {
          if (mounted) setState(() => _switchBanner = false);
        });
        return;
      }
      _answers[_item.id] = _side == HipSide.right
          ? ItemAnswer.sided(left: _leftAnswer!, right: answer)
          : ItemAnswer.single(answer);
      await _advance();
    } finally {
      _advancing = false;
    }
  }

  Future<void> _advance() async {
    _bannerTimer?.cancel();
    _switchBanner = false;
    if (_index < _items.length - 1) {
      setState(() {
        _index++;
        _beginItem();
      });
      return;
    }
    _timer.stop();
    _voiceTicker?.cancel();
    _queue?.cancelAll(_t);
    _queue?.submit(
      const VoiceCue(0, ['chime.finish', 'a.done'], CuePriority.call),
      _t,
    );
    final result = await widget.store.saveAssessment(_answers);
    if (mounted) setState(() => _result = result);
  }

  Future<void> _skipItem() async {
    if (_advancing) return;
    _advancing = true;
    try {
      _answers[_item.id] = _item.sided
          ? const ItemAnswer.sided(
              left: SideAnswer.skipped(),
              right: SideAnswer.skipped(),
            )
          : const ItemAnswer.single(SideAnswer.skipped());
      await _advance();
    } finally {
      _advancing = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: HipFadeSwitcher(
        child: _result == null
            ? KeyedSubtree(key: const ValueKey('items'), child: _itemScreen())
            : KeyedSubtree(
                key: const ValueKey('result'),
                child: _resultScreen(_result!),
              ),
      ),
    ),
  );

  Widget _dots() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < _items.length; i++)
        AnimatedContainer(
          duration: HipMotion.medium,
          curve: HipMotion.curve,
          width: i == _index ? 26 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: i <= _index ? HipColors.jade : HipColors.surfaceHigh,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
    ],
  );

  String get _stepKey => '${_item.id}-${_side?.name ?? 'one'}';

  Widget _itemScreen() {
    final item = _item;
    return Column(
      children: [
        HipTopBar(
          center: Center(child: _dots()),
          trailing: Text(
            '${_index + 1}/${_items.length}',
            style: TextStyle(fontSize: 16, color: HipColors.muted),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final mediaH = (c.maxHeight * .36).clamp(180.0, 300.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: mediaH, child: _demo(item)),
                    const SizedBox(height: 16),
                    HipFadeSwitcher(
                      child: KeyedSubtree(
                        key: ValueKey('$_stepKey-${_needsFollow ? 'f' : 'o'}'),
                        child: _question(item),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _bottomBar(item),
      ],
    );
  }

  Widget _demo(AssessmentItem item) {
    final demo = item.demoArt(widget.store.content.drills);
    final fallback = item.options.length > 1 ? item.options[1].image : null;
    return HipMediaFrame(
      key: const ValueKey('assessment-demo'),
      radius: 26,
      overlays: [
        Positioned(left: 14, top: 14, child: _pill(HipGlyph.loop, '跟着做一遍')),
        if (_side != null) Positioned(right: 14, top: 14, child: _sidePill()),
        Positioned(
          left: 24,
          right: 24,
          bottom: 16,
          child: AnimatedBuilder(
            animation: _timer,
            builder: (_, _) => ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: _timer.value,
                minHeight: 4,
                color: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: .18),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _switchBanner ? 1 : 0,
              duration: HipMotion.medium,
              child: _switchOverlay(),
            ),
          ),
        ),
      ],
      child: HipFadeSwitcher(
        duration: HipMotion.slow,
        offset: 0,
        expand: true,
        child: KeyedSubtree(
          key: ValueKey('demo-${item.id}'),
          child: demo != null && demo.mediaStatus != HipMediaStatus.pending
              ? HipDrillArt(
                  drill: demo,
                  play: true,
                  mirror: _side == HipSide.right,
                )
              : fallback != null
              ? Image.asset(fallback, fit: BoxFit.cover)
              : const HipPendingArt(label: '动画待渲染'),
        ),
      ),
    );
  }

  Widget _switchOverlay() => ColoredBox(
    color: Colors.black.withValues(alpha: .55),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HipIcon(
                HipGlyph.checkCircle,
                filled: true,
                color: HipColors.jade,
                size: 22,
              ),
              const SizedBox(width: 6),
              const Text(
                '左边记好了',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '现在测右边',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sidePill() => Container(
    key: const ValueKey('side-pill'),
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in [HipSide.left, HipSide.right])
          AnimatedContainer(
            duration: HipMotion.medium,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: s == _side ? HipColors.jade : null,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (s == HipSide.left && _side == HipSide.right) ...[
                  HipIcon(
                    HipGlyph.check,
                    size: 14,
                    strokeWidth: 2.4,
                    color: HipColors.jade,
                  ),
                  const SizedBox(width: 2),
                ],
                Text(
                  s == HipSide.left ? '左边' : '右边',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: s == _side ? HipColors.onJade : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _pill(HipGlyph icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .12)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HipIcon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.white)),
      ],
    ),
  );

  Widget _question(AssessmentItem item) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: item.title,
              style: TextStyle(
                color: HipColors.jade,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_side != null)
              TextSpan(
                text: _side == HipSide.left ? ' · 左边' : ' · 右边',
                style: TextStyle(
                  color: HipColors.jade,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        key: const ValueKey('assessment-title'),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15),
      ),
      if (item.aka != null) ...[
        const SizedBox(height: 2),
        Text(
          item.aka!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: HipColors.muted),
        ),
      ],
      const SizedBox(height: 6),
      Text(
        _needsFollow ? item.followUpQuestion! : item.question,
        key: const ValueKey('assessment-question'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          height: 1.3,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        _needsFollow ? '点一下翘起来的那条腿' : item.cue,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, height: 1.5, color: HipColors.muted),
      ),
      const SizedBox(height: 14),
      _needsFollow ? _followRow(item) : _optionRow(item),
    ],
  );

  Widget _bottomBar(AssessmentItem item) {
    final last = _index == _items.length - 1 && _side != HipSide.left;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      decoration: BoxDecoration(color: HipColors.background),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton.icon(
                key: const ValueKey('assessment-pain'),
                onPressed: () => _record(const SideAnswer.pain()),
                icon: HipIcon(HipGlyph.bolt, color: HipColors.pain, size: 18),
                label: Text('做的时候疼', style: TextStyle(color: HipColors.pain)),
              ),
              Text('·', style: TextStyle(color: HipColors.faint)),
              TextButton(
                key: const ValueKey('assessment-skip'),
                onPressed: _skipItem,
                child: Text(
                  '做不了 · 跳过',
                  style: TextStyle(color: HipColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          HipPrimaryButton(
            key: const ValueKey('assessment-next'),
            label: _side == HipSide.left
                ? '记下左边，测右边'
                : last
                ? '看结果'
                : '下一项',
            trailing: HipGlyph.chevronRight,
            onPressed: _canNext ? _next : null,
          ),
        ],
      ),
    );
  }

  Widget _optionRow(AssessmentItem item) => LayoutBuilder(
    builder: (context, c) {
      final cardW = (c.maxWidth - 20) / 3;
      final h = (cardW * 1.4).clamp(150.0, 200.0);
      return Row(
        children: [
          for (final (i, o) in item.options.indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _choiceCard(
                key: ValueKey('option-${o.score}'),
                height: h,
                selected: _choice == o.score,
                onTap: () => setState(() => _choice = o.score),
                image: o.image,
                focus: _focusOf(item),
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HipLevelBars(
                      level: o.score + 1,
                      color: _choice == o.score
                          ? HipColors.jade
                          : HipColors.text,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        o.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _choice == o.score
                              ? HipColors.jade
                              : HipColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                semantic: '${o.label}：${o.description}',
              ),
            ),
          ],
        ],
      );
    },
  );

  Widget _followRow(AssessmentItem item) => LayoutBuilder(
    builder: (context, c) {
      final h = ((c.maxWidth - 10) / 2 * 1.05).clamp(150.0, 200.0);
      return Row(
        children: [
          for (final (i, o) in item.followUp.indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _choiceCard(
                key: ValueKey('follow-${o.id}'),
                height: h,
                selected: _follow == o.id,
                onTap: () => setState(() => _follow = o.id),
                image: o.image,
                focus: _focusOf(item),
                footer: Text(
                  o.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: _follow == o.id ? HipColors.jade : HipColors.text,
                  ),
                ),
                semantic: o.label,
              ),
            ),
          ],
        ],
      );
    },
  );

  /// Option card: picture clipped to the rounded shape, footer, and the
  /// stroke painted on top of both; the check badge sits inside the stroke
  /// (#1).
  Widget _choiceCard({
    required Key key,
    required double height,
    required bool selected,
    required VoidCallback onTap,
    required Widget footer,
    required String semantic,
    required Rect focus,
    String? image,
  }) => Semantics(
    button: true,
    selected: selected,
    label: semantic,
    child: GestureDetector(
      key: key,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: height,
        child: HipMediaFrame(
          radius: 22,
          color: HipColors.surface,
          borderColor: selected ? HipColors.jade : HipColors.line,
          borderWidth: selected ? 2.5 : 1,
          shadow: selected
              ? [
                  BoxShadow(
                    color: HipColors.jade.withValues(alpha: .28),
                    blurRadius: 18,
                  ),
                ]
              : HipColors.cardShadow,
          overlays: [
            Positioned(
              right: 9,
              top: 9,
              child: AnimatedScale(
                scale: selected ? 1 : 0,
                duration: HipMotion.fast,
                curve: Curves.easeOutBack,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: HipColors.jade,
                    shape: BoxShape.circle,
                  ),
                  child: HipIcon(
                    HipGlyph.check,
                    size: 16,
                    strokeWidth: 2.6,
                    color: HipColors.onJade,
                  ),
                ),
              ),
            ),
          ],
          child: Column(
            children: [
              Expanded(
                child: ColoredBox(
                  color: HipPalette.dark.mediaBackdrop,
                  child: image == null
                      ? const HipPendingArt(label: '对比图待渲染')
                      : HipFocusImage(asset: image, focus: focus, margin: .06),
                ),
              ),
              AnimatedContainer(
                duration: HipMotion.fast,
                height: 46,
                color: selected
                    ? HipColors.jade.withValues(alpha: .12)
                    : HipColors.surfaceHigh,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: footer,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // ───────── result ─────────

  Widget _resultScreen(AssessmentResult r) {
    final store = widget.store;
    final routine = r.route == null
        ? null
        : store.content.routine(r.route!.routineId);
    final plan = routine == null
        ? null
        : store.planner.planFor([routine], store.profile);
    return Column(
      children: [
        const HipTopBar(subtitle: '自测完成', title: '你的髋部'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              SizedBox(
                height: 290,
                child: Center(
                  child: HipRadar(
                    values: r.radar,
                    highlight: r.tightest.toSet(),
                    warn: r.painDirections,
                  ),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (r.tightest.isNotEmpty)
                    _resultChip(
                      HipColors.tight,
                      '最紧：${r.tightest.map((d) => d.zh).join(' · ')}',
                    ),
                  if (r.best != null)
                    _resultChip(HipColors.jade, '最好：${r.best!.zh}'),
                  if (r.painDirections.isNotEmpty)
                    _resultChip(
                      HipColors.pain,
                      '先别练这里：${r.painDirections.map((d) => d.zh).join(' · ')}',
                    ),
                  if (r.untestedDirections.isNotEmpty)
                    _resultChip(
                      HipColors.faint,
                      '未测：${r.untestedDirections.map((d) => d.zh).join(' · ')}',
                    ),
                ],
              ),
              if (r.lowest != null) ...[
                const SizedBox(height: 10),
                Text(
                  '你的${_area(r.lowest!)}最紧，先从这里开始。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: HipColors.muted),
                ),
              ],
              const SizedBox(height: 16),
              if (r.route != null && routine != null)
                _routeCard(r.route!, routine, plan),
              if (r.dancerUnlocked) ...[
                const SizedBox(height: 10),
                Center(child: _resultChip(HipColors.jade, '已解锁托马斯动作库')),
              ],
            ],
          ),
        ),
        if (plan != null && plan.steps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  key: const ValueKey('result-other'),
                  onPressed: _chooseOther,
                  child: Text(
                    '换一条路线',
                    style: TextStyle(color: HipColors.muted),
                  ),
                ),
                HipPrimaryButton(
                  key: const ValueKey('result-start'),
                  label: '开始这条路线',
                  icon: HipGlyph.play,
                  onPressed: () => _start(plan),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _area(HipDirection d) => switch (d) {
    HipDirection.flexion => '大腿后侧',
    HipDirection.extension => '髋前侧',
    HipDirection.abduction => '大腿内侧',
    HipDirection.adduction => '髋外侧',
    HipDirection.internalRotation => '髋内旋',
    HipDirection.externalRotation => '髋外旋',
  };

  Future<void> _start(TrainingPlan plan) async {
    Navigator.of(context).pop();
    await widget.onStartPlan(plan);
  }

  Future<void> _chooseOther() async {
    final store = widget.store;
    final routine = await showModalBottomSheet<HipRoutine>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 8),
          children: [
            for (final r in store.content.routines.where((r) => !r.micro))
              ListTile(
                title: Text(r.name),
                subtitle: Text(
                  r.audience,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: HipColors.muted),
                ),
                trailing: Text(
                  r.scene.zh,
                  style: TextStyle(color: HipColors.muted),
                ),
                onTap: () => Navigator.of(context).pop(r),
              ),
          ],
        ),
      ),
    );
    if (routine != null) {
      await _start(store.planner.planFor([routine], store.profile));
    }
  }

  Widget _resultChip(Color color, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: HipColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HipColors.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  /// "Breaking 开胯 · 先补髋前侧（L 撑）" → eyebrow + headline, so the
  /// title breaks where it should (#7 顺修).
  static (String?, String) _splitRoute(String route) {
    final i = route.indexOf(' · ');
    if (i < 0) return (null, route);
    return (route.substring(0, i), route.substring(i + 3));
  }

  Widget _routeCard(RouteSuggestion s, HipRoutine routine, TrainingPlan? plan) {
    final steps = plan?.steps ?? const <PlanStep>[];
    final hero = steps.where((p) => p.drill.poster != null).firstOrNull?.drill;
    final (eyebrow, headline) = _splitRoute(s.route);
    return DecoratedBox(
      key: const ValueKey('route-card'),
      decoration: BoxDecoration(
        color: HipColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: HipColors.jade.withValues(alpha: .45)),
        boxShadow: HipColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow == null ? '为你推荐' : '为你推荐 · $eyebrow',
                        style: TextStyle(
                          fontSize: 13,
                          color: HipColors.jade,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        headline,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${plan?.minutes ?? routine.seconds ~/ 60} 分钟 · ${steps.length} 个动作',
                        style: TextStyle(fontSize: 13, color: HipColors.muted),
                      ),
                    ],
                  ),
                ),
                if (hero != null) ...[
                  const SizedBox(width: 12),
                  HipThumb(
                    size: 96,
                    radius: 14,
                    child: HipDrillArt(drill: hero, showPendingLabel: false),
                  ),
                ],
              ],
            ),
            if (steps.length > 1) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final p in steps.skip(1).take(4)) ...[
                    HipThumb(
                      size: 48,
                      radius: 12,
                      child: HipDrillArt(
                        drill: p.drill,
                        showPendingLabel: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (steps.length > 5)
                    Text(
                      '+${steps.length - 5}',
                      style: TextStyle(fontSize: 14, color: HipColors.muted),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
