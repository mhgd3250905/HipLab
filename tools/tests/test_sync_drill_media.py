"""Run with: python -m unittest discover -s tools/tests -v."""
import contextlib
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
import warnings
from unittest.mock import mock_open, patch


SPEC = importlib.util.spec_from_file_location(
    'sync_drill_media', Path(__file__).resolve().parents[1] / 'sync_drill_media.py')
sync = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sync)


class SyncDrillMediaTests(unittest.TestCase):
    def test_source_attribution_applies_only_to_encoded_video(self):
        args = sync.parse_args(['--source-commit', 'ae81d96', '--source-batch', 'hiplab-hd-20261017',
                                '--source-pixel-ratio', '2', '--size', '1080', '--crf', '18'])
        old = {'source': 'old source', 'source_commit': 'oldcommit', 'encode_size': 720}
        kept = sync.video_metadata(old, 8, 1, 'new source', False, args)
        self.assertEqual(kept['source_commit'], 'oldcommit')
        self.assertEqual(kept['encode_size'], 720)
        self.assertEqual(kept['source'], 'old source')
        self.assertNotIn('source_batch', kept)
        new = sync.video_metadata(old, 8, 1, 'new source', True, args)
        self.assertEqual((new['source_commit'], new['source_batch'], new['source_pixel_ratio']),
                         ('ae81d96', 'hiplab-hd-20261017', '2'))
        self.assertEqual((new['encode_size'], new['encode_crf']), (1080, 18))

    def test_generated_content_uses_lf_on_windows(self):
        # Generate only in a temporary directory; never rewrite the app content pack.
        spec = importlib.util.spec_from_file_location(
            'build_hip_content', Path(__file__).resolve().parents[1] / 'hip_content' / 'build_hip_content.py')
        builder = importlib.util.module_from_spec(spec)
        with warnings.catch_warnings():
            # Existing source readers leave read handles to Python's cleanup.
            warnings.simplefilter('ignore', ResourceWarning)
            spec.loader.exec_module(builder)
            with tempfile.TemporaryDirectory() as directory, \
                    patch.object(builder, 'OUT', str(Path(directory) / 'content.json')), \
                    contextlib.redirect_stdout(io.StringIO()):
                builder.main()
                content = Path(builder.OUT).read_bytes()
        self.assertIn(b'\n', content)
        self.assertNotIn(b'\r', content)

    def test_default_quality_is_backward_compatible(self):
        args = sync.parse_args([])
        self.assertEqual((args.size, args.crf, args.poster_size), (720, 27, 540))
        with patch.object(sync, 'run') as run:
            sync.encode('source.mp4', 'app.mp4')
        command = run.call_args.args[0]
        self.assertEqual(command[command.index('-vf') + 1], 'scale=720:720:flags=lanczos')
        self.assertEqual(command[command.index('-crf') + 1], '27')

    def test_hd_encode_preserves_source_timing_and_cut(self):
        with patch.object(sync, 'run') as run:
            sync.encode('source.mp4', 'app.mp4', 7.2, 12.0, size=1080, crf=18)
        command = run.call_args.args[0]
        self.assertEqual(command[command.index('-vf') + 1], 'scale=1080:1080:flags=lanczos')
        self.assertEqual(command[command.index('-crf') + 1], '18')
        self.assertEqual(command[command.index('-fps_mode') + 1], 'passthrough')
        self.assertNotIn('-r', command)
        self.assertFalse(any('fps=' in value for value in command))
        self.assertLess(command.index('-ss'), command.index('-i'))
        self.assertEqual(command[command.index('-ss') + 1], '7.2')
        self.assertEqual(command[command.index('-to') + 1], '12.0')
        self.assertIn('+faststart', command)

    def test_poster_defaults_and_hd_size(self):
        for size in (None, 1080):
            with self.subTest(size=size), patch.object(sync, 'run') as run:
                sync.poster('source.mp4', 1.25, 'poster.jpg', **({} if size is None else {'size': size}))
            command = run.call_args.args[0]
            expected = size or 540
            self.assertEqual(command[command.index('-vf') + 1],
                             f'scale={expected}:{expected}:flags=lanczos')
            self.assertEqual(command[command.index('-ss') + 1], '1.250')

    def test_quality_argument_bounds(self):
        for size in ('128', '1080', '4096'):
            self.assertEqual(sync.parse_args(['--size', size]).size, int(size))
        for crf in ('0', '18', '51'):
            self.assertEqual(sync.parse_args(['--crf', crf]).crf, int(crf))
        for option, values in (
            ('--size', ('0', '127', '721', '4098', '1080.5', 'bad')),
            ('--poster-size', ('-1', '541', '5000', 'bad')),
            ('--crf', ('-1', '52', '18.5', 'bad')),
        ):
            for value in values:
                with self.subTest(option=option, value=value), contextlib.redirect_stderr(io.StringIO()):
                    with self.assertRaises(SystemExit) as error:
                        sync.parse_args([option, value])
                    self.assertEqual(error.exception.code, 2)

    def test_dry_run_reports_quality_without_writes_or_subprocesses(self):
        output = io.StringIO()
        with tempfile.TemporaryDirectory() as directory, \
                patch.object(sync.shutil, 'which', return_value='available'), \
                patch.object(sync, 'known_drills', return_value=set()), \
                patch.object(sync, 'update_csv', return_value=0) as update_csv, \
                patch.object(sync, 'run') as run, \
                patch('builtins.open', mock_open(read_data='{"videos": {}}')) as files, \
                contextlib.redirect_stdout(output):
            sync.main(['--out', directory, '--dry-run', '--size', '1080', '--crf', '18',
                       '--poster-size', '1080'])
        self.assertIn('video 1080x1080, H.264 CRF 18, source frame timing; poster 1080x1080',
                      output.getvalue())
        run.assert_not_called()
        update_csv.assert_called_once_with(set(), True)
        self.assertEqual(files.call_count, 1)
        self.assertNotIn('w', files.call_args.args[1:])


if __name__ == '__main__':
    unittest.main()
