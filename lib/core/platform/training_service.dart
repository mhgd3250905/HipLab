// HipLab's own platform bridge (not copied from 3D-Body).
// 2026-10-20: delegate session ownership and the Android service to
// ugk_trainer; keep only HipLab's notification copy for the self-check.
import 'package:ugk_trainer/ugk_trainer.dart' as trainer;

/// Compatibility name for existing platform hooks and regression tests.
/// The player and self-check share the package's session sequence/channel.
typedef TrainingService = trainer.TrainingKeepAlive;

/// HipLab notification defaults around the package's keep-alive hold.
/// The package owns all lifetime, renewal and stale-session protection.
class TrainingHold {
  TrainingHold._(this._hold);

  final trainer.TrainingHold _hold;

  static const _notice = trainer.TrainingNotice(
    channelName: '训练进行中',
    channelDescription: '训练或自测进行时保持计时和语音指导',
    title: '开胯训练进行中',
    text: '锁屏或切到后台时，计时和语音会继续',
    icon: 'mipmap/ic_launcher_monochrome',
  );

  static const margin = trainer.TrainingHold.margin;
  static const minCap = trainer.TrainingHold.minCap;
  static const maxCap = trainer.TrainingHold.maxCap;

  static Duration capFor(Duration expected) =>
      trainer.TrainingHold.capFor(expected);

  static TrainingHold begin(Duration expected) =>
      TrainingHold._(trainer.TrainingHold.begin(expected, notice: _notice));

  int get session => _hold.session;
  bool get active => _hold.active;

  void renew(Duration remaining) => _hold.renew(remaining);

  void release({Duration after = Duration.zero}) => _hold.release(after: after);
}
