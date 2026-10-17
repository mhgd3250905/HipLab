import 'package:hiplab/core/media/media_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'metadata and playing state keep the poster until a presented frame',
    () {
      final media = DrillMediaController();
      media.toggle();
      media.receive({'source': 'drill-media', 'type': 'ready'});
      media.receive({
        'source': 'drill-media',
        'type': 'state',
        'playing': true,
      });
      expect(media.ready, isTrue);
      expect(media.playing, isTrue);
      expect(media.hasFrame, isFalse);
      media.receive({'source': 'drill-media', 'type': 'first-frame'});
      expect(media.hasFrame, isTrue);
      media.dispose();
    },
  );
  test(
    'pause before first frame keeps the poster and resume can reveal it',
    () {
      final media = DrillMediaController();
      media.receive({'source': 'drill-media', 'type': 'ready'});
      media.toggle();
      media.pause();
      media.receive({
        'source': 'drill-media',
        'type': 'state',
        'playing': false,
      });
      expect(media.hasFrame, isFalse);
      media.toggle();
      media.receive({'source': 'drill-media', 'type': 'first-frame'});
      media.pause();
      expect(media.hasFrame, isTrue);
      media.setActive(false);
      media.setActive(true);
      expect(media.hasFrame, isTrue);
      expect(media.wantsPlay, isFalse);
      media.dispose();
    },
  );
  test('first frame notification is once and errors restore the poster', () {
    final media = DrillMediaController();
    var notices = 0;
    media.addListener(() => notices++);
    media.receive({'source': 'drill-media', 'type': 'first-frame'});
    media.receive({'source': 'drill-media', 'type': 'first-frame'});
    expect(notices, 1);
    media.reportError();
    expect(media.hasFrame, isFalse);
    media.receive({'source': 'drill-media', 'type': 'first-frame'});
    expect(media.hasFrame, isFalse);
    media.dispose();
    final retry = DrillMediaController();
    expect(retry.hasFrame, isFalse);
    retry.receive({'source': 'drill-media', 'type': 'first-frame'});
    expect(retry.hasFrame, isTrue);
    retry.dispose();
  });
  test('unrelated or disposed first-frame events cannot reveal a poster', () {
    final media = DrillMediaController();
    media.receive({'source': 'flare-scene', 'type': 'first-frame'});
    expect(media.hasFrame, isFalse);
    media.dispose();
    media.receive({'source': 'drill-media', 'type': 'first-frame'});
    expect(media.hasFrame, isFalse);
  });
  test('pausing before metadata arrives cancels the queued play', () {
    final media = DrillMediaController();
    final commands = <Map<String, Object?>>[];
    media.attach(commands.add);
    media.toggle();
    media.toggle();
    media.receive({'source': 'drill-media', 'type': 'ready'});
    expect(commands.any((v) => v['type'] == 'play'), isFalse);
    media.dispose();
  });
  test('rapid card switching releases the former owner only once', () {
    final gate = DrillPlaybackCoordinator();
    final first = Object(), second = Object(), third = Object();
    var stoppedFirst = 0, stoppedSecond = 0;
    gate.claim(first, () {
      stoppedFirst++;
      gate.release(first);
    });
    gate.claim(second, () {
      stoppedSecond++;
      gate.release(second);
    });
    gate.release(
      first,
    ); // Old asynchronous dispose cannot release the new card.
    gate.claim(third, () {});
    expect(stoppedFirst, 1);
    expect(stoppedSecond, 1);
    gate.release(third);
  });
  test('late ready cannot restart a hidden or outgoing demonstration', () {
    final media = DrillMediaController();
    final commands = <Map<String, Object?>>[];
    media.setActive(false);
    media.attach(commands.add);
    media.receive({'source': 'drill-media', 'type': 'ready'});
    expect(commands.last, {'type': 'active', 'value': false});
    media.setActive(true);
    expect(commands.last, {'type': 'active', 'value': true});
    expect(commands.any((v) => v['type'] == 'play'), isFalse);
    media.dispose();
    expect(commands.last['type'], 'pause');
  });
  test('unrelated scene events cannot change media state', () {
    final media = DrillMediaController();
    media.receive({'source': 'flare-scene', 'type': 'ready'});
    expect(media.ready, isFalse);
    media.receive({'source': 'drill-media', 'type': 'state', 'playing': true});
    expect(media.playing, isTrue);
    media.reportError();
    expect(media.failed, isTrue);
    expect(media.playing, isFalse);
    media.dispose();
  });
}
